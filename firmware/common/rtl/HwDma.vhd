-------------------------------------------------------------------------------
-- File       : AxiStreamDmaV2.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-02
-- Last update: 2018-01-24
-------------------------------------------------------------------------------
-- Description:
-- Generic AXI Stream DMA block for frame at a time transfers.
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'SLAC Firmware Standard Library', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.AxiLitePkg.all;
use work.AxiPkg.all;
use work.HwDmaPkg.all;

entity HwDma is
   generic (
      TPD_G             : time                     := 1 ns;
      AXI_READY_EN_G    : boolean                  := false;
      AXIS_READY_EN_G   : boolean                  := false;
      AXIS_CONFIG_G     : AxiStreamConfigType      := AXI_STREAM_CONFIG_INIT_C;
      BURST_BYTES_G     : positive range 1 to 4096 := 4096;
      WR_PIPE_STAGES_G  : natural                  := 1;
      RD_PIPE_STAGES_G  : natural                  := 1;
      RD_PEND_THRESH_G  : positive                 := 1);  -- In units of bytes
   port (
      -- AXI Stream Interface
      axisClk         : in  sl;
      axisRst         : in  sl;
      ibMaster        : in  AxiStreamMasterType;
      ibSlave         : out AxiStreamSlaveType;
      -- AXI Interfaces
      axiClk          : in  sl;
      axiRst          : in  sl;
      axiWriteMaster  : out AxiWriteMasterType;
      axiWriteSlave   : in  AxiWriteSlaveType;
      axiWriteDesc    : out slv(63 downto 0);
      axiWriteDone    : out sl;
      -- AXI-Lite Interface
      axilClk         : in  sl;
      axilRst         : in  sl;
      axilWriteMaster : in  AxiLiteWriteMasterType;
      axilWriteSlave  : out AxiLiteWriteSlaveType;
      axilReadMaster  : in  AxiLiteReadMasterType;
      axilReadSlave   : out AxiLiteReadSlaveType );
end HwDma;

architecture structure of HwDma is

  constant DATA_BYTES_C      : integer := AXIS_CONFIG_G.TDATA_BYTES_C;
  constant ADDR_LSB_C        : integer := bitSize(DATA_BYTES_C-1);
  constant FIFO_ADDR_WIDTH_C : natural := (AXI_CONFIG_G.LEN_BITS_C+1);

  type StateType is (
    RESET_S,
    INIT_S,
    IDLE_S,
    REQ_S,
    ADDR_S,
    MOVE_S,
    PAD_S,
    RETURN_S,
    DUMP_S);

  type RegType is record
    appIndex       : slv( 2 downto 0);
    buffOrder      : slv(23 downto 0);
    buffWriteIndex : slv(23 downto 0);
    buffReadIndex  : slv(23 downto 0);
    result        : slv(1  downto 0);
    reqCount      : slv(31 downto 0);
    ackCount      : slv(31 downto 0);
    stCount       : slv(15 downto 0);
    awlen         : slv(AXI_CONFIG_G.LEN_BITS_C-1 downto 0);
    wMaster       : AxiWriteMasterType;
    slave         : AxiStreamSlaveType;
    state         : StateType;
    lastUser      : slv(7 downto 0);
    continue      : sl;
    dmaWrIdle     : sl;

  end record;

  constant REG_INIT_C : RegType := (
    appIndex       => "000",
    buffOrder      => 21,
    buffWriteIndex => (others=>'0'),
    buffReadIndex  => (others=>'0'),
    result        => (others => '0'),
    reqCount      => (others => '0'),
    ackCount      => (others => '0'),
    stCount       => (others => '0'),
    awlen         => (others => '0'),
    wMaster       => axiWriteMasterInit(AXI_CONFIG_G, '1', "01", "0000"),
    slave         => AXI_STREAM_SLAVE_INIT_C,
    state         => RESET_S,
    lastUser      => (others=>'0'),
    continue      => '0',
    dmaWrIdle     => '0');

   signal r             : RegType := REG_INIT_C;
   signal rin           : RegType;
   signal intAxisMaster : AxiStreamMasterType;
   signal intAxisSlave  : AxiStreamSlaveType;

  signal axiCache : slv(3 downto 0);

  signal axiReset  : slv(CHAN_COUNT_G-1 downto 0);

  attribute dont_touch             : string;
  attribute dont_touch of axiReset : signal is "true";   

   
