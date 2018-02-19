-------------------------------------------------------------------------------
-- File       : AppToMigWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-02-18
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx Axi Data Mover
-- Axi stream input (dscReadMasters.command) launches an AxiReadMaster to
-- read from a memory mapped device and write to another memory mapped device
-- with an AxiWriteMaster to a start address given by the AxiLite bus register
-- writes.  Completion of the transfer results in another axi write.
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-core'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-core', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDescPkg.all;
use work.MigPkg.all;

entity AppToMigWrapper is
  generic ( AXI_STREAM_CONFIG_G : AxiStreamConfigType;
            AXI_BASE_ADDR_G     : slv(31 downto 0) := (others=>'0');
            DEBUG_G             : boolean          := false );
  port    ( -- Clock and reset
    sAxisClk         : in  sl; -- 156MHz
    sAxisRst         : in  sl;
    sAxisMaster      : in  AxiStreamMasterType;
    sAxisSlave       : out AxiStreamSlaveType ;
    sPause           : out sl;
    -- AXI4 Interface to MIG
    mAxiClk          : in  sl; -- 200MHz
    mAxiRst          : in  sl;
    mAxiWriteMaster  : out AxiWriteMasterType ;
    mAxiWriteSlave   : in  AxiWriteSlaveType  ;
    -- Command/Status
    dscWriteMaster   : out AxiDescMasterType  ;
    dscWriteSlave    : in  AxiDescSlaveType   ;
    -- Configuration
    memReady         : in  sl := '0';
    config           : in  MigConfigType;
    -- Status
    status           : out MigStatusType );
end AppToMigWrapper;

architecture mapping of AppToMigWrapper is

  COMPONENT AppToMig
    PORT (
      m_axi_s2mm_aclk : IN STD_LOGIC;
      m_axi_s2mm_aresetn : IN STD_LOGIC;
      s2mm_err : OUT STD_LOGIC;
      m_axis_s2mm_cmdsts_awclk : IN STD_LOGIC;
      m_axis_s2mm_cmdsts_aresetn : IN STD_LOGIC;
      s_axis_s2mm_cmd_tvalid : IN STD_LOGIC;
      s_axis_s2mm_cmd_tready : OUT STD_LOGIC;
      s_axis_s2mm_cmd_tdata : IN STD_LOGIC_VECTOR(71 DOWNTO 0);
      m_axis_s2mm_sts_tvalid : OUT STD_LOGIC;
      m_axis_s2mm_sts_tready : IN STD_LOGIC;
      m_axis_s2mm_sts_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axis_s2mm_sts_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axis_s2mm_sts_tlast : OUT STD_LOGIC;
      m_axi_s2mm_awid : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awaddr : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_axi_s2mm_awlen : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      m_axi_s2mm_awsize : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awburst : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_awprot : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      m_axi_s2mm_awcache : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awuser : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_axi_s2mm_awvalid : OUT STD_LOGIC;
      m_axi_s2mm_awready : IN STD_LOGIC;
      m_axi_s2mm_wdata : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
      m_axi_s2mm_wstrb : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0);
      m_axi_s2mm_wlast : OUT STD_LOGIC;
      m_axi_s2mm_wvalid : OUT STD_LOGIC;
      m_axi_s2mm_wready : IN STD_LOGIC;
      m_axi_s2mm_bresp : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      m_axi_s2mm_bvalid : IN STD_LOGIC;
      m_axi_s2mm_bready : OUT STD_LOGIC;
      s_axis_s2mm_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
      s_axis_s2mm_tkeep : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s_axis_s2mm_tlast : IN STD_LOGIC;
      s_axis_s2mm_tvalid : IN STD_LOGIC;
      s_axis_s2mm_tready : OUT STD_LOGIC
      );
  END COMPONENT;

  signal mAxisMaster : AxiStreamMasterType;
  signal mAxisSlave  : AxiStreamSlaveType;

  signal intDscWriteMaster : AxiDescMasterType;
  signal intDscWriteSlave  : AxiDescSlaveType;

  signal wrTransfer   : sl;
  signal dinTransfer  : slv(22 downto 0);
  signal doutTransfer : slv(22 downto 0);
  
  signal axiRstN : sl;
  signal mPause  : sl;
  
  type RegType is record
    cmIndex        : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
    wrIndex        : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
    rdIndex        : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
    locMaster      : AxiDescMasterType;
    remMaster      : AxiDescMasterType;
    blocksFree     : slv(BLOCK_INDEX_SIZE_C-1 downto 0);
  end record;

  constant REG_INIT_C : RegType := (
    cmIndex        => (others=>'0'),
    wrIndex        => (others=>'0'),
    rdIndex        => (others=>'0'),
    locMaster      => AXI_DESC_MASTER_INIT_C,
    remMaster      => AXI_DESC_MASTER_INIT_C,
    blocksFree     => (others=>'0') );

  signal r   : RegType := REG_INIT_C;
  signal rin : RegType;

  signal isAxisSlave : AxiStreamSlaveType;
  signal isPause     : sl;
  
  signal imAxiWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;

  component ila_0
    port ( clk          : in sl;
           probe0       : in slv(255 downto 0) );
  end component;

  signal trig_out_app : sl;
  signal trig_out_mig : sl;
  
