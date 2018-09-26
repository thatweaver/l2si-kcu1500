-------------------------------------------------------------------------------
-- File       : PgpGen4NoRam.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-10-24
-- Last update: 2018-09-08
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
use work.I2cPkg.all;
use work.MigPkg.all;
use work.TDetPkg.all;

library unisim;
use unisim.vcomponents.all;

entity DrpTDet is
   generic (
      TPD_G        : time := 1 ns;
      BUILD_INFO_G : BuildInfoType);
   port (
      ---------------------
      --  Application Ports
      ---------------------
      timingRefClkP : in    sl;
      timingRefClkN : in    sl;
      timingRxP     : in    sl;
      timingRxN     : in    sl;
      timingTxP     : out   sl;
      timingTxN     : out   sl;
      --------------
      --  Core Ports
      --------------
      -- System Ports
      emcClk       : in    sl;
      userClkP     : in    sl;
      userClkN     : in    sl;
      swDip        : in    slv(3 downto 0);
      led          : out   slv(7 downto 0);
      scl          : inout sl;
      sda          : inout sl;
      i2c_rst_l    : out   sl;
      -- QSFP[0] Ports
      qsfp0RstL    : out   sl;
      qsfp0LpMode  : out   sl;
      qsfp0ModSelL : out   sl;
      qsfp0ModPrsL : in    sl;
      -- Boot Memory Ports 
      flashCsL     : out   sl;
      flashMosi    : out   sl;
      flashMiso    : in    sl;
      flashHoldL   : out   sl;
      flashWp      : out   slv          (1 downto 0);
      -- DDR Ports
      ddrClkP      : in    slv          (1 downto 0);
      ddrClkN      : in    slv          (1 downto 0);
      ddrOut       : out   DdrOutArray  (1 downto 0);
      ddrInOut     : inout DdrInOutArray(1 downto 0);
      -- PCIe Ports
      pciRstL      : in    sl;
      pciRefClkP   : in    sl;
      pciRefClkN   : in    sl;
      pciRxP       : in    slv(7 downto 0);
      pciRxN       : in    slv(7 downto 0);
      pciTxP       : out   slv(7 downto 0);
      pciTxN       : out   slv(7 downto 0);
      -- Extended PCIe Interface
      pciExtRefClkP   : in    sl;
      pciExtRefClkN   : in    sl;
      pciExtRxP       : in    slv(7 downto 0);
      pciExtRxN       : in    slv(7 downto 0);
      pciExtTxP       : out   slv(7 downto 0);
      pciExtTxN       : out   slv(7 downto 0) );
end DrpTDet;

