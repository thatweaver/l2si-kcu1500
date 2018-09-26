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
  constant LANES_C : integer := 4;
  
  signal axiClk, axiRst : sl;
  signal axilWriteMaster     : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
  signal axilWriteSlave      : AxiLiteWriteSlaveType;
  signal axilReadMaster      : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
  signal axilReadSlave       : AxiLiteReadSlaveType := AXI_LITE_READ_SLAVE_INIT_C;

  signal axiReadMasters      : AxiReadMasterArray(LANES_C-1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal axiReadSlaves       : AxiReadSlaveArray (LANES_C-1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal dscReadMasters      : AxiDescMasterArray(LANES_C-1 downto 0) := (others=>AXI_DESC_MASTER_INIT_C);
  signal dscReadSlaves       : AxiDescSlaveArray (LANES_C-1 downto 0) := (others=>AXI_DESC_SLAVE_INIT_C);

  signal axiWriteMasters     : AxiWriteMasterArray(LANES_C downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal axiWriteSlaves      : AxiWriteSlaveArray (LANES_C downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);

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

  constant config : MigConfigType := MIG_CONFIG_INIT_C;
  signal status   : MigStatusArray(LANES_C-1 downto 0);

  signal memWriteMasters : AxiWriteMasterArray(LANES_C-1 downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal memReadMasters  : AxiReadMasterArray (LANES_C-1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal memWriteSlaves  : AxiWriteSlaveArray (LANES_C-1 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);
  signal memReadSlaves   : AxiReadSlaveArray  (LANES_C-1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal ddrClk         : sl;
  signal ddrRst         : sl;
  signal ddrWriteMaster : AxiWriteMasterArray(1 downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal ddrReadMaster  : AxiReadMasterArray (1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal ddrWriteSlave  : AxiWriteSlaveArray (1 downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);
  signal ddrReadSlave   : AxiReadSlaveArray  (1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal pcieClk   : sl;
  signal pcieRst   : sl;
  signal pcieWriteMaster : AxiWriteMasterType := AXI_WRITE_MASTER_INIT_C;
  signal pcieReadMaster  : AxiReadMasterType  := AXI_READ_MASTER_INIT_C;
  signal pcieWriteSlave  : AxiWriteSlaveType  := AXI_WRITE_SLAVE_INIT_C;
  signal pcieReadSlave   : AxiReadSlaveType   := AXI_READ_SLAVE_INIT_C;

  signal pcie_wdata : slv(255 downto 0);

  signal pcieDescWr    : sl;
  signal pcieDescDin   : slv(31 downto 0);
  signal pcieDescRd    : sl;
  signal pcieDescDout  : slv(31 downto 0);
  signal pcieDescValid : sl;

  signal mem_wdata  : Slv128Array(3 downto 0);
  signal mem_rdata  : Slv128Array(3 downto 0);
begin

  pcie_wdata <= pcieWriteMaster.wdata(255 downto 0);
  
  GEN_LANES : for i in 0 to LANES_C-1 generate
    U_DUT : entity work.AppToMigWrapper
      generic map ( AXI_BASE_ADDR_G     => ite( i mod 2 = 0, x"00000000", x"80000000") )
      port map ( sAxisClk        => axisClk,
                 sAxisRst        => axisRst,
                 sAxisMaster     => sAxisMasters(i),
                 sAxisSlave      => sAxisSlaves (i),
                 mAxiClk         => axiClk,
                 mAxiRst         => axiRst,
                 mAxiWriteMaster => mAxiWriteMasters(i),
                 mAxiWriteSlave  => mAxiWriteSlaves (i),
                 dscReadMaster   => dscReadMasters  (i),
                 dscReadSlave    => dscReadSlaves   (i),
                 config          => config,
                 status          => status          (i) );
    memReadMasters (i) <= axiReadMasters  (i);
    memWriteMasters(i) <= mAxiWriteMasters(i);
    axiReadSlaves  (i) <= memReadSlaves   (i);
    mAxiWriteSlaves(i) <= memWriteSlaves  (i);
    -- debugging
    mem_wdata(i)  <= memWriteMasters(i).wdata(127 downto 0);
    mem_rdata(i)  <= memReadSlaves  (i).rdata(127 downto 0);
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

  --GEN_AXIWS : for i in 0 to LANES_C+1 generate
  --  U_AxiWriteslave : entity work.AxiWriteSlaveSim
  --    port map ( axiClk => axiClk,
  --               axiRst => axiRst,
  --               axiWriteMaster => axiWriteMasters(i),
  --               axiWriteSlave  => axiWriteSlaves (i) );
--  end generate;

  U_PcieWriteSlave : entity work.AxiWriteSlaveSim
    port map ( axiClk => pcieClk,
               axiRst => pcieRst,
               axiWriteMaster => pcieWriteMaster,
               axiWriteSlave  => pcieWriteSlave );
  
  U_PcieReadSlave : entity work.AxiReadSlaveSim
    port map ( axiClk => pcieClk,
               axiRst => pcieRst,
               axiReadMaster => pcieReadMaster,
               axiReadSlave  => pcieReadSlave );

  GEN_MIG : for i in 0 to 1 generate
    U_MIG0 : entity work.MigXbarV2Wrapper
      port map (
        -- Slave Interfaces
        sAxiClk          => axiClk,
        sAxiRst          => axiRst,
        sAxiWriteMasters => memWriteMasters(2*i+1 downto 2*i),
        sAxiWriteSlaves  => memWriteSlaves (2*i+1 downto 2*i),
        sAxiReadMasters  => memReadMasters (2*i+1 downto 2*i),
        sAxiReadSlaves   => memReadSlaves  (2*i+1 downto 2*i),
        -- Master Interface
        mAxiClk          => ddrClk,
        mAxiRst          => ddrRst,
        mAxiWriteMaster  => ddrWriteMaster(i),
        mAxiWriteSlave   => ddrWriteSlave (i),
        mAxiReadMaster   => ddrReadMaster (i),
        mAxiReadSlave    => ddrReadSlave  (i) );
    U_AxiReadSlave : entity work.AxiReadSlaveSim
      port map ( axiClk         => ddrClk,
                 axiRst         => ddrRst,
                 axiReadMaster  => ddrReadMaster(i),
                 axiReadSlave   => ddrReadSlave (i));
    U_AxiWriteSlave : entity work.AxiWriteSlaveSim
      port map ( axiClk         => ddrClk,
                 axiRst         => ddrRst,
                 axiWriteMaster => ddrWriteMaster(i),
                 axiWriteSlave  => ddrWriteSlave (i));
  end generate;

  U_DdrRecord_0 : entity work.AxiRecord
    generic map ( filename => "ddr_lane0.txt" )
    port map ( axiClk    => ddrClk,
               axiMaster => ddrWriteMaster(0) ); 
  U_DdrRecord_1 : entity work.AxiRecord
    generic map ( filename => "ddr_lane1.txt") 
    port map ( axiClk    => ddrClk,
               axiMaster => ddrWriteMaster(1) );
 
  U_PCIE : entity work.PcieXbarV2Wrapper
   port map (
      -- Slaves
      sAxiClk          => axiClk,
      sAxiRst          => axiRst,
      sAxiWriteMasters => axiWriteMasters,
      sAxiWriteSlaves  => axiWriteSlaves,
      -- Master
      mAxiClk          => pcieClk,
      mAxiRst          => pcieRst,
      mAxiWriteMaster  => pcieWriteMaster,
      mAxiWriteSlave   => pcieWriteSlave,
      mAxiReadMaster   => pcieReadMaster,
      mAxiReadSlave    => pcieReadSlave );


  GEN_SAXIS : for k in 0 to LANES_C-1 generate
    process is
      variable count : slv(31 downto 0) := (others=>'0');
    begin
      wait for 200 ns;
      if axisRst = '1' then
        wait until axisRst = '0';
      end if;
      if axilDone = '0' then
        wait until axilDone = '1';
      end if;

      for i in 0 to 15 loop
        wait until (axisClk = '1' and (sAxisMasters(k).tValid = '0' or sAxisSlaves(k).tReady = '1'));
        wait until axisClk = '0';
        sAxisMasters(k).tValid <= '1';
        sAxisMasters(k).tLast  <= '0';
        if i = 0 then
          sAxisMasters(k).tData(63 downto 0) <= count & x"FEFEFEFE";
          count := count + 1;
        else
          for j in 0 to 7 loop
            sAxisMasters(k).tData(j*8+7 downto j*8) <= toSlv(j+8*i,8);
          end loop;
        end if;
      end loop;
      sAxisMasters(k).tLast <= '1';
      wait until (axisClk = '1' and sAxisSlaves(k).tReady = '1');
      sAxisMasters(k).tValid <= '0';
    end process;
  end generate;

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
     variable index   : slv(31 downto 0);
  begin
    axilDone <= '0';
    wait until axiRst='0';
    wait for 20 ns;

    wreg(128,x"ABCD0000"); -- Descriptor pages addr(31:0)
    wreg(132,x"00000000"); -- Descriptor pages addr(39:32)
    for i in 16 to 25 loop
      phyAddr := toSlv(15,24) & toSlv(i,19) & toSlv(0,21); -- 2MB buffers
      wreg(136,phyAddr(31 downto 0));
      wreg(140,toSlv(i,24) & phyAddr(39 downto 32));
    end loop;
    for i in 0 to LANES_C-1 loop
      wreg(256+i*32,x"00000000");  -- Set lanes to receive to app 0
    end loop;

    wreg(20, x"ABABA000");  -- monBaseAddr
    wreg(24, x"000000CD");
    wreg( 8, toSlv(200,32) );-- monSampleIntv
    wreg(12, toSlv( 10,32) );-- monReadoutIntv
    wreg(16, toSlv(  1,32) );-- monEnable
    
    wait for 20 ns;
    axilDone <= '1';

    for i in 0 to 99 loop
      pcieDescRd <= '0';
      if pcieDescValid = '0' then
        wait until pcieDescValid = '1';
      end if;
      phyAddr := toSlv(15,24) & pcieDescDout(18 downto 0) & toSlv(0,21); -- 2MB buffers
      wreg(136,phyAddr(31 downto 0));
      wreg(140,x"0" & pcieDescDout(19 downto 0) & phyAddr(39 downto 32));
      pcieDescRd <= '1';
      wait until pcieClk = '1';
    end loop;

    wait;
    
  end process;

  process is
  begin
    pcieDescWr  <= '0';
    wait until pcieWriteMaster.awvalid='0';
    wait until (pcieWriteMaster.awvalid='1' and pcieWriteMaster.awaddr(31 downto 16)=x"ABCD");
    if pcieWriteMaster.wvalid='0' then
      wait until pcieWriteMaster.wvalid='1';
    end if;
    pcieDescWr  <= '1';
    pcieDescDin <= resize(pcieWriteMaster.wdata(23 downto 4),32);
    wait until pcieClk = '1';
  end process;
     
  U_DescFIFO : entity work.FifoSync
    generic map ( FWFT_EN_G => true,
                  DATA_WIDTH_G => 32,
                  ADDR_WIDTH_G => 8 )
    port map ( rst    => pcieRst,
               clk    => pcieClk,
               wr_en  => pcieDescWr,
               din    => pcieDescDin,
               rd_en  => pcieDescRd,
               dout   => pcieDescDout,
               valid  => pcieDescValid );

  process is
  begin
    ddrClk <= '1';
    wait for 1.667 ns;
    ddrClk <= '0';
    wait for 1.667 ns;
  end process;

  pcieRst <= axiRst;
     
  process is
  begin
    pcieClk <= '1';
    wait for 2.0 ns;
    pcieClk <= '0';
    wait for 2.0 ns;
  end process;

  U_AxiRecord : entity work.AxiRecord
    generic map ( filename => "pcie_record.txt" )
    port map ( axiClk    => pcieClk,
               axiMaster => pcieWriteMaster );
     
end architecture;

