set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[0]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[1]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[2]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}]
set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[3]}] \
                 -group [get_clocks -include_generated_clocks {pciRefClkP}] \
                 -group [get_clocks -include_generated_clocks {pciExtRefClkP}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[0]}] \
                 -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[1]}] \
                 -group [get_clocks -include_generated_clocks {qsfp0RefClkP0}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[2]}] \
                 -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]

set_clock_groups -asynchronous \
                 -group [get_clocks -include_generated_clocks {ddrClkP[3]}] \
                 -group [get_clocks -include_generated_clocks {qsfp1RefClkP0}]

