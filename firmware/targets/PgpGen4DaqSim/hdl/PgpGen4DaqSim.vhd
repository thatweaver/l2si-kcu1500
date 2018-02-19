library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDescPkg.all;
use work.AxiPciePkg.all;
use work.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpGen4DaqSim is
end PgpGen4DaqSim;

architecture top_level_app of PgpGen4DaqSim is

  constant NAPP_C  : integer := 1;
  constant LANES_C : integer := 1;
  
  signal axiClk, axiRst : sl;
  signal axilWriteMaster     : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
  signal axilWriteSlave      : AxiLiteWriteSlaveType;
  signal axilReadMaster      : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
  signal axilReadSlave       : AxiLiteReadSlaveType;

  signal axiReadMasters      : AxiReadMasterArray(LANES_C-1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal axiReadSlaves       : AxiReadSlaveArray (LANES_C-1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal dscReadMasters      : AxiDescMasterArray(LANES_C-1 downto 0) := (others=>AXI_DESC_MASTER_INIT_C);
  signal dscReadSlaves       : AxiDescSlaveArray (LANES_C-1 downto 0) := (others=>AXI_DESC_SLAVE_INIT_C);

  signal axiWriteMasters     : AxiWriteMasterArray(LANES_C+1 downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal axiWriteSlaves      : AxiWriteSlaveArray (LANES_C+1 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);

  constant sAxisConfig : AxiStreamConfigType := (
    TSTRB_EN_C    => true,
    TDATA_BYTES_C => 8,
    TDEST_BITS_C  => 0,
    TID_BITS_C    => 0,
    TKEEP_MODE_C  => TKEEP_NORMAL_C,
    TUSER_BITS_C  => 0,
    TUSER_MODE_C  => TUSER_NONE_C );
  
  signal axisClk, axisRst    : sl;
  signal sAxisMasters        : AxiStreamMasterArray(LANES_C-1 downto 0) := (others=>axiStreamMasterInit(sAxisConfig));
  signal sAxisSlaves         : AxiStreamSlaveArray (LANES_C-1 downto 0);
  signal mAxiWriteMasters    : AxiWriteMasterArray (LANES_C-1 downto 0);
  signal mAxiWriteSlaves     : AxiWriteSlaveArray  (LANES_C-1 downto 0);
  
  signal axilDone : sl;

  signal ssamp : sl;
  signal spush : sl;
  signal haddr : slv(9 downto 0) := (others=>'0');
  signal haxisMaster : AxiStreamMasterArray(4 downto 0);
  signal haxisSlave  : AxiStreamSlaveArray (4 downto 0);
  signal haxiWriteMaster : AxiWriteMasterType;
  signal haxiWriteSlave  : AxiWriteSlaveType;
  signal haxiWriteData   : slv(63 downto 0);
  
  constant config : MigConfigType := MIG_CONFIG_INIT_C;
  signal status   : MigStatusArray(LANES_C-1 downto 0);

  signal memWriteMasters : AxiWriteMasterArray(1 downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal memReadMasters  : AxiReadMasterArray (1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal memWriteSlaves  : AxiWriteSlaveArray (1 downto 0) := (others=>AXI_WRITE_SLAVE_FORCE_C);
  signal memReadSlaves   : AxiReadSlaveArray  (1 downto 0) := (others=>AXI_READ_SLAVE_FORCE_C);

  signal memReady : slv          (0 downto 0);
  signal ddrClkP  : slv          (0 downto 0);
  signal ddrClkN  : slv          (0 downto 0);
  signal ddrOut   : DdrOutArray  (0 downto 0);
  signal ddrInOut : DdrInOutArray(0 downto 0);

begin

  haxiWriteData <= haxiWriteMaster.wdata(haxiWriteData'range);
  
    GEN_LANES : for i in 0 to LANES_C-1 generate
      U_DUT : entity work.AppToMigWrapper
        generic map ( AXI_STREAM_CONFIG_G => sAxisConfig )
        port map ( sAxisClk        => axisClk,
                   sAxisRst        => axisRst,
                   sAxisMaster     => sAxisMasters(i),
                   sAxisSlave      => sAxisSlaves (i),
                   sPause          => open,
                   mAxiClk         => axiClk,
                   mAxiRst         => axiRst,
                   mAxiWriteMaster => mAxiWriteMasters(i),
                   mAxiWriteSlave  => mAxiWriteSlaves (i),
                   dscWriteMaster  => dscReadMasters  (i),
                   dscWriteSlave   => dscReadSlaves   (i),
                   config          => config,
                   status          => status          (i) );
    end generate;
  
  U_DUT2 : entity work.MigToPcieWrapper
    generic map ( LANES_G => LANES_C,
                  NAPP_G  => NAPP_C )
    port map (  -- Clock and reset
             axiClk           => axiClk,
             axiRst           => axiRst,
             -- AXI4 Interfaces to MIG
             axiReadMasters   => axiReadMasters,
             axiReadSlaves    => axiReadSlaves,
             -- AxiStream Interfaces from MIG (Data Mover command)
             dscReadMasters   => dscReadMasters,
             dscReadSlaves    => dscReadSlaves,
             -- AXI4 Interface to PCIe
             axiWriteMasters  => axiWriteMasters,
             axiWriteSlaves   => axiWriteSlaves,
             -- AXI Lite Interface
             axilClk          => axiClk,
             axilRst          => axiRst,
             axilWriteMaster  => axilWriteMaster,
             axilWriteSlave   => axilWriteSlave,
             axilReadMaster   => axilReadMaster,
             axilReadSlave    => axilReadSlave,
             --
             migStatus        => status );

  GEN_AXIRS : for i in 0 to LANES_C-1 generate
    --U_AxiSlave : entity work.AxiSlaveSim
    --  port map ( axiClk         => axiClk,
    --             axiRst         => axiRst,
    --             axiReadMaster  => axiReadMasters(i),
    --             axiReadSlave   => axiReadSlaves (i),
    --             axiWriteMaster => mAxiWriteMasters(i),
    --             axiWriteSlave  => mAxiWriteSlaves (i) );
    U_AxiReadSlave : entity work.AxiReadSlaveSim
      port map ( axiClk         => axiClk,
                 axiRst         => axiRst,
                 axiReadMaster  => axiReadMasters(i),
                 axiReadSlave   => axiReadSlaves (i) );
    U_AxiWriteSlave : entity work.AxiWriteSlaveSim
      port map ( axiClk         => axiClk,
                 axiRst         => axiRst,
                 axiWriteMaster => mAxiWriteMasters(i),
                 axiWriteSlave  => mAxiWriteSlaves (i) );
  end generate;
  GEN_AXIWS : for i in 0 to LANES_C+1 generate
    U_AxiWriteslave : entity work.AxiWriteSlaveSim
      port map ( axiClk => axiClk,
                 axiRst => axiRst,
                 axiWriteMaster => axiWriteMasters(i),
                 axiWriteSlave  => axiWriteSlaves (i) );
  end generate;

  memWriteMasters(0) <= axiWriteMasters(0);
  memReadMasters (0) <= axiReadMasters (0);
  
  --U_MIG0 : entity work.Mig0
  --  port map ( axiReady        => memReady(0),
  --             --
  --             axiClk          => axiClk,
  --             axiRst          => axiRst,
  --             axiWriteMasters => memWriteMasters(1 downto 0),
  --             axiWriteSlaves  => memWriteSlaves (1 downto 0),
  --             axiReadMasters  => memReadMasters (1 downto 0),
  --             axiReadSlaves   => memReadSlaves  (1 downto 0),
  --             --
  --             ddrClkP         => ddrClkP (0),
  --             ddrClkN         => ddrClkN (0),
  --             ddrOut          => ddrOut  (0),
  --             ddrInOut        => ddrInOut(0) );

  process is
    variable count : slv(31 downto 0) := (others=>'0');
  begin
    wait for 100 ns;
    if axisRst = '1' then
      wait until axisRst = '0';
    end if;
    if axilDone = '0' then
      wait until axilDone = '1';
    end if;

      --for i in 1 to 160 loop
      --  wait until axiClk = '0';
      --  dscReadMasters(0).command.tValid <= '1';
      --  dscReadMasters(0).command.tLast  <= '1';
      --  dscReadMasters(0).command.tData(79 downto 0) <= x"0" & -- reserved
      --                                                  x"0" & -- tag
      --                                                  toSlv(i,20) & toSlv(0,20) & -- address
      --                                                  "01" & toSlv(0,6) &
      --                                                  '1' & toSlv(4096*4,23);
      
      --  if dscReadSlaves(0).command.tReady = '0' then
      --    wait until dscReadSlaves(0).command.tReady = '1';
      --  end if;
      --  wait until axiClk = '1';
      --  dscReadMasters(0).command.tValid <= '0';
      --  wait for 1 us;
      --end loop;
      for i in 0 to 159 loop
        wait until (axisClk = '1' and (sAxisMasters(0).tValid = '0' or sAxisSlaves(0).tReady = '1'));
        wait until axisClk = '0';
        sAxisMasters(0).tValid <= '1';
        sAxisMasters(0).tLast  <= '0';
        if i = 0 then
          sAxisMasters(0).tData(63 downto 0) <= count & x"FEFEFEFE";
          count := count + 1;
        else
          for j in 0 to 7 loop
            sAxisMasters(0).tData(j*8+7 downto j*8) <= toSlv(j+8*i,8);
          end loop;
        end if;
      end loop;
      sAxisMasters(0).tLast <= '1';
      wait until (axisClk = '1' and sAxisSlaves(0).tReady = '1');
      sAxisMasters(0).tValid <= '0';
  end process;

  --process is
  --begin
  --  dscReadMasters(0).status.tReady <= '0';
  --  wait until dscReadSlaves(0).status.tValid = '1';
  --  dscReadMasters(0).status.tReady <= '1';
  --  wait until axiClk = '1';
  --  wait until axiClk = '0';
  --end process;

  process is
  begin
    axiClk <= '1';
    wait for 2.5 ns;
    axiClk <= '0';
    wait for 2.5 ns;
  end process;

  process is
  begin
    axiRst <= '1';
    wait for 20 ns;
    axiRst <= '0';
    wait;
  end process;

  process is
  begin
    axisClk <= '1';
    wait for 3.2 ns;
    axisClk <= '0';
    wait for 3.2 ns;
  end process;

  axisRst <= axiRst;
  
   process is
     procedure wreg(addr : integer; data : slv(31 downto 0)) is
     begin
       wait until axiClk='0';
       axilWriteMaster.awaddr  <= toSlv(addr,32);
       axilWriteMaster.awvalid <= '1';
       axilWriteMaster.wdata   <= data;
       axilWriteMaster.wvalid  <= '1';
       axilWriteMaster.bready  <= '0';
       wait until axiClk='1';
       if axilWriteSlave.bvalid='0' then
         wait until axilWriteSlave.bvalid='1';
       end if;
       axilWriteMaster.bready  <= '1';
       axilWriteMaster.awvalid <= '0';
       axilWriteMaster.wvalid  <= '0';
       if axiClk = '1' then
         wait until axiClk='0';
       end if;
       wait until axiClk='1';
       wait until axiClk='0';
       axilWriteMaster.bready  <= '0';
       wait for 50 ns;
     end procedure;

     variable phyAddr : slv(63 downto 0);
  begin
    axilDone <= '0';
    wait until axiRst='0';
    wait for 20 ns;

    for i in 16 to 25 loop
      phyAddr := toSlv(0,24) & toSlv(i,19) & toSlv(0,21); -- 2MB buffers
      wreg(32768+i*8,phyAddr(31 downto 0));
      wreg(32772+i*8,phyAddr(63 downto 32));
    end loop;
    
    wreg( 0,x"ABCD0000"); -- wrBaseAddr(31:0)
    wreg( 4,x"00000000"); -- wrBaseAddr(39:32)
    for i in 16 to 25 loop
      wreg(72,toSlv(i,32)); -- bufferId
    end loop;
    wreg(128,x"00000000");

    wreg(16, x"ABABAB00");  -- monBaseAddr
    wreg(20, x"000000CD");
    wreg( 4, toSlv(200,32) );-- monSampleIntv
    wreg( 8, toSlv(  5,32) );-- monReadoutIntv
    wreg(12, toSlv(  1,32) );-- monEnable
    
    wait for 20 ns;
    axilDone <= '1';
    wait;
  end process;

  U_INLET : entity work.AxisHistogram
    generic map ( ADDR_WIDTH_G => 3,
                  INLET_G      => true )
    port map ( clk         => axiClk,
               rst         => axiRst,
               wen         => ssamp,
               addr        => haddr(2 downto 0),
               axisClk     => axiClk,
               axisRst     => axiRst,
               sPush       => spush,
               mAxisMaster => haxisMaster(0),
               mAxisSlave  => haxisSlave (0) );
  GEN_HIST : for i in 0 to 3 generate
    U_HIST : entity work.AxisHistogram
    generic map ( ADDR_WIDTH_G => 4+i )
    port map ( clk         => axiClk,
               rst         => axiRst,
               wen         => ssamp,
               addr        => haddr(3+i downto 0),
               axisClk     => axiClk,
               axisRst     => axiRst,
               sAxisMaster => haxisMaster(i),
               sAxisSlave  => haxisSlave (i),
               mAxisMaster => haxisMaster(i+1),
               mAxisSlave  => haxisSlave (i+1) );
  end generate;

  GEN_MON_AXI : entity work.MonToPcieWrapper
    port map ( axiClk          => axiClk,
               axiRst          => axiRst,
               -- AXI Stream Interface
               sAxisMaster     => haxisMaster(4),
               sAxisSlave      => haxisSlave (4),
               -- AXI4 Interface to PCIe
               mAxiWriteMaster => haxiWriteMaster,
               mAxiWriteSlave  => haxiWriteSlave,
               -- Configuration
               enable          => '1',
               mAxiAddr        => x"3fabcd0000" );

     U_HaxiWriteslave : entity work.AxiWriteSlaveSim
       port map ( axiClk => axiClk,
                  axiRst => axiRst,
                  axiWriteMaster => haxiWriteMaster,
                  axiWriteSlave  => haxiWriteSlave );
     
  process ( axiClk, axiRst ) is
    variable cnt : slv(3 downto 0) := (others=>'0');
  begin
    if rising_edge(axiClk) then
      if cnt = toSlv(13,4) then
        cnt := (others=>'0');
        ssamp <= '1';
      else
        cnt := cnt + 1;
        ssamp <= '0';
      end if;

      spush <= '0';
      if haddr = toSlv(1020,10) then
        spush <= '1';
      end if;
      haddr <= haddr+1;
    end if;
  end process;

  process is
  begin
    ddrClkP(0) <= '1';
    ddrClkN(0) <= '0';
    wait for 1.667 ns;
    ddrClkP(0) <= '0';
    ddrClkN(0) <= '1';
    wait for 1.667 ns;
  end process;
     
end architecture;

