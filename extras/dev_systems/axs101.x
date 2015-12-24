/* ARC AXS101 SDP */

MEMORY
{
    DRAM : ORIGIN = 0x80000000, LENGTH = 512M
}

REGION_ALIAS("startup", DRAM)
REGION_ALIAS("text", DRAM)
REGION_ALIAS("data", DRAM)
REGION_ALIAS("sdata", DRAM)

PROVIDE (__stack_top = (0x9FFFFFFF & -4) );
PROVIDE (__end_heap = (0x9FFFFFFF) );
