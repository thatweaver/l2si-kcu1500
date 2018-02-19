-------------------------------------------------------------------------------
-- File       : AxiPcieReg.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-02-12
-------------------------------------------------------------------------------
-- Description: AXI-Lite Crossbar and Register Access
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
use work.AxiLitePkg.all;
use work.AxiPciePkg.all;
use work.AxiMicronP30Pkg.all;

entity AxiPcieReg is
   generic (
      TPD_G            : time                   := 1 ns;
      MASTER_G         : boolean                := true;
      BUILD_INFO_G     : BuildInfoType;
      XIL_DEVICE_G     : string                 := "7SERIES";
      BOOT_PROM_G      : string                 := "BPI";
      DRIVER_TYPE_ID_G : slv(31 downto 0)       := x"00000000";
      EN_DEVICE_DNA_G  : boolean                := true;
      AXI_ERROR_RESP_G : slv(1 downto 0)        := AXI_RESP_OK_C );
   port (
      -- AXI4 Interfaces
      axiClk             : in  sl;
      axiRst             : in  sl;
      regReadMaster      : in  AxiReadMasterType;
      regReadSlave       : out AxiReadSlaveType;
      regWriteMaster     : in  AxiWriteMasterType;
      regWriteSlave      : out AxiWriteSlaveType;
      -- PHY AXI-Lite Interfaces [0x00030000:0x0003FFFF]
      phyReadMaster      : out AxiLiteReadMasterType;
      phyReadSlave       : in  AxiLiteReadSlaveType;
      phyWriteMaster     : out AxiLiteWriteMasterType;
      phyWriteSlave      : in  AxiLiteWriteSlaveType;
      -- Application AXI-Lite Interfaces [0x00800000:0x00FFFFFF]
      appClk             : in  sl;
      appRst             : in  sl;
      appReadMaster      : out AxiLiteReadMasterType;
      appReadSlave       : in  AxiLiteReadSlaveType;
      appWriteMaster     : out AxiLiteWriteMasterType;
      appWriteSlave      : in  AxiLiteWriteSlaveType;
      -- Application Force reset
      cardResetIn        : in  sl;
      cardResetOut       : out sl;
      -- BPI Boot Memory Ports 
      bpiAddr            : out slv(28 downto 0);
      bpiAdv             : out sl;
      bpiClk             : out sl;
      bpiRstL            : out sl;
      bpiCeL             : out sl;
      bpiOeL             : out sl;
      bpiWeL             : out sl;
      bpiTri             : out sl;
      bpiDin             : out slv(15 downto 0);
      bpiDout            : in  slv(15 downto 0) := x"FFFF";
      -- SPI Boot Memory Ports 
      spiCsL             : out slv(1 downto 0);
      spiSck             : out slv(1 downto 0);
      spiMosi            : out slv(1 downto 0);
      spiMiso            : in  slv(1 downto 0)  := "11");
end AxiPcieReg;

