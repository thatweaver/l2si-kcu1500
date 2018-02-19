-------------------------------------------------------------------------------
-- File       : AxiWriteSlaveSim.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-03-06
-- Last update: 2018-01-29
-------------------------------------------------------------------------------
-- Description: Wrapper for Xilinx Axi Data Mover
-- Axi stream input (dscWriteMasters.command) launches an AxiWriteMaster to
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

entity AxiWriteSlaveSim is
   port    ( -- Clock and reset
             axiClk           : in  sl; -- 200MHz
             axiRst           : in  sl; -- need a user reset to clear the pipeline
             -- AXI4 Interface
             axiWriteMaster    : in  AxiWriteMasterType;
             axiWriteSlave     : out AxiWriteSlaveType );
end AxiWriteSlaveSim;

architecture mapping of AxiWriteSlaveSim is

  type RegType is record
    slave  : AxiWriteSlaveType;
    bvalid : sl;
  end record;

  constant REG_INIT_C : RegType := (
    slave  => AXI_WRITE_SLAVE_INIT_C,
    bvalid => '0' );

  signal r   : RegType;
  signal rin : RegType := REG_INIT_C;
  
begin

  axiWriteSlave <= rin.slave;
  
  comb : process ( axiRst, r, axiWriteMaster ) is
    variable v : RegType;
  begin
    v := r;

    v.slave.awready := '0';
    v.slave.wready  := '0';

    if axiWriteMaster.awvalid = '1' then
      v.slave.awready := '1';
    end if;
    
    if axiWriteMaster.wvalid = '1' then
      v.slave.wready := '1';
      if axiWriteMaster.wlast = '1' then
        v.bvalid := '1';
      end if;
    end if;

    v.slave.bvalid := r.bvalid;
    
    if r.slave.bvalid = '1' and axiWriteMaster.bready = '1' then
      v.slave.bvalid := '0';
      v.bvalid       := '0';
    end if;

    if axiRst = '1' then
      v := REG_INIT_C;
    end if;

    rin <= v;
  end process comb;

  seq : process (axiClk) is
  begin
    if rising_edge(axiClk) then
      r <= rin;
    end if;
  end process seq;
  
end mapping;
