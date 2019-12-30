--------------------------------------------------------------------------
--
-- SuppressBenignWarnings
--
-- Directives for xilt to suppress common benign warnings
--
-- Copyright (C) 2019 Topten Software.  All Rights Reserved.
--
--------------------------------------------------------------------------

-- Input <X> is never used. This port will be preserved and left unconnected if it 
-- belongs to a top-level block or it belongs to a sub-block and the hierarchy of this 
-- sub-block is preserved.
--xilt:nowarn:~^WARNING:Xst:647

-- FF/Latch <X> (without init value) has a constant value of <Y> in block <Z>. 
-- This FF/Latch will be trimmed during the optimization process.
--xilt:nowarn:~^WARNING:Xst:1710

-- Due to other FF/Latch trimming, FF/Latch <X> (without init value) has a constant
-- value of Y in block <Z>. This FF/Latch will be trimmed during the optimization process.
--xilt:nowarn:~^WARNING:Xst:1895

-- FFs/Latches <o_sd_op_cmd<1:1>> (without init value) have a constant value of <X> in 
-- block <Y>.
--xilt:nowarn:~^WARNING:Xst:2404

-- Node <X> of sequential type is unconnected in block <Y>.
--xilt:nowarn:~^WARNING:Xst:2677

-- WARNING:PhysDesignRules:2410 - This design is using one or more 9K Block RAMs
--   (RAMB8BWER).  9K Block RAM initialization data, both user defined and
--   default, may be incorrect and should not be used.  For more information,
--   please reference Xilinx Answer Record 39999.
--xilt:nowarn:~^WARNING:PhysDesignRules:2410