architecture top_level of DrpTDet is

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

   signal qsfpRstL     : slv(1 downto 0) := "11";
   signal qsfpLpMode   : slv(1 downto 0) := "00";
   signal qsfpModSelL  : slv(1 downto 0) := "11";
   signal qsfpModPrsL  : slv(1 downto 0) := "11";

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

   signal memReady        : slv                (1 downto 0);
   signal memWriteMasters : AxiWriteMasterArray(7 downto 0);
   signal memWriteSlaves  : AxiWriteSlaveArray (7 downto 0);
   signal memReadMasters  : AxiReadMasterArray (7 downto 0);
   signal memReadSlaves   : AxiReadSlaveArray  (7 downto 0);
   signal dscMasters      : AxiDescMasterArray (7 downto 0);
   signal dscSlaves       : AxiDescSlaveArray  (7 downto 0);

   constant RNG_AXIL_MASTERS_C : IntegerArray(3 downto 0) := (5,4,3,0);
   constant NUM_AXIL_MASTERS_SUM : integer := 6;
   signal mAxilReadMasters  : AxiLiteReadMasterArray (RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilReadSlaves   : AxiLiteReadSlaveArray  (RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilWriteMasters : AxiLiteWriteMasterArray(RNG_AXIL_MASTERS_C(3) downto 0);
   signal mAxilWriteSlaves  : AxiLiteWriteSlaveArray (RNG_AXIL_MASTERS_C(3) downto 0);
   constant AXIL0_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(3 downto 0) := (
     0 => (baseAddr     => x"00800000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     1 => (baseAddr     => x"00A00000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     2 => (baseAddr     => x"00C00000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     3 => (baseAddr     => x"00E00000",
           addrBits     => 21,
           connectivity => x"FFFF") );
   constant AXIL1_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(1 downto 0) := (
     0 => (baseAddr     => x"00800000",
           addrBits     => 21,
           connectivity => x"FFFF"),
     1 => (baseAddr     => x"00A00000",
           addrBits     => 21,
           connectivity => x"FFFF") );

   signal migConfig : MigConfigArray(7 downto 0) := (others=>MIG_CONFIG_INIT_C);
   signal migStatus : MigStatusArray(7 downto 0);
   
   signal sck      : slv(1 downto 0);
   signal emcClock : sl;
   signal userCclk : sl;
   signal eos      : slv(1 downto 0);

   signal mmcmClkOut : Slv3Array(1 downto 0);
   signal mmcmRstOut : Slv3Array(1 downto 0);

   constant NDET_C   : integer := 8;
   signal tdetClk    : sl;
   signal tdetRst    : sl;
   signal tdetTiming : TDetTimingArray(NDET_C-1 downto 0);
   signal tdetEvent  : TDetEventArray (NDET_C-1 downto 0);
   signal tdetStatus : TDetStatusArray(NDET_C-1 downto 0);

   constant DEVICE_MAP_C : I2cAxiLiteDevArray(3 downto 0) := (
    -----------------------
    -- PC821 I2C DEVICES --
    -----------------------
    -- PCA9548A I2C Mux
    0 => MakeI2cAxiLiteDevType( "1110100", 8, 0, '0' ),
    -- QSFP1, QSFP0, EEPROM;  I2C Mux = 1, 4, 5
    1 => MakeI2cAxiLiteDevType( "1010000", 8, 8, '0' ),
    -- SI570                  I2C Mux = 2
    2 => MakeI2cAxiLiteDevType( "1011101", 8, 8, '0' ),
    -- Fan                    I2C Mux = 3
    3 => MakeI2cAxiLiteDevType( "1001100", 8, 8, '0' ) );
   
begin

  qsfp0RstL      <= qsfpRstL   (0);
  qsfp0LpMode    <= qsfpLpMode (0);
  qsfp0ModSelL   <= qsfpModSelL(0);
  qsfpModPrsL(0) <= qsfp0ModPrsL;

  ipciRefClkP(0) <= pciRefClkP;
  ipciRefClkN(0) <= pciRefClkN;
  ipciRxP    (0) <= pciRxP;
  ipciRxN    (0) <= pciRxN;
  pciTxP         <= ipciTxP(0);
  pciTxN         <= ipciTxN(0);
  
  ipciRefClkP(1) <= pciExtRefClkP;
  ipciRefClkN(1) <= pciExtRefClkN;
  ipciRxP    (1) <= pciExtRxP;
  ipciRxN    (1) <= pciExtRxN;
  pciExtTxP      <= ipciTxP(1);
  pciExtTxN      <= ipciTxN(1);
  
  flashCsL      <= vflashCsL  (0);
  flashMosi     <= vflashMosi (0);
  flashHoldL    <= vflashHoldL(0);
  flashWp       <= vflashWp   (0);
  vflashMiso(0) <= flashMiso;
  vflashMiso(1) <= '0';

  i2c_rst_l     <= '1';
  
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

     U_AxilXbar0 : entity work.AxiLiteCrossbar
       generic map ( NUM_SLAVE_SLOTS_G  => 1,
                     NUM_MASTER_SLOTS_G => 4,
                     MASTERS_CONFIG_G   => AXIL0_CROSSBAR_MASTERS_CONFIG_C )
       port map    ( axiClk              => axilClks        (0),
                     axiClkRst           => axilRsts        (0),
                     sAxiWriteMasters(0) => axilWriteMasters(0),
                     sAxiWriteSlaves (0) => axilWriteSlaves (0),
                     sAxiReadMasters (0) => axilReadMasters (0),
                     sAxiReadSlaves  (0) => axilReadSlaves  (0),
                     mAxiWriteMasters    => mAxilWriteMasters(3 downto 0),
                     mAxiWriteSlaves     => mAxilWriteSlaves (3 downto 0),
                     mAxiReadMasters     => mAxilReadMasters (3 downto 0),
                     mAxiReadSlaves      => mAxilReadSlaves  (3 downto 0) );

     U_AxilXbar1 : entity work.AxiLiteCrossbar
       generic map ( NUM_SLAVE_SLOTS_G  => 1,
                     NUM_MASTER_SLOTS_G => 2,
                     MASTERS_CONFIG_G   => AXIL1_CROSSBAR_MASTERS_CONFIG_C )
       port map    ( axiClk              => axilClks        (1),
                     axiClkRst           => axilRsts        (1),
                     sAxiWriteMasters(0) => axilWriteMasters(1),
                     sAxiWriteSlaves (0) => axilWriteSlaves (1),
                     sAxiReadMasters (0) => axilReadMasters (1),
                     sAxiReadSlaves  (0) => axilReadSlaves  (1),
                     mAxiWriteMasters    => mAxilWriteMasters(5 downto 4),
                     mAxiWriteSlaves     => mAxilWriteSlaves (5 downto 4),
                     mAxiReadMasters     => mAxilReadMasters (5 downto 4),
                     mAxiReadSlaves      => mAxilReadSlaves  (5 downto 4) );
  
   U_I2C : entity work.AxiI2cRegMaster
     generic map ( DEVICE_MAP_G   => DEVICE_MAP_C,
                   AXI_CLK_FREQ_G => 125.0E+6 )
     port map ( scl            => scl,
                sda            => sda,
                axiReadMaster  => mAxilReadMasters (RNG_AXIL_MASTERS_C(0)+3),
                axiReadSlave   => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(0)+3),
                axiWriteMaster => mAxilWriteMasters(RNG_AXIL_MASTERS_C(0)+3),
                axiWriteSlave  => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(0)+3),
                axiClk         => axilClks(0),
                axiRst         => axilRsts(0) );

   U_Timing : entity work.TDetTiming
     generic map ( NDET_G          => 8,
                   AXIL_BASEADDR_G => AXIL0_CROSSBAR_MASTERS_CONFIG_C(2).baseAddr )
     port map ( -- AXI-Lite Interface
                axilClk          => axilClks(0),
                axilRst          => axilRsts(0),
                axilReadMaster   => maxilReadMasters (RNG_AXIL_MASTERS_C(0)+2),
                axilReadSlave    => maxilReadSlaves  (RNG_AXIL_MASTERS_C(0)+2),
                axilWriteMaster  => maxilWriteMasters(RNG_AXIL_MASTERS_C(0)+2),
                axilWriteSlave   => maxilWriteSlaves (RNG_AXIL_MASTERS_C(0)+2),
                -- Timing Interface
                tdetClk          => tdetClk   ,
                tdetTiming       => tdetTiming,
                tdetEvent        => tdetEvent ,
                tdetStatus       => tdetStatus,
                -- Timing Phy Ports
                timingRxP        => timingRxP,
                timingRxN        => timingRxN,
                timingTxP        => timingTxP,
                timingTxN        => timingTxN,
                timingRefClkInP  => timingRefClkP,
                timingRefClkInN  => timingRefClkN );

  tdetClk <= mmcmClkOut(0)(2);
  tdetRst <= mmcmRstOut(0)(2);
  
  GEN_SEMI : for i in 0 to 1 generate
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
                     NUM_CLOCKS_G       => 3,
                     CLKIN_PERIOD_G     => 4.0,
                     DIVCLK_DIVIDE_G    => 1,
                     CLKFBOUT_MULT_F_G  => 5.0,  -- 1.25 GHz
                     CLKOUT0_DIVIDE_F_G => 6.25, -- 200 MHz
                     CLKOUT1_DIVIDE_G   => 10,   -- 125 MHz
                     CLKOUT2_DIVIDE_G   =>  8 )  -- 156.25 MHz
       port map ( clkIn     => sysClks(i),
                  rstIn     => sysRsts(i),
                  clkOut    => mmcmClkOut(i),
                  rstOut    => mmcmRstOut(i) );
     
     U_Core : entity work.XilinxKcu1500Semi
       generic map (
         TPD_G           => TPD_G,
         MASTER_G        => ite(i>0, false, true),
         EN_DEVICE_DNA_G => false,
         EN_XVC_G        => false,
         BUILD_INFO_G    => BUILD_INFO_G )
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

     U_Hw : entity work.TDetSemi
       generic map ( DEBUG_G => (i<1) )
       port map (
         ------------------------      
         --  Top Level Interfaces
         ------------------------         
         -- AXI-Lite Interface (axilClk domain)
         axilClk         => axilClks        (i),
         axilRst         => axilRsts        (i),
         axilReadMaster  => mAxilReadMasters (RNG_AXIL_MASTERS_C(2*i)+1),
         axilReadSlave   => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(2*i)+1),
         axilWriteMaster => mAxilWriteMasters(RNG_AXIL_MASTERS_C(2*i)+1),
         axilWriteSlave  => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(2*i)+1),
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
         --  TDET Ports
         ------------------       
         tdetClk         => tdetClk,
         tdetClkRst      => tdetRst,
         tdetTiming      => tdetTiming(4*i+3 downto 4*i),
         tdetEvent       => tdetEvent (4*i+3 downto 4*i),
         tdetStatus      => tdetStatus(4*i+3 downto 4*i),
         modPrsL         => qsfpModPrsL(i) );

     hwObMasters(4*i+3 downto 4*i) <= (others=>AXI_STREAM_MASTER_INIT_C);

     GEN_HWDMA : for j in 4*i+0 to 4*i+3 generate
       U_HwDma : entity work.AppToMigWrapper
         generic map ( AXI_BASE_ADDR_G     => (toSlv(j,2) & toSlv(0,30)) )
