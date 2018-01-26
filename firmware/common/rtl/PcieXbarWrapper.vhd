-------------------------------------------------------------------------------
-- File       : PcieXbarWrapper.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-14
-- Last update: 2018-01-24
-------------------------------------------------------------------------------
-- Description: AXI DMA Crossbar
-------------------------------------------------------------------------------
-- This file is part of 'AxiPcieCore'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'AxiPcieCore', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;

entity PcieXbarWrapper is
   port (
      -- Slaves
      sAxiClk          : in  sl; -- 200MHz
      sAxiRst          : in  sl;
      sAxiWriteMasters : in  AxiWriteMasterArray(4 downto 0);
      sAxiWriteSlaves  : out AxiWriteSlaveArray (4 downto 0);
      sAxiReadMasters  : in  AxiReadMasterArray (4 downto 0);
      sAxiReadSlaves   : out AxiReadSlaveArray  (4 downto 0);
      -- Master
      mAxiClk          : in  sl; -- 250MHz
      mAxiRst          : in  sl;
      mAxiWriteMaster  : out AxiWriteMasterType;
      mAxiWriteSlave   : in  AxiWriteSlaveType;
      mAxiReadMaster   : out AxiReadMasterType;
      mAxiReadSlave    : in  AxiReadSlaveType);
end PcieXbarWrapper;

