# Modified by Achmad Muhajir (22/500339/TK/54839)
PROJECT:=xilinx_mem_8192x32

all:
	vivado -mode batch -source tcl/run.tcl
	mkdir ip
	cp ${PROJECT}.srcs/sources_1/ip/${PROJECT}/${PROJECT}.xci ./ip
	cp ${PROJECT}.gen/sources_1/ip/${PROJECT}/${PROJECT}_stub.v ./ip
	cp ${PROJECT}.gen/sources_1/ip/${PROJECT}/${PROJECT}.veo ./ip
	cp ${PROJECT}.gen/sources_1/ip/${PROJECT}/${PROJECT}.dcp ./ip

gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ip
	rm -rf ${PROJECT}.xpr
	rm -rf ${PROJECT}.hw
	rm -rf ${PROJECT}.runs
	rm -rf ${PROJECT}.srcs
	rm -rf ${PROJECT}.cache
	rm -rf vivado*.jou
	rm -rf vivado*.log
	rm -rf .Xil
	rm -rf ${PROJECT}.gen
	rm -rf ${PROJECT}.ip_user_files
	rm -rf dfx_runtime.txt
