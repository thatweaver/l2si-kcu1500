-------------------------------------------------------------------------------
-- File       : MigXbar.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-08-02
-- Last update: 2018-01-24
-------------------------------------------------------------------------------
-- Description: Wrapper for the "store-and-forward" AXI FIFO
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

use work.StdRtlPkg.all;
use work.AxiPkg.all;

entity MigXbar is
   generic (
      TPD_G : time := 1 ns);
   port (
      -- Slave Interfaces
      sWrClk           : in  slv                (1 downto 0);
      sWrRst           : out slv                (1 downto 0);
      sAxiWriteMasters : in  AxiWriteMasterArray(1 downto 0);
      sAxiWriteSlaves  : out AxiWriteSlaveArray (1 downto 0);
      sRdClk           : in  slv                (1 downto 0);
      sRdRst           : out slv                (1 downto 0);
      sAxiReadMasters  : in  AxiReadMasterArray (1 downto 0);
      sAxiReadSlaves   : out AxiReadSlaveArray  (1 downto 0);
      -- Master Interface
      mAxiClk          : in  sl;
      mAxiRst          : out sl;
      mAxiWriteMaster  : out AxiWriteMasterType;
      mAxiWriteSlave   : in  AxiWriteSlaveType;
      mAxiReadMaster   : out AxiReadMasterType;
      mAxiReadSlave    : in  AxiReadSlaveType);
end MigXbar;

