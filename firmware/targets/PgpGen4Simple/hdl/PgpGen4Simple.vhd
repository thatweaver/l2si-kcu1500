-------------------------------------------------------------------------------
-- File       : PgpGen4NoRam.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-03-10
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- This file is part of 'axi-pcie-dev'.
-- It is subject to the license terms in the LICENSE.txt file found in the 
-- top-level directory of this distribution and at: 
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html. 
-- No part of 'axi-pcie-dev', including this file, 
-- may be copied, modified, propagated, or distributed except according to 
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.AxiDescPkg.all;
use work.AxiPciePkg.all;
use work.MigPkg.all;

library unisim;
use unisim.vcomponents.all;

entity PgpGen4Simple is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      -- QSFP[0] Ports
      qsfp0RefClkP : in    slv(1 downto 0);
      qsfp0RefClkN : in    slv(1 downto 0);
      qsfp0RxP     : in    slv(3 downto 0);
      qsfp0RxN     : in    slv(3 downto 0);
      qsfp0TxP     : out   slv(3 downto 0);
      qsfp0TxN     : out   slv(3 downto 0);
      -- QSFP[1] Ports
      --qsfp1RefClkP : in    slv(1 downto 0);
      --qsfp1RefClkN : in    slv(1 downto 0);
      --qsfp1RxP     : in    slv(3 downto 0);
      --qsfp1RxN     : in    slv(3 downto 0);
      --qsfp1TxP     : out   slv(3 downto 0);
      --qsfp1TxN     : out   slv(3 downto 0);
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      swDip        : in    slv(3 downto 0);
      led          : out   slv(7 downto 0);
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- QSFP[1] Ports
      --qsfp1RstL    : out   sl;
      --qsfp1LpMode  : out   sl;
      --qsfp1ModSelL : out   sl;
      --qsfp1ModPrsL : in    sl;
      -- Boot Memory Ports 
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   sl;
      -- DDR Ports
      ddrClkP      : in    slv(1 downto 0);
      ddrClkN      : in    slv(1 downto 0);
      ddrOut       : out   DdrOutArray(1 downto 0);
      ddrInOut     : inout DdrInOutArray(1 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0) );
      -- Extended PCIe Interface
      --pciExtRefClkP   : in    sl;
      --pciExtRefClkN   : in    sl;
      --pciExtRxP       : in    slv(7 downto 0);
      --pciExtRxN       : in    slv(7 downto 0);
      --pciExtTxP       : out   slv(7 downto 0);
      --pciExtTxN       : out   slv(7 downto 0) );
end PgpGen4Simple;

