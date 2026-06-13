# Modified by Achmad Muhajir (22/500339/TK/54839)

all: ips pulpino pulpemu
# sw is commented because it must be run on Linux (WSL) for toolchain dependency

.PHONY: ips
ips: clk mem fp_fma


.PHONY: clk
clk: ips/xilinx_clock_manager/ip/xilinx_clock_manager.dcp

ips/xilinx_clock_manager/ip/xilinx_clock_manager.dcp:
	make -C ips/xilinx_clock_manager/ all


.PHONY: mem
mem: ips/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp

ips/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp:
	make -C ips/xilinx_mem_8192x32/ all


.PHONY: mem_dp
mem_dp: ips/xilinx_mem_32768x32_dp/ip/xilinx_mem_32768x32_dp.dcp

ips/xilinx_mem_32768x32_dp/ip/xilinx_mem_32768x32_dp.dcp:
	make -C ips/xilinx_mem_32768x32_dp/ all

.PHONY: fp_fma
fp_fma: ips/xilinx_fp_fma/ip/xilinx_fp_fma.dcp

ips/xilinx_fp_fma/ip/xilinx_fp_fma.dcp:
	make -C ips/xilinx_fp_fma/ all

.PHONY: pulpino
pulpino: pulpino/pulpino.edf

pulpino/pulpino.edf:
	make -C pulpino all


.PHONY: pulpemu
pulpemu: pulpemu/pulpemu_top.bit

pulpemu/pulpemu_top.bit:
	make -C pulpemu all


#.PHONY: sw
#sw:
#	make -C sw all


.PHONY: clean
clean:
	make -C ips/xilinx_clock_manager/ clean
	make -C ips/xilinx_mem_8192x32/ clean
	make -C ips/xilinx_mem_32768x32_dp/ clean
	make -C ips/xilinx_fp_fma/ clean
	make -C pulpino clean
	make -C pulpemu clean
	make -C sw clean
