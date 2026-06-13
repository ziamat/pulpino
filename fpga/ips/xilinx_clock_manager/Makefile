# Modified by Achmad Muhajir (22/500339/TK/54839)
PROJECT:=xilinx_clock_manager

all:
	vivado -mode batch -source tcl/run.tcl
	mkdir ip
	cp ${PROJECT}.runs/${PROJECT}_synth_1/${PROJECT}.dcp ip/
	cp ${PROJECT}.gen/sources_1/ip/${PROJECT}/${PROJECT}_stub.v ip/

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