begin

      -- Help with timing
      U_AxisRst : entity work.RstPipeline
         generic map (
            TPD_G     => TPD_G,
            INV_RST_G => false)
         port map (
            clk    => axiClk,
            rstIn  => axiRst,
            rstOut => axiReset(i));   

   U_Pipeline : entity work.AxiStreamPipeline
      generic map (
         TPD_G         => TPD_G,
         PIPE_STAGES_G => PIPE_STAGES_G)
      port map (
         axisClk     => axiClk,
         axisRst     => axiRst,
         sAxisMaster => axisMaster,
         sAxisSlave  => axisSlave,
         mAxisMaster => intAxisMaster,
         mAxisSlave  => intAxisSlave);    

   -- State machine
   comb : process (axiRst, axiWriteSlave, dmaWrDescAck, dmaWrDescRetAck, 
                   intAxisMaster, trackData, pause, r, axiCache) is
      variable v       : RegType;
      variable bytes   : natural;
   begin
      -- Latch the current value
      v := r;

      -- Clear stream slave
      v.slave.tReady := '0';

      -- Cache setting
      v.wMaster.awcache := axiCache;

      -- Reset AXI Signals
      if (axiWriteSlave.awready = '1') or (AXI_READY_EN_G = false) then
         v.wMaster.awvalid := '0';
      end if;
      if (axiWriteSlave.wready = '1') or (AXI_READY_EN_G = false) then
         v.wMaster.wvalid := '0';
         v.wMaster.wlast  := '0';
      end if;

      -- Wait for memory bus response
      if (axiWriteSlave.bvalid = '1') and (ACK_WAIT_BVALID_G = true) then
         -- Increment the counter
         v.ackCount := r.ackCount + 1;
         -- Check for error response
         if (axiWriteSlave.bresp /= "00") and (r.result = 0) then
            -- Latch the response value
            v.result := axiWriteSlave.bresp;
         end if;
      end if;

      -- Descriptor handshaking
      if dmaWrDescRetAck = '1' then
         v.dmaWrDescRet.valid := '0';
      end if;
      if dmaWrDescAck.valid = '1' then
         v.dmaWrDescReq.valid := '0';
      end if;

      -- Count number of bytes in return data
      if (AXIS_CONFIG_G.TKEEP_MODE_C = TKEEP_COUNT_C) then
         bytes := conv_integer(intAxisMaster.tKeep(4 downto 0));
      else
         bytes := getTKeep(intAxisMaster.tKeep(DATA_BYTES_C-1 downto 0));
      end if;
      
      -- State machine
      case r.state is
         ----------------------------------------------------------------------
         when RESET_S =>
            v := REG_INIT_C;
            if r.stCount = 100 then
               v.state := INIT_S;
            else
               v.stCount := r.stCount + 1;
            end if;
         ----------------------------------------------------------------------
         when INIT_S =>
            v.dmaWrTrack.dest := r.dmaWrTrack.dest + 1;
            if r.dmaWrTrack.dest = 255 then
               v.state           := IDLE_S;
            end if;
         ----------------------------------------------------------------------
         when IDLE_S =>
            if intAxisMaster.tValid = '1' then
               v.dmaWrTrack.inUse     := '1';
               v.dmaWrTrack.address   := dmaWrDescAck.address;
               v.dmaWrTrack.maxSize   := dmaWrDescAck.maxSize;
               v.dmaWrTrack.size      := (others=>'0');
               v.dmaWrTrack.firstUser := (others=>'0');
               v.dmaWrTrack.contEn    := dmaWrDescAck.contEn;
               v.dmaWrTrack.dropEn    := dmaWrDescAck.dropEn;
               v.dmaWrTrack.buffId    := dmaWrDescAck.buffId;
               v.dmaWrTrack.overflow  := '0';

               -- Descriptor return calls for dumping frame?
               if dmaWrDescAck.dropEn = '1' then
                  v.state := DUMP_S;
               else
                  v.state := ADDR_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when ADDR_S =>
            -- Reset counter, continue and last user
            v.stCount  := (others=>'0');
            v.continue := '0';
            v.lastUser := (others=>'0');
            -- Address can be sent
            if (v.wMaster.awvalid = '0') then
               -- Set the memory address
               v.wMaster.awaddr(AXI_CONFIG_G.ADDR_WIDTH_C-1 downto 0) := 
                  r.dmaWrTrack.address(AXI_CONFIG_G.ADDR_WIDTH_C-1 downto 0);
               -- Determine transfer size aligned to 4k boundaries
               v.wMaster.awlen := getAxiLen(AXI_CONFIG_G,BURST_BYTES_G,r.dmaWrTrack.maxSize,r.dmaWrTrack.address);
               -- Latch AXI awlen value
               v.awlen := v.wMaster.awlen(AXI_CONFIG_G.LEN_BITS_C-1 downto 0);
               -- Check if enough room
               if pause = '0' then
                  -- Set the flag
                  v.wMaster.awvalid := '1';
                  -- Increment the counter
                  v.reqCount := r.reqCount + 1;
                  -- Next state
                  v.state := MOVE_S;
               end if;
            end if;
         ----------------------------------------------------------------------
         when MOVE_S =>
            -- Incoming valid data
            if intAxisMaster.tValid = '1' then
               v.stCount := (others=>'0');
               -- Destination has changed, complete current write
               if intAxisMaster.tDest /= r.dmaWrDescReq.dest then
                  v.state := PAD_S;
               -- Overflow detect
               elsif bytes > r.dmaWrTrack.maxSize then
                  -- Multi-descriptor DMA is supported
                  if r.dmaWrTrack.contEn = '1' then
                     v.continue := '1';
                     v.dmaWrTrack.inUse := '0';
                  else
                     v.dmaWrTrack.overflow := '1';
                     v.dmaWrTrack.dropEn := '1';
                  end if;
                  -- Pad current write, dump of incoming frame will occur
                  -- after state machine returns to idle due to dropEn being set.
                  -- Return will follow pad with inUse = '0'
                  v.state := PAD_S;
               -- We are able to push more data
               elsif v.wMaster.wvalid = '0' then
                  -- Accept the data
                  v.slave.tReady := '1';
                  -- Move the data
                  v.wMaster.wvalid := '1';
                  v.wMaster.wdata((DATA_BYTES_C*8)-1 downto 0) := intAxisMaster.tData((DATA_BYTES_C*8)-1 downto 0);
                  -- Set byte write strobes
                  if (AXIS_CONFIG_G.TKEEP_MODE_C = TKEEP_COUNT_C) then
                     v.wMaster.wstrb(15 downto 0)             := genTKeep(bytes);
                  else
                     v.wMaster.wstrb(DATA_BYTES_C-1 downto 0) := intAxisMaster.tKeep(DATA_BYTES_C-1 downto 0);
                  end if;                  
                  -- Address and size increment
                  v.dmaWrTrack.address := r.dmaWrTrack.address + DATA_BYTES_C;
                  v.dmaWrTrack.address(ADDR_LSB_C-1 downto 0) := (others => '0');
                  -- Increment the byte counter
                  v.dmaWrTrack.size    := r.dmaWrTrack.size + bytes;
                  v.dmaWrTrack.maxSize := r.dmaWrTrack.maxSize - bytes;
                  -- First word
                  if r.dmaWrTrack.size = 0 then
                     -- Latch the tDest/tId/tUser values
                     v.dmaWrTrack.id := intAxisMaster.tId;
                     v.dmaWrTrack.firstUser(AXIS_CONFIG_G.TUSER_BITS_C-1 downto 0) := 
                        axiStreamGetUserField(AXIS_CONFIG_G, intAxisMaster, 0);
                  end if;
                  -- -- Check for last AXIS word
                  if intAxisMaster.tLast = '1' then
                     -- Latch the tUser value
                     v.lastUser(AXIS_CONFIG_G.TUSER_BITS_C-1 downto 0) := 
                        axiStreamGetUserField(AXIS_CONFIG_G, intAxisMaster);
                     v.dmaWrTrack.inUse := '0';
                     -- Pad write if transaction is not done, return will following PAD because inUse = 0
                     if r.awlen = 0 then
                        v.state := RETURN_S;
                     else
                        v.state := PAD_S;
                     end if;
                  end if;
                  -- Check for last AXI transfer
                  if r.awlen = 0 then
                     -- Set the flag
                     v.wMaster.wlast := '1';
                     -- If next state has not already been updated go to idle
                     if v.state = MOVE_S then
                        v.state := IDLE_S;
                     end if;
                  else
                     -- Decrement the transaction counter
                     v.awlen := r.awlen - 1;
                  end if;
               end if;
            -- Timeout on stalled writes to avoid locking AXI crossbar
            elsif r.stCount = 100 then
               v.state := PAD_S;
            else
               v.stCount := r.stCount + 1;
            end if;
         ----------------------------------------------------------------------
         when PAD_S =>
            v.stCount := (others=>'0');
            -- We are able to push more data
            if v.wMaster.wvalid = '0' then
               v.wMaster.wvalid := '1';
               v.wMaster.wstrb := (others=>'0');
               -- Check for last AXI transfer
               if r.awlen = 0 then
                  -- Set the flag
                  v.wMaster.wlast := '1';
                  -- Frame is done. Go to return. Otherwise go to idle.
                  if r.dmaWrTrack.inUse = '0' then
                     v.state := RETURN_S;
                  else
                     v.state := IDLE_S;
                  end if;
               else
                  -- Decrement the counter
                  v.awlen := r.awlen - 1;
               end if;
            end if;
         ----------------------------------------------------------------------
         when RETURN_S =>
            -- Previous return was acked
            if v.dmaWrDescRet.valid = '0' then
               -- Setup return record
               v.dmaWrDescRet.buffId    := r.dmaWrTrack.buffId;
               v.dmaWrDescRet.firstUser := r.dmaWrTrack.firstUser;
               v.dmaWrDescRet.size      := r.dmaWrTrack.size;
               v.dmaWrDescRet.dest      := r.dmaWrTrack.dest;
               v.dmaWrDescRet.id        := r.dmaWrTrack.id;
               v.dmaWrDescRet.lastUser  := r.lastUser;
               v.dmaWrDescRet.continue  := r.continue;
               v.dmaWrDescRet.result(2) := r.dmaWrTrack.overflow;
               v.dmaWrDescRet.result(1 downto 0) := r.result;
               -- Init record
               v.dmaWrTrack.inUse := '0';
               -- Wait for all transactions to complete before returning descriptor
               if (r.ackCount = r.reqCount) or (ACK_WAIT_BVALID_G = false) then
                  v.dmaWrDescRet.valid := '1';
                  v.state := IDLE_S;
               -- Check for ACK timeout   
               elsif (r.stCount = x"FFFF") then
                  -- Set the flags
                  v.dmaWrDescRet.result(1 downto 0) := "11";
                  v.dmaWrDescRet.valid := '1';
                  v.reqCount := (others => '0');
                  v.ackCount := (others => '0');
                  v.state    := IDLE_S;
               else
                  -- Increment the counter
                  v.stCount := r.stCount + 1;
               end if;
            else
               v.stCount := (others=>'0');
            end if;
         ----------------------------------------------------------------------
         when DUMP_S =>
            -- Incoming valid data
            if intAxisMaster.tValid = '1' then
               -- Destination has changed, complete current write
               if intAxisMaster.tDest /= r.dmaWrDescReq.dest then
                  v.state := IDLE_S;
               else
                  -- Accept the data
                  v.slave.tReady := '1';
                  -- -- Check for last AXIS word
                  if intAxisMaster.tLast = '1' then
                     v.dmaWrTrack.inUse := '0';
                     v.state := RETURN_S;
                  end if;
               end if;
            end if;
      ----------------------------------------------------------------------
         when others =>
            v.state := RESET_S;
      end case;

      -- Forward the state of the state machine
      if (v.state = IDLE_S) then
         v.dmaWrIdle := '1';
      else
         v.dmaWrIdle := '0';
      end if;

      -- Reset      
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle      
      rin <= v;

      -- Outputs   
      intAxisSlave   <= v.slave;
      axiWriteMaster <= r.wMaster;
      dmaWrDescReq   <= r.dmaWrDescReq;
      dmaWrDescRet   <= r.dmaWrDescRet;
      dmaWrIdle      <= r.dmaWrIdle;

   end process comb;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

      
      U_DmaWrite : entity work.AxiStreamDmaV2Write
         generic map (
            TPD_G             => TPD_G,
            AXI_READY_EN_G    => AXI_READY_EN_G,
            AXIS_CONFIG_G     => AXIS_CONFIG_G,
            AXI_CONFIG_G      => AXI_DMA_CONFIG_G,
            PIPE_STAGES_G     => WR_PIPE_STAGES_G,
            BURST_BYTES_G     => BURST_BYTES_G,
            ACK_WAIT_BVALID_G => true)
         port map (
            axiClk          => axiClk,
            axiRst          => axiReset(i),
            dmaWrDescReq    => dmaWrDescReq(i),
            dmaWrDescAck    => dmaWrDescAck(i),
            dmaWrDescRet    => dmaWrDescRet(i),
            dmaWrDescRetAck => dmaWrDescRetAck(i),
            dmaWrIdle       => open,
            axiCache        => axiCache,
            axisMaster      => sAxisMaster(i),
            axisSlave       => sAxisSlave(i),
            axiWriteMaster  => axiWriteMaster(i+1),
            axiWriteSlave   => axiWriteSlave(i+1),
            axiWriteCtrl    => axiWriteCtrl(i+1));
   end generate;

end structure;

