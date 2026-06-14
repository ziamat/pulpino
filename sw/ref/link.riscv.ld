/* not needed, but we need separate linker scripts anyway */
OUTPUT_ARCH(riscv)

/* required to correctly link newlib */
GROUP( -lgcc )

INCLUDE link.common.ld