architecture mapping of MigXbar is

   component DdrXbar
      port (
         INTERCONNECT_ACLK    : in  std_logic;
         INTERCONNECT_ARESETN : in  std_logic;
         S00_AXI_ARESET_OUT_N : out std_logic;
         S00_AXI_ACLK         : in  std_logic;
         S00_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S00_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_AWLOCK       : in  std_logic;
         S00_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_AWVALID      : in  std_logic;
         S00_AXI_AWREADY      : out std_logic;
         S00_AXI_WDATA        : in  std_logic_vector(255 downto 0);
         S00_AXI_WSTRB        : in  std_logic_vector( 31 downto 0);
         S00_AXI_WLAST        : in  std_logic;
         S00_AXI_WVALID       : in  std_logic;
         S00_AXI_WREADY       : out std_logic;
         S00_AXI_BID          : out std_logic_vector(0 downto 0);
         S00_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_BVALID       : out std_logic;
         S00_AXI_BREADY       : in  std_logic;
         S00_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S00_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S00_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S00_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S00_AXI_ARLOCK       : in  std_logic;
         S00_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S00_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S00_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S00_AXI_ARVALID      : in  std_logic;
         S00_AXI_ARREADY      : out std_logic;
         S00_AXI_RID          : out std_logic_vector(0 downto 0);
         S00_AXI_RDATA        : out std_logic_vector(255 downto 0);
         S00_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S00_AXI_RLAST        : out std_logic;
         S00_AXI_RVALID       : out std_logic;
         S00_AXI_RREADY       : in  std_logic;
         S01_AXI_ARESET_OUT_N : out std_logic;
         S01_AXI_ACLK         : in  std_logic;
         S01_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S01_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S01_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_AWLOCK       : in  std_logic;
         S01_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_AWVALID      : in  std_logic;
         S01_AXI_AWREADY      : out std_logic;
         S01_AXI_WDATA        : in  std_logic_vector(255 downto 0);
         S01_AXI_WSTRB        : in  std_logic_vector(31 downto 0);
         S01_AXI_WLAST        : in  std_logic;
         S01_AXI_WVALID       : in  std_logic;
         S01_AXI_WREADY       : out std_logic;
         S01_AXI_BID          : out std_logic_vector(0 downto 0);
         S01_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_BVALID       : out std_logic;
         S01_AXI_BREADY       : in  std_logic;
         S01_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S01_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S01_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S01_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S01_AXI_ARLOCK       : in  std_logic;
         S01_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S01_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S01_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S01_AXI_ARVALID      : in  std_logic;
         S01_AXI_ARREADY      : out std_logic;
         S01_AXI_RID          : out std_logic_vector(0 downto 0);
         S01_AXI_RDATA        : out std_logic_vector(255 downto 0);
         S01_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S01_AXI_RLAST        : out std_logic;
         S01_AXI_RVALID       : out std_logic;
         S01_AXI_RREADY       : in  std_logic;
         S02_AXI_ARESET_OUT_N : out std_logic;
         S02_AXI_ACLK         : in  std_logic;
         S02_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S02_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S02_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_AWLOCK       : in  std_logic;
         S02_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_AWVALID      : in  std_logic;
         S02_AXI_AWREADY      : out std_logic;
         S02_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S02_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S02_AXI_WLAST        : in  std_logic;
         S02_AXI_WVALID       : in  std_logic;
         S02_AXI_WREADY       : out std_logic;
         S02_AXI_BID          : out std_logic_vector(0 downto 0);
         S02_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_BVALID       : out std_logic;
         S02_AXI_BREADY       : in  std_logic;
         S02_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S02_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S02_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S02_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S02_AXI_ARLOCK       : in  std_logic;
         S02_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S02_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S02_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S02_AXI_ARVALID      : in  std_logic;
         S02_AXI_ARREADY      : out std_logic;
         S02_AXI_RID          : out std_logic_vector(0 downto 0);
         S02_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S02_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S02_AXI_RLAST        : out std_logic;
         S02_AXI_RVALID       : out std_logic;
         S02_AXI_RREADY       : in  std_logic;
         S03_AXI_ARESET_OUT_N : out std_logic;
         S03_AXI_ACLK         : in  std_logic;
         S03_AXI_AWID         : in  std_logic_vector(0 downto 0);
         S03_AXI_AWADDR       : in  std_logic_vector(31 downto 0);
         S03_AXI_AWLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_AWSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_AWLOCK       : in  std_logic;
         S03_AXI_AWCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_AWPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_AWQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_AWVALID      : in  std_logic;
         S03_AXI_AWREADY      : out std_logic;
         S03_AXI_WDATA        : in  std_logic_vector(127 downto 0);
         S03_AXI_WSTRB        : in  std_logic_vector( 15 downto 0);
         S03_AXI_WLAST        : in  std_logic;
         S03_AXI_WVALID       : in  std_logic;
         S03_AXI_WREADY       : out std_logic;
         S03_AXI_BID          : out std_logic_vector(0 downto 0);
         S03_AXI_BRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_BVALID       : out std_logic;
         S03_AXI_BREADY       : in  std_logic;
         S03_AXI_ARID         : in  std_logic_vector(0 downto 0);
         S03_AXI_ARADDR       : in  std_logic_vector(31 downto 0);
         S03_AXI_ARLEN        : in  std_logic_vector(7 downto 0);
         S03_AXI_ARSIZE       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARBURST      : in  std_logic_vector(1 downto 0);
         S03_AXI_ARLOCK       : in  std_logic;
         S03_AXI_ARCACHE      : in  std_logic_vector(3 downto 0);
         S03_AXI_ARPROT       : in  std_logic_vector(2 downto 0);
         S03_AXI_ARQOS        : in  std_logic_vector(3 downto 0);
         S03_AXI_ARVALID      : in  std_logic;
         S03_AXI_ARREADY      : out std_logic;
         S03_AXI_RID          : out std_logic_vector(0 downto 0);
         S03_AXI_RDATA        : out std_logic_vector(127 downto 0);
         S03_AXI_RRESP        : out std_logic_vector(1 downto 0);
         S03_AXI_RLAST        : out std_logic;
         S03_AXI_RVALID       : out std_logic;
         S03_AXI_RREADY       : in  std_logic;
         M00_AXI_ARESET_OUT_N : out std_logic;
         M00_AXI_ACLK         : in  std_logic;
         M00_AXI_AWID         : out std_logic_vector(3 downto 0);
         M00_AXI_AWADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_AWLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_AWSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_AWBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_AWLOCK       : out std_logic;
         M00_AXI_AWCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_AWPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_AWQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_AWVALID      : out std_logic;
         M00_AXI_AWREADY      : in  std_logic;
         M00_AXI_WDATA        : out std_logic_vector(511 downto 0);
         M00_AXI_WSTRB        : out std_logic_vector(63 downto 0);
         M00_AXI_WLAST        : out std_logic;
         M00_AXI_WVALID       : out std_logic;
         M00_AXI_WREADY       : in  std_logic;
         M00_AXI_BID          : in  std_logic_vector(3 downto 0);
         M00_AXI_BRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_BVALID       : in  std_logic;
         M00_AXI_BREADY       : out std_logic;
         M00_AXI_ARID         : out std_logic_vector(3 downto 0);
         M00_AXI_ARADDR       : out std_logic_vector(31 downto 0);
         M00_AXI_ARLEN        : out std_logic_vector(7 downto 0);
         M00_AXI_ARSIZE       : out std_logic_vector(2 downto 0);
         M00_AXI_ARBURST      : out std_logic_vector(1 downto 0);
         M00_AXI_ARLOCK       : out std_logic;
         M00_AXI_ARCACHE      : out std_logic_vector(3 downto 0);
         M00_AXI_ARPROT       : out std_logic_vector(2 downto 0);
         M00_AXI_ARQOS        : out std_logic_vector(3 downto 0);
         M00_AXI_ARVALID      : out std_logic;
         M00_AXI_ARREADY      : in  std_logic;
         M00_AXI_RID          : in  std_logic_vector(3 downto 0);
         M00_AXI_RDATA        : in  std_logic_vector(511 downto 0);
         M00_AXI_RRESP        : in  std_logic_vector(1 downto 0);
         M00_AXI_RLAST        : in  std_logic;
         M00_AXI_RVALID       : in  std_logic;
         M00_AXI_RREADY       : out std_logic
         );
   end component;

   signal axiClk      : sl;
   signal axiRst      : sl;
   signal axiRstL     : sl;
   signal mAxiRstSync : sl;

