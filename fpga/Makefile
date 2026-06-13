# Modified by Achmad Muhajir (22/500339/TK/54839)
NAME:=RISCY
PROJECT:=pulpino

all:
	vivado -mode batch -source tcl/run.tcl
# ./postsynth_names.py

gui:
	vivado -mode gui -source tcl/run.tcl &

clean:
	rm -rf ${PROJECT}.xpr
	rm -rf ${PROJECT}.data
	rm -rf ${PROJECT}.runs
	rm -rf ${PROJECT}.srcs
	rm -rf ${PROJECT}.sim
	rm -rf ${PROJECT}.cache
	rm -rf ${PROJECT}.ioplanning
	rm -rf ${PROJECT}.hw
	rm -rf component.xml
	rm -rf vivado*
	rm -rf .Xil
	rm -rf xgui
	rm -rf *.edn
	rm -rf reports*
	rm -rf ${PROJECT}_stub.v
	rm -rf ${PROJECT}_funcsim.v
	rm -rf ${PROJECT}.gen
	rm -rf ${PROJECT}.ip_user_files
	rm -rf dfx_runtime.txt