architecture top_level of PgpGen4Simple is

   signal sysClks    : slv(1 downto 0);
   signal sysRsts    : slv(1 downto 0);
   signal clk200     : slv(1 downto 0);
   signal rst200     : slv(1 downto 0);
   signal irst200    : slv(1 downto 0);
   signal urst200    : slv(1 downto 0);
   signal userReset  : slv(1 downto 0);
   signal userClock  : sl;
   signal userClk156 : sl;
   signal userSwDip  : slv(3 downto 0);
   signal userLed    : slv(7 downto 0);
   
   signal qsfpRstL     : slv(1 downto 0);
   signal qsfpLpMode   : slv(1 downto 0);
   signal qsfpModSelL  : slv(1 downto 0);
   signal qsfpModPrsL  : slv(1 downto 0);

   signal qsfpRefClkP  : Slv2Array(1 downto 0);
   signal qsfpRefClkN  : Slv2Array(1 downto 0);
   signal qsfpRxP      : Slv4Array(1 downto 0);
   signal qsfpRxN      : Slv4Array(1 downto 0);
   signal qsfpTxP      : Slv4Array(1 downto 0);
   signal qsfpTxN      : Slv4Array(1 downto 0);

   signal ipciRefClkP  : slv      (1 downto 0);
   signal ipciRefClkN  : slv      (1 downto 0);
   signal ipciRxP      : Slv8Array(1 downto 0);
   signal ipciRxN      : Slv8Array(1 downto 0);
   signal ipciTxP      : Slv8Array(1 downto 0);
   signal ipciTxN      : Slv8Array(1 downto 0);

   signal vflashCsL     : slv(1 downto 0);
   signal vflashMosi    : slv(1 downto 0);
   signal vflashMiso    : slv(1 downto 0);
   signal vflashHoldL   : slv(1 downto 0);
   signal vflashWp      : slv(1 downto 0);
   
   signal axilClks         : slv                    (1 downto 0);
   signal axilRsts         : slv                    (1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray (1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray  (1 downto 0);
   signal axilWriteMasters : AxiLiteWriteMasterArray(1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray (1 downto 0);

   signal dmaObMasters    : AxiStreamMasterArray(1 downto 0);
   signal dmaObSlaves     : AxiStreamSlaveArray (1 downto 0);

   signal dmaIbMasters    : AxiWriteMasterArray (9 downto 0);
   signal dmaIbSlaves     : AxiWriteSlaveArray  (9 downto 0);

   signal hwClks          : slv                 (7 downto 0);
   signal hwRsts          : slv                 (7 downto 0);
   signal hwObMasters     : AxiStreamMasterArray(7 downto 0);
   signal hwObSlaves      : AxiStreamSlaveArray (7 downto 0);
   signal hwIbMasters     : AxiStreamMasterArray(7 downto 0);
   signal hwIbSlaves      : AxiStreamSlaveArray (7 downto 0);
   signal hwIbAlmostFull  : slv                 (7 downto 0);
   signal hwIbFull        : slv                 (7 downto 0);
   
   signal memReady        : slv                (3 downto 0);
   signal memWriteMasters : AxiWriteMasterArray(7 downto 0);
   signal memWriteSlaves  : AxiWriteSlaveArray (7 downto 0);
   signal memReadMasters  : AxiReadMasterArray (7 downto 0);
   signal memReadSlaves   : AxiReadSlaveArray  (7 downto 0);
   signal dscMasters      : AxiDescMasterArray (7 downto 0);
   signal dscSlaves       : AxiDescSlaveArray  (7 downto 0);

   constant NUM_AXIL_MASTERS_C : integer := 2;
   signal mAxilReadMasters  : AxiLiteReadMasterArray (2*NUM_AXIL_MASTERS_C-1 downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray  (2*NUM_AXIL_MASTERS_C-1 downto 0);
   signal mAxilWriteMasters : AxiLiteWriteMasterArray(2*NUM_AXIL_MASTERS_C-1 downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray (2*NUM_AXIL_MASTERS_C-1 downto 0);
   constant AXIL_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXIL_MASTERS_C-1 downto 0) := genAxiLiteConfig( NUM_AXIL_MASTERS_C, x"00800000", 23, 22);

   signal migConfig : MigConfigArray(7 downto 0) := (others=>MIG_CONFIG_INIT_C);
   signal migStatus : MigStatusArray(7 downto 0);
   
   signal sck      : slv(1 downto 0);
   signal emcClock : sl;
   signal userCclk : sl;
   signal eos      : slv(1 downto 0);

   signal mmcmClkOut : Slv2Array(1 downto 0);
   signal mmcmRstOut : Slv2Array(1 downto 0);

begin

  qsfpRefClkP(0) <= qsfp0RefClkP;
  qsfpRefClkN(0) <= qsfp0RefClkN;
  qsfpRxP    (0) <= qsfp0RxP;
  qsfpRxN    (0) <= qsfp0RxN;
  qsfp0TxP       <= qsfpTxP(0);
  qsfp0TxN       <= qsfpTxN(0);
  
  --qsfpRefClkP(1) <= qsfp1RefClkP;
  --qsfpRefClkN(1) <= qsfp1RefClkN;
  --qsfpRxP    (1) <= qsfp1RxP;
  --qsfpRxN    (1) <= qsfp1RxN;
  --qsfp1TxP       <= qsfpTxP(1);
  --qsfp1TxN       <= qsfpTxN(1);
  
  qsfp0RstL      <= qsfpRstL   (0);
  qsfp0LpMode    <= qsfpLpMode (0);
  qsfp0ModSelL   <= qsfpModSelL(0);
  qsfpModPrsL(0) <= qsfp0ModPrsL;

  --qsfp1RstL      <= qsfpRstL   (1);
  --qsfp1LpMode    <= qsfpLpMode (1);
  --qsfp1ModSelL   <= qsfpModSelL(1);
  --qsfpModPrsL(1) <= qsfp1ModPrsL;

  ipciRefClkP(0) <= pciRefClkP;
  ipciRefClkN(0) <= pciRefClkN;
  ipciRxP    (0) <= pciRxP;
  ipciRxN    (0) <= pciRxN;
  pciTxP         <= ipciTxP(0);
  pciTxN         <= ipciTxN(0);
  
  --ipciRefClkP(1) <= pciExtRefClkP;
  --ipciRefClkN(1) <= pciExtRefClkN;
  --ipciRxP    (1) <= pciExtRxP;
  --ipciRxN    (1) <= pciExtRxN;
  --pciExtTxP      <= ipciTxP(1);
  --pciExtTxN      <= ipciTxN(1);
  
  flashCsL      <= vflashCsL  (0);
  flashMosi     <= vflashMosi (0);
  flashHoldL    <= vflashHoldL(0);
  flashWp       <= vflashWp   (0);
  vflashMiso(0) <= flashMiso;
  vflashMiso(1) <= '0';
  
   --  156MHz user clock
  U_IBUFDS : IBUFDS
    port map(
      I  => userClkP,
      IB => userClkN,
      O  => userClock);

  U_BUFG : BUFG
    port map (
      I => userClock,
      O => userClk156);

  -- clock
  U_emcClk : IBUF
    port map (
      I => emcClk,
      O => emcClock);

  U_BUFGMUX : BUFGMUX
    port map (
      O  => userCclk,                -- 1-bit output: Clock output
      I0 => emcClock,                -- 1-bit input: Clock input (S=0)
      I1 => sck(0),                  -- 1-bit input: Clock input (S=1)
      S  => eos(0));                 -- 1-bit input: Clock select      

   -- led
   GEN_LED :
   for i in 7 downto 0 generate
      U_LED : OBUF
         port map (
            I => userLed(i),
            O => led(i));
   end generate GEN_LED;

   -- dip switch
   GEN_SW_DIP :
   for i in 3 downto 0 generate
      U_SwDip : IBUF
         port map (
            I => swDip(i),
            O => userSwDip(i));
   end generate GEN_SW_DIP;

  GEN_SEMI : for i in 0 to 0 generate

     clk200  (i) <= mmcmClkOut(i)(0);
     axilClks(i) <= mmcmClkOut(i)(1);
     axilRsts(i) <= mmcmRstOut(i)(1);

     -- Forcing BUFG for reset that's used everywhere      
     U_BUFG : BUFG
       port map (
         I => mmcmRstOut(i)(0),
         O => rst200(i));

     irst200(i) <= rst200(i) or userReset(i);
     -- Forcing BUFG for reset that's used everywhere      
     U_BUFGU : BUFG
       port map (
         I => irst200(i),
         O => urst200(i));
     
     U_MMCM : entity work.ClockManagerUltraScale
       generic map ( INPUT_BUFG_G       => false,
                     NUM_CLOCKS_G       => 2,
                     CLKIN_PERIOD_G     => 4.0,
                     DIVCLK_DIVIDE_G    => 1,
                     CLKFBOUT_MULT_F_G  => 4.0, -- 1.00 GHz
                     CLKOUT0_DIVIDE_F_G => 5.0, -- 200 MHz
                     CLKOUT1_DIVIDE_G   => 8 )  -- 125 MHz
       port map ( clkIn     => sysClks(i),
                  rstIn     => sysRsts(i),
                  clkOut    => mmcmClkOut(i),
                  rstOut    => mmcmRstOut(i) );
     
     U_Core : entity work.XilinxKcu1500Semi
       generic map (
         TPD_G        => TPD_G,
         MASTER_G     => ite(i>0, false, true),
         BUILD_INFO_G => BUILD_INFO_G )
       port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------        
         -- System Clock and Reset
         sysClk          => sysClks(i),
         sysRst          => sysRsts(i),
         -- DMA Interfaces
         --dmaObClk        => 
         --dmaObMaster     => dmaObMasters   (i),
         --dmaObSlave      => dmaObSlaves    (i),
         --
         dmaIbClk        => clk200         (i),
         dmaIbRst        => urst200        (i),
         dmaIbMasters    => dmaIbMasters   (5*i+4 downto 5*i),
         dmaIbSlaves     => dmaIbSlaves    (5*i+4 downto 5*i),
         -- AXI-Lite Interface
         appClk          => axilClks        (i),
         appRst          => axilRsts        (i),
         appReadMaster   => axilReadMasters (i),
         appReadSlave    => axilReadSlaves  (i),
         appWriteMaster  => axilWriteMasters(i),
         appWriteSlave   => axilWriteSlaves (i),
         --------------
         --  Core Ports
         --------------   
         -- QSFP[0] Ports
         qsfp0RstL       => qsfpRstL   (i),
         qsfp0LpMode     => qsfpLpMode (i),
         qsfp0ModSelL    => qsfpModSelL(i),
         qsfp0ModPrsL    => qsfpModPrsL(i),
         -- Boot Memory Ports 
         flashCsL        => vflashCsL  (i),
         flashMosi       => vflashMosi (i),
         flashMiso       => vflashMiso (i),
         flashHoldL      => vflashHoldL(i),
         flashWp         => vflashWp   (i),
         --
         userCclk        => userCclk,
         sck             => sck        (i),
         eos             => eos        (i),
         -- PCIe Ports 
         pciRstL         => pciRstL,
         pciRefClkP      => ipciRefClkP(i),
         pciRefClkN      => ipciRefClkN(i),
         pciRxP          => ipciRxP    (i),
         pciRxN          => ipciRxN    (i),
         pciTxP          => ipciTxP    (i),
         pciTxN          => ipciTxN    (i) );

     U_AxilXbar : entity work.AxiLiteCrossbar
       generic map ( NUM_SLAVE_SLOTS_G  => 1,
                     NUM_MASTER_SLOTS_G => NUM_AXIL_MASTERS_C,
                     MASTERS_CONFIG_G   => AXIL_CROSSBAR_MASTERS_CONFIG_C )
       port map    ( axiClk              => axilClks        (i),
                     axiClkRst           => axilRsts        (i),
                     sAxiWriteMasters(0) => axilWriteMasters(i),
                     sAxiWriteSlaves (0) => axilWriteSlaves (i),
                     sAxiReadMasters (0) => axilReadMasters (i),
                     sAxiReadSlaves  (0) => axilReadSlaves  (i),
                     mAxiWriteMasters    => mAxilWriteMasters((i+1)*NUM_AXIL_MASTERS_C-1 downto i*NUM_AXIL_MASTERS_C),
                     mAxiWriteSlaves     => mAxilWriteSlaves ((i+1)*NUM_AXIL_MASTERS_C-1 downto i*NUM_AXIL_MASTERS_C),
                     mAxiReadMasters     => mAxilReadMasters ((i+1)*NUM_AXIL_MASTERS_C-1 downto i*NUM_AXIL_MASTERS_C),
                     mAxiReadSlaves      => mAxilReadSlaves  ((i+1)*NUM_AXIL_MASTERS_C-1 downto i*NUM_AXIL_MASTERS_C) );

     U_Hw : entity work.HardwareSemi
       generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => BAR0_ERROR_RESP_C,
         AXI_BASE_ADDR_G  => x"00C00000")
       port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------         
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClks        (i),
         axilRst         => axilRsts        (i),
         axilReadMaster  => mAxilReadMasters (i*NUM_AXIL_MASTERS_C+1),
         axilReadSlave   => mAxilReadSlaves  (i*NUM_AXIL_MASTERS_C+1),
         axilWriteMaster => mAxilWriteMasters(i*NUM_AXIL_MASTERS_C+1),
         axilWriteSlave  => mAxilWriteSlaves (i*NUM_AXIL_MASTERS_C+1),
         -- DMA Interface (dmaClk domain)
         dmaClks         => hwClks        (4*i+3 downto 4*i),
         dmaRsts         => hwRsts        (4*i+3 downto 4*i),
         dmaObMasters    => hwObMasters   (4*i+3 downto 4*i),
         dmaObSlaves     => hwObSlaves    (4*i+3 downto 4*i),
         dmaIbMasters    => hwIbMasters   (4*i+3 downto 4*i),
         dmaIbSlaves     => hwIbSlaves    (4*i+3 downto 4*i),
         dmaIbAlmostFull => hwIbAlmostFull(4*i+3 downto 4*i),
         dmaIbFull       => hwIbFull      (4*i+3 downto 4*i),
         ------------------
         --  Hardware Ports
         ------------------       
         -- QSFP[0] Ports
         qsfp0RefClkP    => qsfpRefClkP(i),
         qsfp0RefClkN    => qsfpRefClkN(i),
         qsfp0RxP        => qsfpRxP    (i),
         qsfp0RxN        => qsfpRxN    (i),
         qsfp0TxP        => qsfpTxP    (i),
         qsfp0TxN        => qsfpTxN    (i) );

     hwObMasters(4*i+3 downto 4*i) <= (others=>AXI_STREAM_MASTER_INIT_C);

     GEN_HWDMA : for j in 4*i+0 to 4*i+3 generate
       U_HwDma : entity work.AppToMigWrapper
         generic map ( AXI_BASE_ADDR_G     => (toSlv(j,1) & toSlv(0,31)),
                       DEBUG_G             => (j<1) )
         port map ( sAxisClk        => hwClks         (j),
                    sAxisRst        => hwRsts         (j),
                    sAxisMaster     => hwIbMasters    (j),
                    sAxisSlave      => hwIbSlaves     (j),
                    sAlmostFull     => hwIbAlmostFull (j),
                    sFull           => hwIbFull       (j),
                    mAxiClk         => clk200     (i),
                    mAxiRst         => urst200    (i),
                    mAxiWriteMaster => memWriteMasters(j),
                    mAxiWriteSlave  => memWriteSlaves (j),
                    dscReadMaster   => dscMasters     (j),
                    dscReadSlave    => dscSlaves      (j),
                    memReady        => memReady       (j/2),
                    config          => migConfig      (j),
                    status          => migStatus      (j) );
     end generate;

     U_Mig2Pcie : entity work.MigToPcieWrapper
       generic map ( NAPP_G           => 4,
                     AXIL_BASE_ADDR_G => x"00800000" )
       port map ( axiClk         => clk200(i),
                  axiRst         => rst200(i),
                  usrRst         => userReset(i),
                  axiReadMasters => memReadMasters(4*i+3 downto 4*i),
                  axiReadSlaves  => memReadSlaves (4*i+3 downto 4*i),
                  dscReadMasters => dscMasters    (4*i+3 downto 4*i),
                  dscReadSlaves  => dscSlaves     (4*i+3 downto 4*i),
                  axiWriteMasters=> dmaIbMasters  (5*i+4 downto 5*i),
                  axiWriteSlaves => dmaIbSlaves   (5*i+4 downto 5*i),
                  axilClk        => axilClks        (i),
                  axilRst        => axilRsts        (i),
                  axilWriteMaster=> mAxilWriteMasters(i*NUM_AXIL_MASTERS_C+0),
                  axilWriteSlave => mAxilWriteSlaves (i*NUM_AXIL_MASTERS_C+0),
                  axilReadMaster => mAxilReadMasters (i*NUM_AXIL_MASTERS_C+0),
                  axilReadSlave  => mAxilReadSlaves  (i*NUM_AXIL_MASTERS_C+0),
                  migConfig      => migConfig      (4*i+3 downto 4*i),
                  migStatus      => migStatus      (4*i+3 downto 4*i) );

     end generate;

   U_MIG0 : entity work.Mig0
    port map ( axiReady        => memReady(0),
               --
               axiClk          => clk200         (0),
               axiRst          => urst200        (0),
               axiWriteMasters => memWriteMasters(1 downto 0),
               axiWriteSlaves  => memWriteSlaves (1 downto 0),
               axiReadMasters  => memReadMasters (1 downto 0),
               axiReadSlaves   => memReadSlaves  (1 downto 0),
               --
               ddrClkP         => ddrClkP (0),
               ddrClkN         => ddrClkN (0),
               ddrOut          => ddrOut  (0),
               ddrInOut        => ddrInOut(0) );

  U_MIG1 : entity work.Mig1
    port map ( axiReady        => memReady(1),
               --
               axiClk          => clk200         (0),
               axiRst          => urst200        (0),
               axiWriteMasters => memWriteMasters(3 downto 2),
               axiWriteSlaves  => memWriteSlaves (3 downto 2),
               axiReadMasters  => memReadMasters (3 downto 2),
               axiReadSlaves   => memReadSlaves  (3 downto 2),
               --
               ddrClkP         => ddrClkP (1),
               ddrClkN         => ddrClkN (1),
               ddrOut          => ddrOut  (1),
               ddrInOut        => ddrInOut(1) );
  
  --U_MIG2 : entity work.Mig2
  --  port map ( axiReady        => memReady(2),
  --             --
  --             axiClk          => clk200         (1),
  --             axiRst          => rst200         (1),
  --             axiWriteMasters => memWriteMasters(5 downto 4),
  --             axiWriteSlaves  => memWriteSlaves (5 downto 4),
  --             axiReadMasters  => memReadMasters (5 downto 4),
  --             axiReadSlaves   => memReadSlaves  (5 downto 4),
  --             --
  --             ddrClkP         => ddrClkP (2),
  --             ddrClkN         => ddrClkN (2),
  --             ddrOut          => ddrOut  (2),
  --             ddrInOut        => ddrInOut(2) );

  --U_MIG3 : entity work.Mig3
  --  port map ( axiReady        => memReady(3),
  --             --
  --             axiClk          => clk200         (1),
  --             axiRst          => rst200         (1),
  --             axiWriteMasters => memWriteMasters(7 downto 6),
  --             axiWriteSlaves  => memWriteSlaves (7 downto 6),
  --             axiReadMasters  => memReadMasters (7 downto 6),
  --             axiReadSlaves   => memReadSlaves  (7 downto 6),
  --             --
  --             ddrClkP         => ddrClkP (3),
  --             ddrClkN         => ddrClkN (3),
  --             ddrOut          => ddrOut  (3),
  --             ddrInOut        => ddrInOut(3) );

   -- Unused user signals
   userLed <= (others => '0');

end top_level;