begin

  GEN_DEBUG : if DEBUG_G generate
    U_ILA_APP : ila_0
      port map ( clk          => sAxisClk,
                 probe0(0)    => sAxisRst,
                 probe0(1)    => sAxisMaster.tValid,
                 probe0(2)    => sAxisMaster.tLast,
                 probe0(3)    => isAxisSlave.tReady,
                 probe0(4)    => isPause,
                 probe0(255 downto 5) => (others=>'0') );
    U_ILA_MIG : ila_0
      port map ( clk          => mAxiClk,
                 probe0(0)              => imAxiWriteMaster.awvalid,
                 probe0(32 downto 1)    => imAxiWriteMaster.awaddr(31 downto 0),
                 probe0(40 downto 33)   => imAxiWriteMaster.awlen,
                 probe0(43 downto 41)   => imAxiWriteMaster.awsize,
                 probe0(44)             => mAxiWriteSlave.awready,
                 probe0(45)              => imAxiWriteMaster.wvalid,
                 probe0(46)              => imAxiWriteMaster.wlast,
                 probe0(47)              => mAxiWriteSlave.wready,
                 probe0(48)              => mAxiWriteSlave.bvalid,
                 probe0(50 downto 49)    => mAxiWriteSlave.bresp,
                 probe0(51)              => imAxiWriteMaster.bready,
                 probe0(52)              => intDscWriteMaster.command.tValid,
                 probe0(124 downto 53)   => intDscWriteMaster.command.tData(71 downto 0),
                 probe0(125)             => intDscWriteMaster.command.tLast,
                 probe0(126)             => intDscWriteSlave .command.tReady,
                 probe0(127)             => intDscWriteSlave .status .tValid,
                 probe0(159 downto 128)  => intDscWriteSlave .status .tData(31 downto 0),
                 probe0(160)             => intDscWriteMaster.status .tReady,
                 probe0(161)             => r.remMaster.command.tValid,
                 probe0(233 downto 162)  => r.remMaster.command.tData(71 downto 0),
                 probe0(234)             => dscWriteSlave.command.tReady,
                 probe0(255 downto 235)  => (others=>'0') );
  end generate;

  sAxisSlave                <= isAxisSlave;
  sPause                    <= isPause;
  status.blocksFree         <= r.blocksFree;
  dscWriteMaster            <= r.remMaster;
  intDscWriteMaster.command <= r  .locMaster.command;
  intDscWriteMaster.status  <= rin.locMaster.status;
  mAxiWriteMaster           <= imAxiWriteMaster;
  
  mPause <= '1' when (r.blocksFree < config.blocksPause) else '0';
  
  U_Pause : entity work.Synchronizer
    port map ( clk     => sAxisClk,
               rst     => sAxisRst,
               dataIn  => mPause,
               dataOut => isPause );

  U_Ready : entity work.Synchronizer
    port map ( clk     => mAxiClk,
               rst     => mAxiRst,
               dataIn  => memReady,
               dataOut => status.memReady );
  
  --
  --  Insert a fifo to cross clock domains
  --
  U_AxisFifo : entity work.AxiStreamFifo
    generic map ( FIFO_ADDR_WIDTH_G   => 4,
                  SLAVE_AXI_CONFIG_G  => AXI_STREAM_CONFIG_G,
                  MASTER_AXI_CONFIG_G => AXI_STREAM_CONFIG_G )
    port map ( sAxisClk    => sAxisClk,
               sAxisRst    => sAxisRst,
               sAxisMaster => sAxisMaster,
               sAxisSlave  => isAxisSlave,
               sAxisCtrl   => open,
               mAxisClk    => mAxiClk,
               mAxisRst    => mAxiRst,
               mAxisMaster => mAxisMaster,
               mAxisSlave  => mAxisSlave );
  
  axiRstN                  <= not mAxiRst;

  --
  --  Translate AxiStream to Axi using fixed size starting block addresses
  --
  U_ADM : AppToMig
    port map ( m_axi_s2mm_aclk            => mAxiClk,
               m_axi_s2mm_aresetn         => axiRstN,
               s2mm_err                   => open,
               m_axis_s2mm_cmdsts_awclk   => mAxiClk,
               m_axis_s2mm_cmdsts_aresetn => axiRstN,
               s_axis_s2mm_cmd_tvalid     => intDscWriteMaster.command.tValid,
               s_axis_s2mm_cmd_tready     => intDscWriteSlave .command.tReady,
               s_axis_s2mm_cmd_tdata      => intDscWriteMaster.command.tData(71 DOWNTO 0),
               m_axis_s2mm_sts_tvalid     => intDscWriteSlave .status.tValid,
               m_axis_s2mm_sts_tready     => intDscWriteMaster.status.tReady,
               m_axis_s2mm_sts_tdata      => intDscWriteSlave .status.tData(31 DOWNTO 0),
               m_axis_s2mm_sts_tkeep      => intDscWriteSlave .status.tKeep(3 DOWNTO 0),
               m_axis_s2mm_sts_tlast      => intDscWriteSlave .status.tLast,
               m_axi_s2mm_awid            => imAxiWriteMaster.awid(3 downto 0),
               m_axi_s2mm_awaddr          => imAxiWriteMaster.awaddr(31 downto 0),
               m_axi_s2mm_awlen           => imAxiWriteMaster.awlen,
               m_axi_s2mm_awsize          => imAxiWriteMaster.awsize,
               m_axi_s2mm_awburst         => imAxiWriteMaster.awburst,
               m_axi_s2mm_awprot          => imAxiWriteMaster.awprot,
               m_axi_s2mm_awcache         => imAxiWriteMaster.awcache,
--                 m_axi_s2mm_awuser          => imAxiWriteMaster.awuser,
               m_axi_s2mm_awvalid         => imAxiWriteMaster.awvalid,
               m_axi_s2mm_awready         => mAxiWriteSlave .awready,
               m_axi_s2mm_wdata           => imAxiWriteMaster.wdata(63 downto 0),
               m_axi_s2mm_wstrb           => imAxiWriteMaster.wstrb( 7 downto 0),
               m_axi_s2mm_wlast           => imAxiWriteMaster.wlast,
               m_axi_s2mm_wvalid          => imAxiWriteMaster.wvalid,
               m_axi_s2mm_wready          => mAxiWriteSlave .wready,
               m_axi_s2mm_bresp           => mAxiWriteSlave .bresp,
               m_axi_s2mm_bvalid          => mAxiWriteSlave .bvalid,
               m_axi_s2mm_bready          => imAxiWriteMaster.bready,
               s_axis_s2mm_tdata          => mAxisMaster.tData(63 downto 0),
               s_axis_s2mm_tkeep          => mAxisMaster.tKeep( 7 downto 0),
               s_axis_s2mm_tlast          => mAxisMaster.tLast,
               s_axis_s2mm_tvalid         => mAxisMaster.tValid,
               s_axis_s2mm_tready         => mAxisSlave.tReady
               );
  
  wrTransfer  <= intDscWriteSlave.status.tValid and intDscWriteMaster.status.tReady;
  dinTransfer <= intDscWriteSlave.status.tData(30 downto 8);
  
  U_TransferFifo : entity work.SimpleDualPortRam
    generic map ( DATA_WIDTH_G => 23,
                  ADDR_WIDTH_G => BLOCK_INDEX_SIZE_C )
    port map ( clka       => mAxiClk,
               ena        => '1',
               wea        => wrTransfer,
               addra      => r.wrIndex,
               dina       => dinTransfer,
               clkb       => mAxiClk,
               enb        => '1',
               rstb       => mAxiRst,
               addrb      => r.rdIndex,
               doutb      => doutTransfer );

  comb : process ( r, mAxiRst, 
                   doutTransfer ,
                   dscWriteSlave,
                   intDscWriteSlave,
                   config ) is
    variable v       : RegType;
    variable i       : integer;
    variable wlen    : slv(22 downto 0);
    variable waddr   : slv(31 downto 0);
    variable rlen    : slv(22 downto 0);
    variable raddr   : slv(31 downto 0);
  begin
    v := r;

    i := BLOCK_BASE_SIZE_C;
    
    --
    --  Keep stuffing new block addresses into the Axi engine
    --
    if intDscWriteSlave.command.tReady = '1' then
      v.locMaster.command.tValid := '0';
    end if;

    if v.locMaster.command.tValid = '0' then
      waddr   := resize(r.cmIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      wlen    := (others=>'0');
      wlen(i) := '1';
      v.locMaster.command.tData(71 downto 0) := x"0" & toSlv(0,4) &
                                                waddr &
                                                "01" & toSlv(0,6) &
                                                '1' & wlen;
      v.locMaster.command.tValid := '1';
      v.locMaster.command.tLast  := '1';
      v.cmIndex := r.cmIndex + 1;
    end if;

    --  Must hold to one clock edge
    if r.locMaster.status.tReady = '1' then
      v.locMaster.status.tReady := '0';
    end if;

    if intDscWriteSlave.status.tValid = '1' then
      v.locMaster.status.tReady := '1';
      v.wrIndex                 := r.wrIndex + 1;
    end if;
    
    if dscWriteSlave.command.tReady = '1' then
      v.remMaster.command.tValid := '0';
    end if;
    
    if (v.remMaster.command.tValid = '0' and
        r.rdIndex /= r.wrIndex) then
      raddr   := resize(r.rdIndex & toSlv(0,i), 32) + AXI_BASE_ADDR_G;
      rlen    := doutTransfer;
      v.remMaster.command.tData(71 downto 0) := x"0" & toSlv(0,4) &
                                                raddr &
                                                "01" & toSlv(0,6) &
                                                '1' & rlen;
      v.remMaster.command.tValid := '1';
      v.remMaster.command.tLast  := '1';
      v.rdIndex                  := r.rdIndex + 1;
    end if;

    v.remMaster.status.tReady := '0';
    if dscWriteSlave.status.tValid = '1' then
      v.remMaster.status.tReady := '1';
    end if;

    v.blocksFree := resize(r.rdIndex - r.wrIndex - 1, BLOCK_INDEX_SIZE_C);
    
    if mAxiRst = '1' then
      v := REG_INIT_C;
    end if;
    
    rin <= v;

  end process comb;

  seq: process(mAxiClk) is
  begin
    if rising_edge(mAxiClk) then
      r <= rin;
    end if;
  end process seq;
  
  
end mapping;



