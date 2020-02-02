--------------------------------------------------------------------------
--
-- T80 wrapper directives
--
-- Directives for xilt to import T80 cpu core and suppress benign warnings.
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------


--xilt:require:./T80/T80.vhd
--xilt:require:./T80/T80_ALU.vhd
--xilt:require:./T80/T80_MCode.vhd
--xilt:require:./T80/T80_Pack.vhd
--xilt:require:./T80/T80_Reg.vhd
--xilt:require:./T80/T80se.vhd


--xilt:nowarn:WARNING:Par:288 - The signal cpu/u0/Regs/Mram_RegsL11_RAMD_D1_O has no load.  PAR will not attempt to route this signal.
--xilt:nowarn:WARNING:Par:288 - The signal cpu/u0/Regs/Mram_RegsH11_RAMD_D1_O has no load.  PAR will not attempt to route this signal.
--xilt:nowarn:WARNING:Par:283 - There are 2 loadless signals in this design. This design will cause Bitgen to issue DRC warnings.
--xilt:nowarn:WARNING:PhysDesignRules:367 - The signal <cpu/u0/Regs/Mram_RegsL11_RAMD_D1_O> is
--xilt:nowarn:WARNING:PhysDesignRules:367 - The signal <cpu/u0/Regs/Mram_RegsH11_RAMD_D1_O> is
 