architecture mapping of PcieXbarWrapper is

  component PcieXbar
    PORT (
      INTERCONNECT_ACLK : IN STD_LOGIC;
      INTERCONNECT_ARESETN : IN STD_LOGIC;
      S00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S00_AXI_ACLK : IN STD_LOGIC;
      S00_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S00_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S00_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_AWLOCK : IN STD_LOGIC;
      S00_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_AWVALID : IN STD_LOGIC;
      S00_AXI_AWREADY : OUT STD_LOGIC;
      S00_AXI_WDATA : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      S00_AXI_WSTRB : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      S00_AXI_WLAST : IN STD_LOGIC;
      S00_AXI_WVALID : IN STD_LOGIC;
      S00_AXI_WREADY : OUT STD_LOGIC;
      S00_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_BVALID : OUT STD_LOGIC;
      S00_AXI_BREADY : IN STD_LOGIC;
      S00_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S00_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S00_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_ARLOCK : IN STD_LOGIC;
      S00_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S00_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S00_AXI_ARVALID : IN STD_LOGIC;
      S00_AXI_ARREADY : OUT STD_LOGIC;
      S00_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S00_AXI_RDATA : OUT STD_LOGIC_VECTOR(127 DOWNTO 0);
      S00_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S00_AXI_RLAST : OUT STD_LOGIC;
      S00_AXI_RVALID : OUT STD_LOGIC;
      S00_AXI_RREADY : IN STD_LOGIC;
      S01_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S01_AXI_ACLK : IN STD_LOGIC;
      S01_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S01_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S01_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_AWLOCK : IN STD_LOGIC;
      S01_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_AWVALID : IN STD_LOGIC;
      S01_AXI_AWREADY : OUT STD_LOGIC;
      S01_AXI_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      S01_AXI_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S01_AXI_WLAST : IN STD_LOGIC;
      S01_AXI_WVALID : IN STD_LOGIC;
      S01_AXI_WREADY : OUT STD_LOGIC;
      S01_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_BVALID : OUT STD_LOGIC;
      S01_AXI_BREADY : IN STD_LOGIC;
      S01_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S01_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S01_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_ARLOCK : IN STD_LOGIC;
      S01_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S01_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S01_AXI_ARVALID : IN STD_LOGIC;
      S01_AXI_ARREADY : OUT STD_LOGIC;
      S01_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S01_AXI_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      S01_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S01_AXI_RLAST : OUT STD_LOGIC;
      S01_AXI_RVALID : OUT STD_LOGIC;
      S01_AXI_RREADY : IN STD_LOGIC;
      S02_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S02_AXI_ACLK : IN STD_LOGIC;
      S02_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S02_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S02_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_AWLOCK : IN STD_LOGIC;
      S02_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_AWVALID : IN STD_LOGIC;
      S02_AXI_AWREADY : OUT STD_LOGIC;
      S02_AXI_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      S02_AXI_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S02_AXI_WLAST : IN STD_LOGIC;
      S02_AXI_WVALID : IN STD_LOGIC;
      S02_AXI_WREADY : OUT STD_LOGIC;
      S02_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_BVALID : OUT STD_LOGIC;
      S02_AXI_BREADY : IN STD_LOGIC;
      S02_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S02_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S02_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_ARLOCK : IN STD_LOGIC;
      S02_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S02_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S02_AXI_ARVALID : IN STD_LOGIC;
      S02_AXI_ARREADY : OUT STD_LOGIC;
      S02_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S02_AXI_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      S02_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S02_AXI_RLAST : OUT STD_LOGIC;
      S02_AXI_RVALID : OUT STD_LOGIC;
      S02_AXI_RREADY : IN STD_LOGIC;
      S03_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S03_AXI_ACLK : IN STD_LOGIC;
      S03_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S03_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S03_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_AWLOCK : IN STD_LOGIC;
      S03_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_AWVALID : IN STD_LOGIC;
      S03_AXI_AWREADY : OUT STD_LOGIC;
      S03_AXI_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      S03_AXI_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S03_AXI_WLAST : IN STD_LOGIC;
      S03_AXI_WVALID : IN STD_LOGIC;
      S03_AXI_WREADY : OUT STD_LOGIC;
      S03_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_BVALID : OUT STD_LOGIC;
      S03_AXI_BREADY : IN STD_LOGIC;
      S03_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S03_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S03_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_ARLOCK : IN STD_LOGIC;
      S03_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S03_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S03_AXI_ARVALID : IN STD_LOGIC;
      S03_AXI_ARREADY : OUT STD_LOGIC;
      S03_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S03_AXI_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      S03_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S03_AXI_RLAST : OUT STD_LOGIC;
      S03_AXI_RVALID : OUT STD_LOGIC;
      S03_AXI_RREADY : IN STD_LOGIC;
      S04_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      S04_AXI_ACLK : IN STD_LOGIC;
      S04_AXI_AWID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_AWADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S04_AXI_AWLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S04_AXI_AWSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_AWBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_AWLOCK : IN STD_LOGIC;
      S04_AXI_AWCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_AWPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_AWQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_AWVALID : IN STD_LOGIC;
      S04_AXI_AWREADY : OUT STD_LOGIC;
      S04_AXI_WDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      S04_AXI_WSTRB : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      S04_AXI_WLAST : IN STD_LOGIC;
      S04_AXI_WVALID : IN STD_LOGIC;
      S04_AXI_WREADY : OUT STD_LOGIC;
      S04_AXI_BID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_BRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_BVALID : OUT STD_LOGIC;
      S04_AXI_BREADY : IN STD_LOGIC;
      S04_AXI_ARID : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_ARADDR : IN STD_LOGIC_VECTOR(37 DOWNTO 0);
      S04_AXI_ARLEN : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      S04_AXI_ARSIZE : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_ARBURST : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_ARLOCK : IN STD_LOGIC;
      S04_AXI_ARCACHE : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_ARPROT : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      S04_AXI_ARQOS : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      S04_AXI_ARVALID : IN STD_LOGIC;
      S04_AXI_ARREADY : OUT STD_LOGIC;
      S04_AXI_RID : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      S04_AXI_RDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      S04_AXI_RRESP : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      S04_AXI_RLAST : OUT STD_LOGIC;
      S04_AXI_RVALID : OUT STD_LOGIC;
      S04_AXI_RREADY : IN STD_LOGIC;
      M00_AXI_ARESET_OUT_N : OUT STD_LOGIC;
      M00_AXI_ACLK : IN STD_LOGIC;
      M00_AXI_AWID : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWADDR : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      M00_AXI_AWLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M00_AXI_AWSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_AWBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_AWLOCK : OUT STD_LOGIC;
      M00_AXI_AWCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_AWQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_AWVALID : OUT STD_LOGIC;
      M00_AXI_AWREADY : IN STD_LOGIC;
      M00_AXI_WDATA : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
      M00_AXI_WSTRB : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      M00_AXI_WLAST : OUT STD_LOGIC;
      M00_AXI_WVALID : OUT STD_LOGIC;
      M00_AXI_WREADY : IN STD_LOGIC;
      M00_AXI_BID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_BRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_BVALID : IN STD_LOGIC;
      M00_AXI_BREADY : OUT STD_LOGIC;
      M00_AXI_ARID : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARADDR : OUT STD_LOGIC_VECTOR(37 DOWNTO 0);
      M00_AXI_ARLEN : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      M00_AXI_ARSIZE : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_ARBURST : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_ARLOCK : OUT STD_LOGIC;
      M00_AXI_ARCACHE : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARPROT : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      M00_AXI_ARQOS : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_ARVALID : OUT STD_LOGIC;
      M00_AXI_ARREADY : IN STD_LOGIC;
      M00_AXI_RID : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      M00_AXI_RDATA : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
      M00_AXI_RRESP : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
      M00_AXI_RLAST : IN STD_LOGIC;
      M00_AXI_RVALID : IN STD_LOGIC;
      M00_AXI_RREADY : OUT STD_LOGIC
      );
  END COMPONENT;

  signal axiRstL : sl;

  signal axiWriteMasters : AxiWriteMasterArray(8 downto 1);
  signal axiWriteSlaves  : AxiWriteSlaveArray (8 downto 1);
  signal axiReadMasters  : AxiReadMasterArray (8 downto 1);
  signal axiReadSlaves   : AxiReadSlaveArray  (8 downto 1);