architecture mapping of AxiPcieReg is

   constant USE_SPI : boolean := MASTER_G and (BOOT_PROM_G = "SPI");
   constant USE_BPI : boolean := MASTER_G and (BOOT_PROM_G = "BPI");

   constant VERSION_INDEX_C : natural := 0;
   constant PHY_INDEX_C     : natural := 1;
   constant PROM_INDEX_C    : natural := 2;
   constant APP_INDEX_C     : natural := ite(USE_SPI, 4, ite(USE_BPI, 3, 2));

   constant NUM_AXI_MASTERS_C : natural := APP_INDEX_C+1;
   
   constant VERSION_ADDR_C : slv(31 downto 0) := x"00000000";
   constant PHY_ADDR_C     : slv(31 downto 0) := x"00010000";
   constant BPI_ADDR_C     : slv(31 downto 0) := x"00030000";
   constant SPI0_ADDR_C    : slv(31 downto 0) := x"00040000";
   constant SPI1_ADDR_C    : slv(31 downto 0) := x"00050000";
   constant APP_ADDR_C     : slv(31 downto 0) := x"00800000";

   function axilMasterConfig(constant n : integer) return AxiLiteCrossbarMasterConfigArray is
     variable ret : AxiLiteCrossbarMasterConfigArray(n-1 downto 0);
     variable i   : integer;
   begin
     ret(VERSION_INDEX_C).baseAddr     := VERSION_ADDR_C;
     ret(VERSION_INDEX_C).addrBits     := 16;
     ret(VERSION_INDEX_C).connectivity := x"FFFF";

     ret(PHY_INDEX_C).baseAddr     := PHY_ADDR_C;
     ret(PHY_INDEX_C).addrBits     := 16;
     ret(PHY_INDEX_C).connectivity := x"FFFF";

     if (USE_BPI) then
       ret(PROM_INDEX_C).baseAddr     := BPI_ADDR_C;
       ret(PROM_INDEX_C).addrBits     := 16;
       ret(PROM_INDEX_C).connectivity := x"FFFF";
     elsif (USE_SPI) then
       ret(PROM_INDEX_C).baseAddr     := SPI0_ADDR_C;
       ret(PROM_INDEX_C).addrBits     := 16;
       ret(PROM_INDEX_C).connectivity := x"FFFF";

       ret(PROM_INDEX_C+1).baseAddr     := SPI1_ADDR_C;
       ret(PROM_INDEX_C+1).addrBits     := 16;
       ret(PROM_INDEX_C+1).connectivity := x"FFFF";
     end if;

     ret(APP_INDEX_C).baseAddr     := APP_ADDR_C;
     ret(APP_INDEX_C).addrBits     := 23;
     ret(APP_INDEX_C).connectivity := x"FFFF";

     return ret;
   end function;
                                  
   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := axilMasterConfig(NUM_AXI_MASTERS_C);

   signal axilReadMaster  : AxiLiteReadMasterType;
   signal maskReadMaster  : AxiLiteReadMasterType;
   signal axilReadSlave   : AxiLiteReadSlaveType;
   signal axilWriteMaster : AxiLiteWriteMasterType;
   signal maskWriteMaster : AxiLiteWriteMasterType;
   signal axilWriteSlave  : AxiLiteWriteSlaveType;

   signal axilReadMasters  : AxiLiteReadMasterArray (NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (NUM_AXI_MASTERS_C-1 downto 0);

   signal userValues : Slv32Array(63 downto 0) := (others => x"00000000");
   signal bpiAddress : slv(30 downto 0);
   signal spiBusyIn  : slv(1 downto 0);
   signal spiBusyOut : slv(1 downto 0);
   signal cardRst    : sl;
   signal appReset   : sl;

   constant BOOT_PROM_C : slv(31 downto 0) := ite(MASTER_G,
                                                  ite(BOOT_PROM_G = "BPI", x"00000000",
                                                      ite(BOOT_PROM_G = "SPI", x"00000001", x"FFFFFFFF")),
                                                  x"FFFFFFFF");

begin

   ---------------------------------------------------------------------------------------------
   -- Driver Polls the userValues to determine the firmware's configurations and interrupt state
   ---------------------------------------------------------------------------------------------   
   process(appReset)
      variable i : natural;
   begin
      userValues(0) <= toSlv(0, 32);
      userValues(1) <= x"00000001";
      userValues(2) <= DRIVER_TYPE_ID_G;

      case XIL_DEVICE_G is
         when "ULTRASCALE" => userValues(3) <= x"00000000";
         when "7SERIES"    => userValues(3) <= x"00000001";
         when others       => userValues(3) <= x"FFFFFFFF";
      end case;

      userValues(4) <= toSlv(getTimeRatio(SYS_CLK_FREQ_C, 1.0), 32);

      userValues(5) <= BOOT_PROM_C;

      userValues(6)(0) <= appReset;

      for i in 63 downto 7 loop
         userValues(i) <= x"00000000";
      end loop;

   end process;

   -------------------------          
   -- AXI-to-AXI-Lite Bridge
   -------------------------          
   U_AxiToAxiLite : entity work.AxiToAxiLite
      generic map (
         TPD_G           => TPD_G,
         EN_SLAVE_RESP_G => false)
      port map (
         axiClk          => axiClk,
         axiClkRst       => axiRst,
         axiReadMaster   => regReadMaster,
         axiReadSlave    => regReadSlave,
         axiWriteMaster  => regWriteMaster,
         axiWriteSlave   => regWriteSlave,
         axilReadMaster  => axilReadMaster,
         axilReadSlave   => axilReadSlave,
         axilWriteMaster => axilWriteMaster,
         axilWriteSlave  => axilWriteSlave);

   ----------------------------------------
   -- Mask off upper address for 16 MB BAR0
   ----------------------------------------
   maskWriteMaster.awaddr  <= x"00" & axilWriteMaster.awaddr(23 downto 0);
   maskWriteMaster.awprot  <= axilWriteMaster.awprot;
   maskWriteMaster.awvalid <= axilWriteMaster.awvalid;
   maskWriteMaster.wdata   <= axilWriteMaster.wdata;
   maskWriteMaster.wstrb   <= axilWriteMaster.wstrb;
   maskWriteMaster.wvalid  <= axilWriteMaster.wvalid;
   maskWriteMaster.bready  <= axilWriteMaster.bready;
   maskReadMaster.araddr   <= x"00" & axilReadMaster.araddr(23 downto 0);
   maskReadMaster.arprot   <= axilReadMaster.arprot;
   maskReadMaster.arvalid  <= axilReadMaster.arvalid;
   maskReadMaster.rready   <= axilReadMaster.rready;

   --------------------
   -- AXI-Lite Crossbar
   --------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk              => axiClk,
         axiClkRst           => axiRst,
         sAxiWriteMasters(0) => maskWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => maskReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   --------------------------
   -- AXI-Lite Version Module
   --------------------------   
   U_Version : entity work.AxiVersion
      generic map (
         TPD_G            => TPD_G,
         BUILD_INFO_G     => BUILD_INFO_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         CLK_PERIOD_G     => (1.0/SYS_CLK_FREQ_C),
         EN_DEVICE_DNA_G  => ite(MASTER_G, EN_DEVICE_DNA_G, false),
         XIL_DEVICE_G     => XIL_DEVICE_G)
      port map (
         -- AXI-Lite Interface
         axiClk         => axiClk,
         axiRst         => axiRst,
         axiReadMaster  => axilReadMasters (VERSION_INDEX_C),
         axiReadSlave   => axilReadSlaves  (VERSION_INDEX_C),
         axiWriteMaster => axilWriteMasters(VERSION_INDEX_C),
         axiWriteSlave  => axilWriteSlaves (VERSION_INDEX_C),
         -- Optional: User Reset
         userReset      => cardResetOut,
         -- Optional: user values
         userValues     => userValues);

   -----------------------------         
   -- AXI-Lite Boot Flash Module
   -----------------------------        
   GEN_BPI : if (USE_BPI) generate

     U_BootProm : entity work.AxiMicronP30Reg
       generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_CLK_FREQ_G   => SYS_CLK_FREQ_C)
       port map (
         -- FLASH Interface 
         flashAddr      => bpiAddress,
         flashAdv       => bpiAdv,
         flashClk       => bpiClk,
         flashRstL      => bpiRstL,
         flashCeL       => bpiCeL,
         flashOeL       => bpiOeL,
         flashWeL       => bpiWeL,
         flashDin       => bpiDin,
         flashDout      => bpiDout,
         flashTri       => bpiTri,
         -- AXI-Lite Register Interface
         axiReadMaster  => axilReadMasters (PROM_INDEX_C),
         axiReadSlave   => axilReadSlaves  (PROM_INDEX_C),
         axiWriteMaster => axilWriteMasters(PROM_INDEX_C),
         axiWriteSlave  => axilWriteSlaves (PROM_INDEX_C),
         -- Clocks and Resets
         axiClk         => axiClk,
         axiRst         => axiRst);

     bpiAddr <= bpiAddress(28 downto 0);

   end generate;

   GEN_NOBPI : if not (USE_BPI) generate

     bpiAddr <= (others => '1');
      bpiAdv  <= '1';
      bpiClk  <= '1';
      bpiRstL <= '1';
      bpiCeL  <= '1';
      bpiOeL  <= '1';
      bpiWeL  <= '1';
      bpiTri  <= '1';
      bpiDin  <= (others => '1');

   end generate;
   
   GEN_SPI : if (USE_SPI) generate

      spiBusyIn(0) <= spiBusyOut(1);
      spiBusyIn(1) <= spiBusyOut(0);

      GEN_VEC : for i in 1 downto 0 generate

         U_BootProm : entity work.AxiMicronN25QCore
            generic map (
               TPD_G            => TPD_G,
               AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
               AXI_CLK_FREQ_G   => SYS_CLK_FREQ_C,        -- units of Hz
               SPI_CLK_FREQ_G   => (SYS_CLK_FREQ_C/8.0))  -- units of Hz
            port map (
               -- FLASH Memory Ports
               csL            => spiCsL(i),
               sck            => spiSck(i),
               mosi           => spiMosi(i),
               miso           => spiMiso(i),
               -- Shared SPI Interface 
               busyIn         => spiBusyIn(i),
               busyOut        => spiBusyOut(i),
               -- AXI-Lite Register Interface
               axiReadMaster  => axilReadMasters (PROM_INDEX_C+i),
               axiReadSlave   => axilReadSlaves  (PROM_INDEX_C+i),
               axiWriteMaster => axilWriteMasters(PROM_INDEX_C+i),
               axiWriteSlave  => axilWriteSlaves (PROM_INDEX_C+i),
               -- Clocks and Resets
               axiClk         => axiClk,
               axiRst         => axiRst);

      end generate GEN_VEC;

   end generate;

   GEN_NOSPI : if not (USE_SPI) generate

      GEN_VEC : for i in 1 downto 0 generate

         spiCsL  <= (others => '1');
         spiSck  <= (others => '1');
         spiMosi <= (others => '1');

      end generate GEN_VEC;

   end generate;

   -------------------------------
   -- Map the AXI-Lite to PCIe PHY
   -------------------------------
   phyWriteMaster               <= axilWriteMasters(PHY_INDEX_C);
   axilWriteSlaves(PHY_INDEX_C) <= phyWriteSlave;
   phyReadMaster                <= axilReadMasters (PHY_INDEX_C);
   axilReadSlaves(PHY_INDEX_C)  <= phyReadSlave;

   ----------------------------------
   -- Map the AXI-Lite to Application
   ----------------------------------   
   U_AxiLiteAsync : entity work.AxiLiteAsync
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         COMMON_CLK_G     => false,
         NUM_ADDR_BITS_G  => 24)
      port map (
         -- Slave Interface
         sAxiClk         => axiClk,
         sAxiClkRst      => axiRst,
         sAxiReadMaster  => axilReadMasters (APP_INDEX_C),
         sAxiReadSlave   => axilReadSlaves  (APP_INDEX_C),
         sAxiWriteMaster => axilWriteMasters(APP_INDEX_C),
         sAxiWriteSlave  => axilWriteSlaves (APP_INDEX_C),
         -- Master Interface
         mAxiClk         => appClk,
         mAxiClkRst      => appReset,
         mAxiReadMaster  => appReadMaster,
         mAxiReadSlave   => appReadSlave,
         mAxiWriteMaster => appWriteMaster,
         mAxiWriteSlave  => appWriteSlave);

   appReset <= cardResetIn or appRst;

end mapping;

