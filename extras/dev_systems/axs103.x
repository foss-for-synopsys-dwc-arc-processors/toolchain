/* ARC AXS103 SDP */

MEMORY
{
    DRAM : ORIGIN = 0x80000000, LENGTH = 1024M
}

REGION_ALIAS("startup", DRAM)
REGION_ALIAS("text", DRAM)
REGION_ALIAS("data", DRAM)
REGION_ALIAS("sdata", DRAM)

PROVIDE (__stack_top = (0xBFFFFFFF & -4) );
PROVIDE (__end_heap = (0xBFFFFFFF) );