begin

  axiRstL <= not(axiRst);

   -------------------
   -- AXI PCIe IP Core
   -------------------
   U_AxiCrossbar : PcieXbar
      port map (
         INTERCONNECT_ACLK    => maxiClk,
         INTERCONNECT_ARESETN => maxiRstL,
         -- SLAVE[0] 
         S00_AXI_ARESET_OUT_N => open,
         S00_AXI_ACLK         => sAxiClk,
         S00_AXI_AWID(0)      => '0',
         S00_AXI_AWADDR       => sAxiWriteMasters(0).awaddr(37 downto 0),
         S00_AXI_AWLEN        => sAxiWriteMasters(0).awlen,
         S00_AXI_AWSIZE       => sAxiWriteMasters(0).awsize,
         S00_AXI_AWBURST      => sAxiWriteMasters(0).awburst,
         S00_AXI_AWLOCK       => sAxiWriteMasters(0).awlock(0),
         S00_AXI_AWCACHE      => sAxiWriteMasters(0).awcache,
         S00_AXI_AWPROT       => sAxiWriteMasters(0).awprot,
         S00_AXI_AWQOS        => sAxiWriteMasters(0).awqos,
         S00_AXI_AWVALID      => sAxiWriteMasters(0).awvalid,
         S00_AXI_AWREADY      => sAxiWriteSlaves(0).awready,
         S00_AXI_WDATA        => sAxiWriteMasters(0).wdata(127 downto 0),
         S00_AXI_WSTRB        => sAxiWriteMasters(0).wstrb(15 downto 0),
         S00_AXI_WLAST        => sAxiWriteMasters(0).wlast,
         S00_AXI_WVALID       => sAxiWriteMasters(0).wvalid,
         S00_AXI_WREADY       => sAxiWriteSlaves(0).wready,
         S00_AXI_BID          => sAxiWriteSlaves(0).bid(0 downto 0),
         S00_AXI_BRESP        => sAxiWriteSlaves(0).bresp,
         S00_AXI_BVALID       => sAxiWriteSlaves(0).bvalid,
         S00_AXI_BREADY       => sAxiWriteMasters(0).bready,
         S00_AXI_ARID(0)      => '0',
         S00_AXI_ARADDR       => sAxiReadMasters(0).araddr(37 downto 0),
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
         S00_AXI_RDATA        => sAxiReadSlaves(0).rdata(127 downto 0),
         S00_AXI_RRESP        => sAxiReadSlaves(0).rresp,
         S00_AXI_RLAST        => sAxiReadSlaves(0).rlast,
         S00_AXI_RVALID       => sAxiReadSlaves(0).rvalid,
         S00_AXI_RREADY       => sAxiReadMasters(0).rready,
         -- SLAVE[1]
         S01_AXI_ARESET_OUT_N => open,
         S01_AXI_ACLK         => sAxiClk,
         S01_AXI_AWID(0)      => '0',
         S01_AXI_AWADDR       => axiWriteMasters(1).awaddr(37 downto 0),
         S01_AXI_AWLEN        => axiWriteMasters(1).awlen,
         S01_AXI_AWSIZE       => axiWriteMasters(1).awsize,
         S01_AXI_AWBURST      => axiWriteMasters(1).awburst,
         S01_AXI_AWLOCK       => axiWriteMasters(1).awlock(0),
         S01_AXI_AWCACHE      => "0000",  -- revert back the cache
         S01_AXI_AWPROT       => axiWriteMasters(1).awprot,
         S01_AXI_AWQOS        => axiWriteMasters(1).awqos,
         S01_AXI_AWVALID      => axiWriteMasters(1).awvalid,
         S01_AXI_AWREADY      => axiWriteSlaves(1).awready,
         S01_AXI_WDATA        => axiWriteMasters(1).wdata(255 downto 0),
         S01_AXI_WSTRB        => axiWriteMasters(1).wstrb(31 downto 0),
         S01_AXI_WLAST        => axiWriteMasters(1).wlast,
         S01_AXI_WVALID       => axiWriteMasters(1).wvalid,
         S01_AXI_WREADY       => axiWriteSlaves(1).wready,
         S01_AXI_BID          => axiWriteSlaves(1).bid(0 downto 0),
         S01_AXI_BRESP        => axiWriteSlaves(1).bresp,
         S01_AXI_BVALID       => axiWriteSlaves(1).bvalid,
         S01_AXI_BREADY       => axiWriteMasters(1).bready,
         S01_AXI_ARID(0)      => '0',
         S01_AXI_ARADDR       => axiReadMasters(1).araddr(37 downto 0),
         S01_AXI_ARLEN        => axiReadMasters(1).arlen,
         S01_AXI_ARSIZE       => axiReadMasters(1).arsize,
         S01_AXI_ARBURST      => axiReadMasters(1).arburst,
         S01_AXI_ARLOCK       => axiReadMasters(1).arlock(0),
         S01_AXI_ARCACHE      => axiReadMasters(1).arcache,
         S01_AXI_ARPROT       => axiReadMasters(1).arprot,
         S01_AXI_ARQOS        => axiReadMasters(1).arqos,
         S01_AXI_ARVALID      => axiReadMasters(1).arvalid,
         S01_AXI_ARREADY      => axiReadSlaves(1).arready,
         S01_AXI_RID          => axiReadSlaves(1).rid(0 downto 0),
         S01_AXI_RDATA        => axiReadSlaves(1).rdata(255 downto 0),
         S01_AXI_RRESP        => axiReadSlaves(1).rresp,
         S01_AXI_RLAST        => axiReadSlaves(1).rlast,
         S01_AXI_RVALID       => axiReadSlaves(1).rvalid,
         S01_AXI_RREADY       => axiReadMasters(1).rready,
         -- SLAVE[2]
         S02_AXI_ARESET_OUT_N => open,
         S02_AXI_ACLK         => sAxiClk,
         S02_AXI_AWID(0)      => '0',
         S02_AXI_AWADDR       => axiWriteMasters(2).awaddr(37 downto 0),
         S02_AXI_AWLEN        => axiWriteMasters(2).awlen,
         S02_AXI_AWSIZE       => axiWriteMasters(2).awsize,
         S02_AXI_AWBURST      => axiWriteMasters(2).awburst,
         S02_AXI_AWLOCK       => axiWriteMasters(2).awlock(0),
         S02_AXI_AWCACHE      => "0000",  -- revert back the cache
         S02_AXI_AWPROT       => axiWriteMasters(2).awprot,
         S02_AXI_AWQOS        => axiWriteMasters(2).awqos,
         S02_AXI_AWVALID      => axiWriteMasters(2).awvalid,
         S02_AXI_AWREADY      => axiWriteSlaves(2).awready,
         S02_AXI_WDATA        => axiWriteMasters(2).wdata(255 downto 0),
         S02_AXI_WSTRB        => axiWriteMasters(2).wstrb(31 downto 0),
         S02_AXI_WLAST        => axiWriteMasters(2).wlast,
         S02_AXI_WVALID       => axiWriteMasters(2).wvalid,
         S02_AXI_WREADY       => axiWriteSlaves(2).wready,
         S02_AXI_BID          => axiWriteSlaves(2).bid(0 downto 0),
         S02_AXI_BRESP        => axiWriteSlaves(2).bresp,
         S02_AXI_BVALID       => axiWriteSlaves(2).bvalid,
         S02_AXI_BREADY       => axiWriteMasters(2).bready,
         S02_AXI_ARID(0)      => '0',
         S02_AXI_ARADDR       => axiReadMasters(2).araddr(37 downto 0),
         S02_AXI_ARLEN        => axiReadMasters(2).arlen,
         S02_AXI_ARSIZE       => axiReadMasters(2).arsize,
         S02_AXI_ARBURST      => axiReadMasters(2).arburst,
         S02_AXI_ARLOCK       => axiReadMasters(2).arlock(0),
         S02_AXI_ARCACHE      => axiReadMasters(2).arcache,
         S02_AXI_ARPROT       => axiReadMasters(2).arprot,
         S02_AXI_ARQOS        => axiReadMasters(2).arqos,
         S02_AXI_ARVALID      => axiReadMasters(2).arvalid,
         S02_AXI_ARREADY      => axiReadSlaves(2).arready,
         S02_AXI_RID          => axiReadSlaves(2).rid(0 downto 0),
         S02_AXI_RDATA        => axiReadSlaves(2).rdata(255 downto 0),
         S02_AXI_RRESP        => axiReadSlaves(2).rresp,
         S02_AXI_RLAST        => axiReadSlaves(2).rlast,
         S02_AXI_RVALID       => axiReadSlaves(2).rvalid,
         S02_AXI_RREADY       => axiReadMasters(2).rready,
         -- SLAVE[3]
         S03_AXI_ARESET_OUT_N => open,
         S03_AXI_ACLK         => sAxiClk,
         S03_AXI_AWID(0)      => '0',
         S03_AXI_AWADDR       => axiWriteMasters(3).awaddr(37 downto 0),
         S03_AXI_AWLEN        => axiWriteMasters(3).awlen,
         S03_AXI_AWSIZE       => axiWriteMasters(3).awsize,
         S03_AXI_AWBURST      => axiWriteMasters(3).awburst,
         S03_AXI_AWLOCK       => axiWriteMasters(3).awlock(0),
         S03_AXI_AWCACHE      => "0000",  -- revert back the cache
         S03_AXI_AWPROT       => axiWriteMasters(3).awprot,
         S03_AXI_AWQOS        => axiWriteMasters(3).awqos,
         S03_AXI_AWVALID      => axiWriteMasters(3).awvalid,
         S03_AXI_AWREADY      => axiWriteSlaves(3).awready,
         S03_AXI_WDATA        => axiWriteMasters(3).wdata(255 downto 0),
         S03_AXI_WSTRB        => axiWriteMasters(3).wstrb(31 downto 0),
         S03_AXI_WLAST        => axiWriteMasters(3).wlast,
         S03_AXI_WVALID       => axiWriteMasters(3).wvalid,
         S03_AXI_WREADY       => axiWriteSlaves(3).wready,
         S03_AXI_BID          => axiWriteSlaves(3).bid(0 downto 0),
         S03_AXI_BRESP        => axiWriteSlaves(3).bresp,
         S03_AXI_BVALID       => axiWriteSlaves(3).bvalid,
         S03_AXI_BREADY       => axiWriteMasters(3).bready,
         S03_AXI_ARID(0)      => '0',
         S03_AXI_ARADDR       => axiReadMasters(3).araddr(37 downto 0),
         S03_AXI_ARLEN        => axiReadMasters(3).arlen,
         S03_AXI_ARSIZE       => axiReadMasters(3).arsize,
         S03_AXI_ARBURST      => axiReadMasters(3).arburst,
         S03_AXI_ARLOCK       => axiReadMasters(3).arlock(0),
         S03_AXI_ARCACHE      => axiReadMasters(3).arcache,
         S03_AXI_ARPROT       => axiReadMasters(3).arprot,
         S03_AXI_ARQOS        => axiReadMasters(3).arqos,
         S03_AXI_ARVALID      => axiReadMasters(3).arvalid,
         S03_AXI_ARREADY      => axiReadSlaves(3).arready,
         S03_AXI_RID          => axiReadSlaves(3).rid(0 downto 0),
         S03_AXI_RDATA        => axiReadSlaves(3).rdata(255 downto 0),
         S03_AXI_RRESP        => axiReadSlaves(3).rresp,
         S03_AXI_RLAST        => axiReadSlaves(3).rlast,
         S03_AXI_RVALID       => axiReadSlaves(3).rvalid,
         S03_AXI_RREADY       => axiReadMasters(3).rready,
         -- SLAVE[4]
         S04_AXI_ARESET_OUT_N => open,
         S04_AXI_ACLK         => sAxiClk,
         S04_AXI_AWID(0)      => '0',
         S04_AXI_AWADDR       => axiWriteMasters(4).awaddr(37 downto 0),
         S04_AXI_AWLEN        => axiWriteMasters(4).awlen,
         S04_AXI_AWSIZE       => axiWriteMasters(4).awsize,
         S04_AXI_AWBURST      => axiWriteMasters(4).awburst,
         S04_AXI_AWLOCK       => axiWriteMasters(4).awlock(0),
         S04_AXI_AWCACHE      => "0000",  -- revert back the cache
         S04_AXI_AWPROT       => axiWriteMasters(4).awprot,
         S04_AXI_AWQOS        => axiWriteMasters(4).awqos,
         S04_AXI_AWVALID      => axiWriteMasters(4).awvalid,
         S04_AXI_AWREADY      => axiWriteSlaves(4).awready,
         S04_AXI_WDATA        => axiWriteMasters(4).wdata(255 downto 0),
         S04_AXI_WSTRB        => axiWriteMasters(4).wstrb(31 downto 0),
         S04_AXI_WLAST        => axiWriteMasters(4).wlast,
         S04_AXI_WVALID       => axiWriteMasters(4).wvalid,
         S04_AXI_WREADY       => axiWriteSlaves(4).wready,
         S04_AXI_BID          => axiWriteSlaves(4).bid(0 downto 0),
         S04_AXI_BRESP        => axiWriteSlaves(4).bresp,
         S04_AXI_BVALID       => axiWriteSlaves(4).bvalid,
         S04_AXI_BREADY       => axiWriteMasters(4).bready,
         S04_AXI_ARID(0)      => '0',
         S04_AXI_ARADDR       => axiReadMasters(4).araddr(37 downto 0),
         S04_AXI_ARLEN        => axiReadMasters(4).arlen,
         S04_AXI_ARSIZE       => axiReadMasters(4).arsize,
         S04_AXI_ARBURST      => axiReadMasters(4).arburst,
         S04_AXI_ARLOCK       => axiReadMasters(4).arlock(0),
         S04_AXI_ARCACHE      => axiReadMasters(4).arcache,
         S04_AXI_ARPROT       => axiReadMasters(4).arprot,
         S04_AXI_ARQOS        => axiReadMasters(4).arqos,
         S04_AXI_ARVALID      => axiReadMasters(4).arvalid,
         S04_AXI_ARREADY      => axiReadSlaves(4).arready,
         S04_AXI_RID          => axiReadSlaves(4).rid(0 downto 0),
         S04_AXI_RDATA        => axiReadSlaves(4).rdata(255 downto 0),
         S04_AXI_RRESP        => axiReadSlaves(4).rresp,
         S04_AXI_RLAST        => axiReadSlaves(4).rlast,
         S04_AXI_RVALID       => axiReadSlaves(4).rvalid,
         S04_AXI_RREADY       => axiReadMasters(4).rready,
         -- SLAVE[5]
         S05_AXI_ARESET_OUT_N => open,
         S05_AXI_ACLK         => sAxiClk,
         S05_AXI_AWID(0)      => '0',
         S05_AXI_AWADDR       => axiWriteMasters(5).awaddr(37 downto 0),
         S05_AXI_AWLEN        => axiWriteMasters(5).awlen,
         S05_AXI_AWSIZE       => axiWriteMasters(5).awsize,
         S05_AXI_AWBURST      => axiWriteMasters(5).awburst,
         S05_AXI_AWLOCK       => axiWriteMasters(5).awlock(0),
         S05_AXI_AWCACHE      => "0000",  -- revert back the cache
         S05_AXI_AWPROT       => axiWriteMasters(5).awprot,
         S05_AXI_AWQOS        => axiWriteMasters(5).awqos,
         S05_AXI_AWVALID      => axiWriteMasters(5).awvalid,
         S05_AXI_AWREADY      => axiWriteSlaves(5).awready,
         S05_AXI_WDATA        => axiWriteMasters(5).wdata(255 downto 0),
         S05_AXI_WSTRB        => axiWriteMasters(5).wstrb(31 downto 0),
         S05_AXI_WLAST        => axiWriteMasters(5).wlast,
         S05_AXI_WVALID       => axiWriteMasters(5).wvalid,
         S05_AXI_WREADY       => axiWriteSlaves(5).wready,
         S05_AXI_BID          => axiWriteSlaves(5).bid(0 downto 0),
         S05_AXI_BRESP        => axiWriteSlaves(5).bresp,
         S05_AXI_BVALID       => axiWriteSlaves(5).bvalid,
         S05_AXI_BREADY       => axiWriteMasters(5).bready,
         S05_AXI_ARID(0)      => '0',
         S05_AXI_ARADDR       => axiReadMasters(5).araddr(37 downto 0),
         S05_AXI_ARLEN        => axiReadMasters(5).arlen,
         S05_AXI_ARSIZE       => axiReadMasters(5).arsize,
         S05_AXI_ARBURST      => axiReadMasters(5).arburst,
         S05_AXI_ARLOCK       => axiReadMasters(5).arlock(0),
         S05_AXI_ARCACHE      => axiReadMasters(5).arcache,
         S05_AXI_ARPROT       => axiReadMasters(5).arprot,
         S05_AXI_ARQOS        => axiReadMasters(5).arqos,
         S05_AXI_ARVALID      => axiReadMasters(5).arvalid,
         S05_AXI_ARREADY      => axiReadSlaves(5).arready,
         S05_AXI_RID          => axiReadSlaves(5).rid(0 downto 0),
         S05_AXI_RDATA        => axiReadSlaves(5).rdata(255 downto 0),
         S05_AXI_RRESP        => axiReadSlaves(5).rresp,
         S05_AXI_RLAST        => axiReadSlaves(5).rlast,
         S05_AXI_RVALID       => axiReadSlaves(5).rvalid,
         S05_AXI_RREADY       => axiReadMasters(5).rready,
         -- SLAVE[6]
         S06_AXI_ARESET_OUT_N => open,
         S06_AXI_ACLK         => sAxiClk,
         S06_AXI_AWID(0)      => '0',
         S06_AXI_AWADDR       => axiWriteMasters(6).awaddr(37 downto 0),
         S06_AXI_AWLEN        => axiWriteMasters(6).awlen,
         S06_AXI_AWSIZE       => axiWriteMasters(6).awsize,
         S06_AXI_AWBURST      => axiWriteMasters(6).awburst,
         S06_AXI_AWLOCK       => axiWriteMasters(6).awlock(0),
         S06_AXI_AWCACHE      => "0000",  -- revert back the cache
         S06_AXI_AWPROT       => axiWriteMasters(6).awprot,
         S06_AXI_AWQOS        => axiWriteMasters(6).awqos,
         S06_AXI_AWVALID      => axiWriteMasters(6).awvalid,
         S06_AXI_AWREADY      => axiWriteSlaves(6).awready,
         S06_AXI_WDATA        => axiWriteMasters(6).wdata(255 downto 0),
         S06_AXI_WSTRB        => axiWriteMasters(6).wstrb(31 downto 0),
         S06_AXI_WLAST        => axiWriteMasters(6).wlast,
         S06_AXI_WVALID       => axiWriteMasters(6).wvalid,
         S06_AXI_WREADY       => axiWriteSlaves(6).wready,
         S06_AXI_BID          => axiWriteSlaves(6).bid(0 downto 0),
         S06_AXI_BRESP        => axiWriteSlaves(6).bresp,
         S06_AXI_BVALID       => axiWriteSlaves(6).bvalid,
         S06_AXI_BREADY       => axiWriteMasters(6).bready,
         S06_AXI_ARID(0)      => '0',
         S06_AXI_ARADDR       => axiReadMasters(6).araddr(37 downto 0),
         S06_AXI_ARLEN        => axiReadMasters(6).arlen,
         S06_AXI_ARSIZE       => axiReadMasters(6).arsize,
         S06_AXI_ARBURST      => axiReadMasters(6).arburst,
         S06_AXI_ARLOCK       => axiReadMasters(6).arlock(0),
         S06_AXI_ARCACHE      => axiReadMasters(6).arcache,
         S06_AXI_ARPROT       => axiReadMasters(6).arprot,
         S06_AXI_ARQOS        => axiReadMasters(6).arqos,
         S06_AXI_ARVALID      => axiReadMasters(6).arvalid,
         S06_AXI_ARREADY      => axiReadSlaves(6).arready,
         S06_AXI_RID          => axiReadSlaves(6).rid(0 downto 0),
         S06_AXI_RDATA        => axiReadSlaves(6).rdata(255 downto 0),
         S06_AXI_RRESP        => axiReadSlaves(6).rresp,
         S06_AXI_RLAST        => axiReadSlaves(6).rlast,
         S06_AXI_RVALID       => axiReadSlaves(6).rvalid,
         S06_AXI_RREADY       => axiReadMasters(6).rready,
         -- SLAVE[7]
         S07_AXI_ARESET_OUT_N => open,
         S07_AXI_ACLK         => sAxiClk,
         S07_AXI_AWID(0)      => '0',
         S07_AXI_AWADDR       => axiWriteMasters(7).awaddr(37 downto 0),
         S07_AXI_AWLEN        => axiWriteMasters(7).awlen,
         S07_AXI_AWSIZE       => axiWriteMasters(7).awsize,
         S07_AXI_AWBURST      => axiWriteMasters(7).awburst,
         S07_AXI_AWLOCK       => axiWriteMasters(7).awlock(0),
         S07_AXI_AWCACHE      => "0000",  -- revert back the cache
         S07_AXI_AWPROT       => axiWriteMasters(7).awprot,
         S07_AXI_AWQOS        => axiWriteMasters(7).awqos,
         S07_AXI_AWVALID      => axiWriteMasters(7).awvalid,
         S07_AXI_AWREADY      => axiWriteSlaves(7).awready,
         S07_AXI_WDATA        => axiWriteMasters(7).wdata(255 downto 0),
         S07_AXI_WSTRB        => axiWriteMasters(7).wstrb(31 downto 0),
         S07_AXI_WLAST        => axiWriteMasters(7).wlast,
         S07_AXI_WVALID       => axiWriteMasters(7).wvalid,
         S07_AXI_WREADY       => axiWriteSlaves(7).wready,
         S07_AXI_BID          => axiWriteSlaves(7).bid(0 downto 0),
         S07_AXI_BRESP        => axiWriteSlaves(7).bresp,
         S07_AXI_BVALID       => axiWriteSlaves(7).bvalid,
         S07_AXI_BREADY       => axiWriteMasters(7).bready,
         S07_AXI_ARID(0)      => '0',
         S07_AXI_ARADDR       => axiReadMasters(7).araddr(37 downto 0),
         S07_AXI_ARLEN        => axiReadMasters(7).arlen,
         S07_AXI_ARSIZE       => axiReadMasters(7).arsize,
         S07_AXI_ARBURST      => axiReadMasters(7).arburst,
         S07_AXI_ARLOCK       => axiReadMasters(7).arlock(0),
         S07_AXI_ARCACHE      => axiReadMasters(7).arcache,
         S07_AXI_ARPROT       => axiReadMasters(7).arprot,
         S07_AXI_ARQOS        => axiReadMasters(7).arqos,
         S07_AXI_ARVALID      => axiReadMasters(7).arvalid,
         S07_AXI_ARREADY      => axiReadSlaves(7).arready,
         S07_AXI_RID          => axiReadSlaves(7).rid(0 downto 0),
         S07_AXI_RDATA        => axiReadSlaves(7).rdata(255 downto 0),
         S07_AXI_RRESP        => axiReadSlaves(7).rresp,
         S07_AXI_RLAST        => axiReadSlaves(7).rlast,
         S07_AXI_RVALID       => axiReadSlaves(7).rvalid,
         S07_AXI_RREADY       => axiReadMasters(7).rready,
         -- SLAVE[8]
         S08_AXI_ARESET_OUT_N => open,
         S08_AXI_ACLK         => sAxiClk,
         S08_AXI_AWID(0)      => '0',
         S08_AXI_AWADDR       => axiWriteMasters(8).awaddr(37 downto 0),
         S08_AXI_AWLEN        => axiWriteMasters(8).awlen,
         S08_AXI_AWSIZE       => axiWriteMasters(8).awsize,
         S08_AXI_AWBURST      => axiWriteMasters(8).awburst,
         S08_AXI_AWLOCK       => axiWriteMasters(8).awlock(0),
         S08_AXI_AWCACHE      => "0000",  -- revert back the cache
         S08_AXI_AWPROT       => axiWriteMasters(8).awprot,
         S08_AXI_AWQOS        => axiWriteMasters(8).awqos,
         S08_AXI_AWVALID      => axiWriteMasters(8).awvalid,
         S08_AXI_AWREADY      => axiWriteSlaves(8).awready,
         S08_AXI_WDATA        => axiWriteMasters(8).wdata(255 downto 0),
         S08_AXI_WSTRB        => axiWriteMasters(8).wstrb(31 downto 0),
         S08_AXI_WLAST        => axiWriteMasters(8).wlast,
         S08_AXI_WVALID       => axiWriteMasters(8).wvalid,
         S08_AXI_WREADY       => axiWriteSlaves(8).wready,
         S08_AXI_BID          => axiWriteSlaves(8).bid(0 downto 0),
         S08_AXI_BRESP        => axiWriteSlaves(8).bresp,
         S08_AXI_BVALID       => axiWriteSlaves(8).bvalid,
         S08_AXI_BREADY       => axiWriteMasters(8).bready,
         S08_AXI_ARID(0)      => '0',
         S08_AXI_ARADDR       => axiReadMasters(8).araddr(37 downto 0),
         S08_AXI_ARLEN        => axiReadMasters(8).arlen,
         S08_AXI_ARSIZE       => axiReadMasters(8).arsize,
         S08_AXI_ARBURST      => axiReadMasters(8).arburst,
         S08_AXI_ARLOCK       => axiReadMasters(8).arlock(0),
         S08_AXI_ARCACHE      => axiReadMasters(8).arcache,
         S08_AXI_ARPROT       => axiReadMasters(8).arprot,
         S08_AXI_ARQOS        => axiReadMasters(8).arqos,
         S08_AXI_ARVALID      => axiReadMasters(8).arvalid,
         S08_AXI_ARREADY      => axiReadSlaves(8).arready,
         S08_AXI_RID          => axiReadSlaves(8).rid(0 downto 0),
         S08_AXI_RDATA        => axiReadSlaves(8).rdata(255 downto 0),
         S08_AXI_RRESP        => axiReadSlaves(8).rresp,
         S08_AXI_RLAST        => axiReadSlaves(8).rlast,
         S08_AXI_RVALID       => axiReadSlaves(8).rvalid,
         S08_AXI_RREADY       => axiReadMasters(8).rready,
         -- MASTER         
         M00_AXI_ARESET_OUT_N => open,
         M00_AXI_ACLK         => mAxiClk,
         M00_AXI_AWID         => mAxiWriteMaster.awid(3 downto 0),
         M00_AXI_AWADDR       => mAxiWriteMaster.awaddr(37 downto 0),
         M00_AXI_AWLEN        => mAxiWriteMaster.awlen,
         M00_AXI_AWSIZE       => mAxiWriteMaster.awsize,
         M00_AXI_AWBURST      => mAxiWriteMaster.awburst,
         M00_AXI_AWLOCK       => mAxiWriteMaster.awlock(0),
         M00_AXI_AWCACHE      => mAxiWriteMaster.awcache,
         M00_AXI_AWPROT       => mAxiWriteMaster.awprot,
         M00_AXI_AWQOS        => mAxiWriteMaster.awqos,
         M00_AXI_AWVALID      => mAxiWriteMaster.awvalid,
         M00_AXI_AWREADY      => mAxiWriteSlave.awready,
         M00_AXI_WDATA        => mAxiWriteMaster.wdata(255 downto 0),
         M00_AXI_WSTRB        => mAxiWriteMaster.wstrb(31 downto 0),
         M00_AXI_WLAST        => mAxiWriteMaster.wlast,
         M00_AXI_WVALID       => mAxiWriteMaster.wvalid,
         M00_AXI_WREADY       => mAxiWriteSlave.wready,
         M00_AXI_BID          => mAxiWriteSlave.bid(3 downto 0),
         M00_AXI_BRESP        => mAxiWriteSlave.bresp,
         M00_AXI_BVALID       => mAxiWriteSlave.bvalid,
         M00_AXI_BREADY       => mAxiWriteMaster.bready,
         M00_AXI_ARID         => mAxiReadMaster.arid(3 downto 0),
         M00_AXI_ARADDR       => mAxiReadMaster.araddr(37 downto 0),
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
         M00_AXI_RDATA        => mAxiReadSlave.rdata(255 downto 0),
         M00_AXI_RRESP        => mAxiReadSlave.rresp,
         M00_AXI_RLAST        => mAxiReadSlave.rlast,
         M00_AXI_RVALID       => mAxiReadSlave.rvalid,
         M00_AXI_RREADY       => mAxiReadMaster.rready);

end mapping;