--                       DEBUG_G             => (j<1) )
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
                    memReady        => memReady       (i),
                    config          => migConfig      (j),
                    status          => migStatus      (j) );
     end generate;

     U_Mig2Pcie : entity work.MigToPcieWrapper
       generic map ( NAPP_G           => 1,
                     AXIL_BASE_ADDR_G => x"00800000" )
--                     DEBUG_G          => (i<1) )
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
                  axilWriteMaster=> mAxilWriteMasters(RNG_AXIL_MASTERS_C(2*i)+0),
                  axilWriteSlave => mAxilWriteSlaves (RNG_AXIL_MASTERS_C(2*i)+0),
                  axilReadMaster => mAxilReadMasters (RNG_AXIL_MASTERS_C(2*i)+0),
                  axilReadSlave  => mAxilReadSlaves  (RNG_AXIL_MASTERS_C(2*i)+0),
                  migConfig      => migConfig      (4*i+3 downto 4*i),
                  migStatus      => migStatus      (4*i+3 downto 4*i) );

     end generate;

       U_MIG0 : entity work.MigA
         port map ( axiReady        => memReady(0),
                    --
                    axiClk          => clk200         (0),
                    axiRst          => urst200        (0),
                    axiWriteMasters => memWriteMasters(3 downto 0),
                    axiWriteSlaves  => memWriteSlaves (3 downto 0),
                    axiReadMasters  => memReadMasters (3 downto 0),
                    axiReadSlaves   => memReadSlaves  (3 downto 0),
                    --
                    ddrClkP         => ddrClkP (0),
                    ddrClkN         => ddrClkN (0),
                    ddrOut          => ddrOut  (0),
                    ddrInOut        => ddrInOut(0) );

       U_MIG1 : entity work.MigB
         port map ( axiReady        => memReady(1),
                    --
                    axiClk          => clk200         (1),
                    axiRst          => urst200        (1),
                    axiWriteMasters => memWriteMasters(7 downto 4),
                    axiWriteSlaves  => memWriteSlaves (7 downto 4),
                    axiReadMasters  => memReadMasters (7 downto 4),
                    axiReadSlaves   => memReadSlaves  (7 downto 4),
                    --
                    ddrClkP         => ddrClkP (1),
                    ddrClkN         => ddrClkN (1),
                    ddrOut          => ddrOut  (1),
                    ddrInOut        => ddrInOut(1) );
  
   -- Unused user signals
   userLed <= (others => '0');

end top_level;