begin

   axiClk  <= sAxiClk;
   axiRst  <= sAxiRst or mAxiRstSync;
   axiRstL <= not(axiRst);

   U_Sync : entity work.Synchronizer
      generic map (
         TPD_G => TPD_G)
      port map (
         clk     => sAxiClk,
         dataIn  => mAxiRst,
         dataOut => mAxiRstSync);

   U_XBAR : DdrXbar
      port map (
         INTERCONNECT_ACLK    => axiClk,
         INTERCONNECT_ARESETN => axiRstL,
         -- SLAVE[0]
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => sRdClk(0),
         S00_AXI_AWID(0)      => '0',
         S00_AXI_AWADDR       => (others=>'0'),
         S00_AXI_AWLEN        => (others=>'0'),
         S00_AXI_AWSIZE       => (others=>'0'),
         S00_AXI_AWBURST      => (others=>'0'),
         S00_AXI_AWLOCK       => '0',
         S00_AXI_AWCACHE      => (others=>'0'),
         S00_AXI_AWPROT       => (others=>'0'),
         S00_AXI_AWQOS        => (others=>'0'),
         S00_AXI_AWVALID      => '0',
         S00_AXI_AWREADY      => open
         S00_AXI_WDATA        => (others=>'0'),
         S00_AXI_WSTRB        => (others=>'0'),
         S00_AXI_WLAST        => '0',
         S00_AXI_WVALID       => '0',
         S00_AXI_WREADY       => open,
         S00_AXI_BID          => open,
         S00_AXI_BRESP        => open,
         S00_AXI_BVALID       => open,
         S00_AXI_BREADY       => '0',
         S00_AXI_ARID(0)      => '0',
         S00_AXI_ARADDR       => sAxiReadMasters(0).araddr(31 downto 0),
         S00_AXI_ARLEN        => sAxiReadMasters(0).arlen,
         S00_AXI_ARSIZE       => sAxiReadMasters(0).arsize,
         S00_AXI_ARBURST      => sAxiReadMasters(0).arburst,
         S00_AXI_ARLOCK       => sAxiReadMasters(0).arlock(0),
         S00_AXI_ARCACHE      => sAxiReadMasters(0).arcache,
         S00_AXI_ARPROT       => sAxiReadMasters(0).arprot,
         S00_AXI_ARQOS        => sAxiReadMasters(0).arqos,
         S00_AXI_ARVALID      => sAxiReadMasters(0).arvalid,
         S00_AXI_ARREADY      => sAxiReadSlaves(0).arready,
         S00_AXI_RID          => sAxiReadSlaves(0).rid(0 downto 0),
         S00_AXI_RDATA        => sAxiReadSlaves(0).rdata(255 downto 0),
         S00_AXI_RRESP        => sAxiReadSlaves(0).rresp,
         S00_AXI_RLAST        => sAxiReadSlaves(0).rlast,
         S00_AXI_RVALID       => sAxiReadSlaves(0).rvalid,
         S00_AXI_RREADY       => sAxiReadMasters(0).rready,
         -- SLAVE[1]
         S01_AXI_ARESET_OUT_N => open,
         S01_AXI_ACLK         => sRdClk(1),
         S01_AXI_AWID(0)      => '0',
         S01_AXI_AWADDR       => (others=>'0'),
         S01_AXI_AWLEN        => (others=>'0'),
         S01_AXI_AWSIZE       => (others=>'0'),
         S01_AXI_AWBURST      => (others=>'0'),
         S01_AXI_AWLOCK       => '0',
         S01_AXI_AWCACHE      => (others=>'0'),
         S01_AXI_AWPROT       => (others=>'0'),
         S01_AXI_AWQOS        => (others=>'0'),
         S01_AXI_AWVALID      => '0',
         S01_AXI_AWREADY      => open,
         S01_AXI_WDATA        => (others=>'0'),
         S01_AXI_WSTRB        => (others=>'0'),
         S01_AXI_WLAST        => '0',
         S01_AXI_WVALID       => '0',
         S01_AXI_WREADY       => open,
         S01_AXI_BID          => open,
         S01_AXI_BRESP        => open,
         S01_AXI_BVALID       => open,
         S01_AXI_BREADY       => '0',
         S01_AXI_ARID(0)      => '0',
         S01_AXI_ARADDR       => sAxiReadMasters(1).araddr(31 downto 0),
         S01_AXI_ARLEN        => sAxiReadMasters(1).arlen,
         S01_AXI_ARSIZE       => sAxiReadMasters(1).arsize,
         S01_AXI_ARBURST      => sAxiReadMasters(1).arburst,
         S01_AXI_ARLOCK       => sAxiReadMasters(1).arlock(0),
         S01_AXI_ARCACHE      => sAxiReadMasters(1).arcache,
         S01_AXI_ARPROT       => sAxiReadMasters(1).arprot,
         S01_AXI_ARQOS        => sAxiReadMasters(1).arqos,
         S01_AXI_ARVALID      => sAxiReadMasters(1).arvalid,
         S01_AXI_ARREADY      => sAxiReadSlaves(1).arready,
         S01_AXI_RID          => sAxiReadSlaves(1).rid(0 downto 0),
         S01_AXI_RDATA        => sAxiReadSlaves(1).rdata(255 downto 0),
         S01_AXI_RRESP        => sAxiReadSlaves(1).rresp,
         S01_AXI_RLAST        => sAxiReadSlaves(1).rlast,
         S01_AXI_RVALID       => sAxiReadSlaves(1).rvalid,
         S01_AXI_RREADY       => sAxiReadMasters(1).rready,
         -- SLAVE[2]
         S02_AXI_ARESET_OUT_N => open,
         S02_AXI_ACLK         => sWrClk(0),
         S02_AXI_AWID(0)      => '0',
         S02_AXI_AWADDR       => sAxiWriteMasters(0).awaddr(31 downto 0),
         S02_AXI_AWLEN        => sAxiWriteMasters(0).awlen,
         S02_AXI_AWSIZE       => sAxiWriteMasters(0).awsize,
         S02_AXI_AWBURST      => sAxiWriteMasters(0).awburst,
         S02_AXI_AWLOCK       => sAxiWriteMasters(0).awlock(0),
         S02_AXI_AWCACHE      => sAxiWriteMasters(0).awcache,
         S02_AXI_AWPROT       => sAxiWriteMasters(0).awprot,
         S02_AXI_AWQOS        => sAxiWriteMasters(0).awqos,
         S02_AXI_AWVALID      => sAxiWriteMasters(0).awvalid,
         S02_AXI_AWREADY      => sAxiWriteSlaves(0).awready,
         S02_AXI_WDATA        => sAxiWriteMasters(0).wdata(63 downto 0),
         S02_AXI_WSTRB        => sAxiWriteMasters(0).wstrb( 7 downto 0),
         S02_AXI_WLAST        => sAxiWriteMasters(0).wlast,
         S02_AXI_WVALID       => sAxiWriteMasters(0).wvalid,
         S02_AXI_WREADY       => sAxiWriteSlaves(0).wready,
         S02_AXI_BID          => sAxiWriteSlaves(0).bid(0 downto 0),
         S02_AXI_BRESP        => sAxiWriteSlaves(0).bresp,
         S02_AXI_BVALID       => sAxiWriteSlaves(0).bvalid,
         S02_AXI_BREADY       => sAxiWriteMasters(0).bready,
         S02_AXI_ARID(0)      => '0',
         S02_AXI_ARADDR       => (others=>'0'),
         S02_AXI_ARLEN        => (others=>'0'),
         S02_AXI_ARSIZE       => (others=>'0'),
         S02_AXI_ARBURST      => (others=>'0'),
         S02_AXI_ARLOCK       => '0',
         S02_AXI_ARCACHE      => (others=>'0'),
         S02_AXI_ARPROT       => (others=>'0'),
         S02_AXI_ARQOS        => (others=>'0'),
         S02_AXI_ARVALID      => '0',
         S02_AXI_ARREADY      => open,
         S02_AXI_RID          => open,
         S02_AXI_RDATA        => open,
         S02_AXI_RRESP        => open,
         S02_AXI_RLAST        => open,
         S02_AXI_RVALID       => open,
         S02_AXI_RREADY       => '0',
         -- SLAVE[3]
         S03_AXI_ARESET_OUT_N => open,
         S03_AXI_ACLK         => sWrClk(1),
         S03_AXI_AWID(0)      => '0',
         S03_AXI_AWADDR       => sAxiWriteMasters(1).awaddr(31 downto 0),
         S03_AXI_AWLEN        => sAxiWriteMasters(1).awlen,
         S03_AXI_AWSIZE       => sAxiWriteMasters(1).awsize,
         S03_AXI_AWBURST      => sAxiWriteMasters(1).awburst,
         S03_AXI_AWLOCK       => sAxiWriteMasters(1).awlock(0),
         S03_AXI_AWCACHE      => sAxiWriteMasters(1).awcache,
         S03_AXI_AWPROT       => sAxiWriteMasters(1).awprot,
         S03_AXI_AWQOS        => sAxiWriteMasters(1).awqos,
         S03_AXI_AWVALID      => sAxiWriteMasters(1).awvalid,
         S03_AXI_AWREADY      => sAxiWriteSlaves(1).awready,
         S03_AXI_WDATA        => sAxiWriteMasters(1).wdata(63 downto 0),
         S03_AXI_WSTRB        => sAxiWriteMasters(1).wstrb( 7 downto 0),
         S03_AXI_WLAST        => sAxiWriteMasters(1).wlast,
         S03_AXI_WVALID       => sAxiWriteMasters(1).wvalid,
         S03_AXI_WREADY       => sAxiWriteSlaves(1).wready,
         S03_AXI_BID          => sAxiWriteSlaves(1).bid(0 downto 0),
         S03_AXI_BRESP        => sAxiWriteSlaves(1).bresp,
         S03_AXI_BVALID       => sAxiWriteSlaves(1).bvalid,
         S03_AXI_BREADY       => sAxiWriteMasters(1).bready,
         S03_AXI_ARID(0)      => '0',
         S03_AXI_ARADDR       => (others=>'0'),
         S03_AXI_ARLEN        => (others=>'0'),
         S03_AXI_ARSIZE       => (others=>'0'),
         S03_AXI_ARBURST      => (others=>'0'),
         S03_AXI_ARLOCK       => '0',
         S03_AXI_ARCACHE      => (others=>'0'),
         S03_AXI_ARPROT       => (others=>'0'),
         S03_AXI_ARQOS        => (others=>'0'),
         S03_AXI_ARVALID      => '0',
         S03_AXI_ARREADY      => open,
         S03_AXI_RID          => open,
         S03_AXI_RDATA        => open,
         S03_AXI_RRESP        => open,
         S03_AXI_RLAST        => open,
         S03_AXI_RVALID       => open,
         S03_AXI_RREADY       => open,
         -- MASTER         
         M00_AXI_ARESET_OUT_N => open,
         M00_AXI_ACLK         => mAxiClk,
         M00_AXI_AWID         => mAxiWriteMaster.awid(3 downto 0),
         M00_AXI_AWADDR       => mAxiWriteMaster.awaddr(31 downto 0),
         M00_AXI_AWLEN        => mAxiWriteMaster.awlen,
         M00_AXI_AWSIZE       => mAxiWriteMaster.awsize,
         M00_AXI_AWBURST      => mAxiWriteMaster.awburst,
         M00_AXI_AWLOCK       => mAxiWriteMaster.awlock(0),
         M00_AXI_AWCACHE      => mAxiWriteMaster.awcache,
         M00_AXI_AWPROT       => mAxiWriteMaster.awprot,
         M00_AXI_AWQOS        => mAxiWriteMaster.awqos,
         M00_AXI_AWVALID      => mAxiWriteMaster.awvalid,
         M00_AXI_AWREADY      => mAxiWriteSlave.awready,
         M00_AXI_WDATA        => mAxiWriteMaster.wdata(511 downto 0),
         M00_AXI_WSTRB        => mAxiWriteMaster.wstrb(63 downto 0),
         M00_AXI_WLAST        => mAxiWriteMaster.wlast,
         M00_AXI_WVALID       => mAxiWriteMaster.wvalid,
         M00_AXI_WREADY       => mAxiWriteSlave.wready,
         M00_AXI_BID          => mAxiWriteSlave.bid(3 downto 0),
         M00_AXI_BRESP        => mAxiWriteSlave.bresp,
         M00_AXI_BVALID       => mAxiWriteSlave.bvalid,
         M00_AXI_BREADY       => mAxiWriteMaster.bready,
         M00_AXI_ARID         => mAxiReadMaster.arid(3 downto 0),
         M00_AXI_ARADDR       => mAxiReadMaster.araddr(31 downto 0),
         M00_AXI_ARLEN        => mAxiReadMaster.arlen,
         M00_AXI_ARSIZE       => mAxiReadMaster.arsize,
         M00_AXI_ARBURST      => mAxiReadMaster.arburst,
         M00_AXI_ARLOCK       => mAxiReadMaster.arlock(0),
         M00_AXI_ARCACHE      => mAxiReadMaster.arcache,
         M00_AXI_ARPROT       => mAxiReadMaster.arprot,
         M00_AXI_ARQOS        => mAxiReadMaster.arqos,
         M00_AXI_ARVALID      => mAxiReadMaster.arvalid,
         M00_AXI_ARREADY      => mAxiReadSlave.arready,
         M00_AXI_RID          => mAxiReadSlave.rid(3 downto 0),
         M00_AXI_RDATA        => mAxiReadSlave.rdata(511 downto 0),
         M00_AXI_RRESP        => mAxiReadSlave.rresp,
         M00_AXI_RLAST        => mAxiReadSlave.rlast,
         M00_AXI_RVALID       => mAxiReadSlave.rvalid,
         M00_AXI_RREADY       => mAxiReadMaster.rready);

end mapping;
