library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiPkg.all;
use work.AxiLitePkg.all;
use work.AxiDescPkg.all;

library unisim;
use unisim.vcomponents.all;

entity daq_sim is
end daq_sim;

architecture top_level_app of daq_sim is

  signal axiClk, axiRst : sl;
  signal axilWriteMaster     : AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
  signal axilWriteSlave      : AxiLiteWriteSlaveType;
  signal axilReadMaster      : AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
  signal axilReadSlave       : AxiLiteReadSlaveType;

  constant LANES_C : integer := 1;
  signal axiReadMasters      : AxiReadMasterArray(LANES_C-1 downto 0) := (others=>AXI_READ_MASTER_INIT_C);
  signal axiReadSlaves       : AxiReadSlaveArray (LANES_C-1 downto 0) := (others=>AXI_READ_SLAVE_INIT_C);

  signal dscWriteMasters      : AxiDescMasterArray(LANES_C downto 0) := (others=>AXI_DESC_MASTER_INIT_C);
  signal dscWriteSlaves       : AxiDescSlaveArray (LANES_C downto 0) := (others=>AXI_DESC_SLAVE_INIT_C);

  signal axiWriteMasters      : AxiWriteMasterArray(LANES_C downto 0) := (others=>AXI_WRITE_MASTER_INIT_C);
  signal axiWriteSlaves       : AxiWriteSlaveArray (LANES_C downto 0) := (others=>AXI_WRITE_SLAVE_INIT_C);

  signal axilDone : sl;
  
begin

  U_DUT : entity work.AxiDataMover
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
             axilReadSlave    => axilReadSlave );

  process is
    axiClk <= '1';
    wait for 2.5 ns;
    axiClk <= '0';
    wait for 2.5 ns;
  end process;

  process is
    axiRst <= '1';
    wait for 20 ns;
    axiRst <= '0';
    wait;
  end process;
  
   process is
     procedure wreg(addr : integer; data : slv(31 downto 0)) is
     begin
       wait until axiClk='0';
       axilWriteMaster.awaddr  <= toSlv(addr,32);
       axilWriteMaster.awvalid <= '1';
       axilWriteMaster.wdata   <= data;
       axilWriteMaster.wvalid  <= '1';
       axilWriteMaster.bready  <= '1';
       wait until axiClk='1';
       wait until axilWriteSlave.bvalid='1';
       wait until axiClk='0';
       wait until axiClk='1';
       wait until axiClk='0';
       axilWriteMaster.awvalid <= '0';
       axilWriteMaster.wvalid  <= '0';
       axilWriteMaster.bready  <= '0';
       wait for 50 ns;
     end procedure;
  begin
    axilDone <= '0';
    wait until axiRst='0';
    wait for 1200 ns;
    wreg(16,x"00000000"); -- prescale
    wreg(20,x"00800004"); -- fexLength/Delay
    wreg(24,x"00040C00"); -- almostFull
    wreg(32,x"00000000"); -- prescale
    wreg(36,x"00800004"); -- fexLength/Delay
    wreg(40,x"00040C00"); -- almostFull
    wreg(256*2+16,x"00000040");
    wreg(256*2+24,x"000003c0");
    wreg(256*2+32,x"00000002");
    wreg(256*2+40,x"00000002");
    wreg( 0,x"00000003"); -- fexEnable
    wait for 600 ns;
    axilDone <= '1';
    wait;
  end process;
     
end architecture;

