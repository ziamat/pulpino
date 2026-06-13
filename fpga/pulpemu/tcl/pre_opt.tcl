# pre_opt.tcl
# This script runs right before opt_design to resolve black boxes for Xilinx encrypted memory IPs.
# Because pulpino.edn was pre-synthesized, it contains the IP wrappers but leaves the encrypted cores as black boxes.
# This script replaces the EDIF wrappers with the actual .dcp files to restore the full IP hierarchy.
#
# NOTE: When this script runs as a pre-opt hook via launch_runs, the working directory
# is inside pulpemu.runs/impl_1/ and current_project may not be available.
# We must use absolute paths derived from the script's own location.

puts "====================================================================="
puts "pre_opt.tcl: Starting memory black box resolution"
puts "====================================================================="
puts "pre_opt.tcl: pwd = [pwd]"
puts "pre_opt.tcl: info script = [info script]"

# --- Strategy 1: Derive path from the script's own location ---
# This script lives at: <pulpemu>/tcl/pre_opt.tcl
# IPs live at:          <pulpemu>/../ips
set script_dir [file dirname [file normalize [info script]]]
set project_base [file dirname $script_dir]
set ips_dir [file normalize "$project_base/../ips"]

puts "pre_opt.tcl: script_dir   = $script_dir"
puts "pre_opt.tcl: project_base = $project_base"
puts "pre_opt.tcl: ips_dir      = $ips_dir"

# Primary DCP location: <ips>/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp
set dcp_path [file normalize "$ips_dir/xilinx_mem_8192x32/ip/xilinx_mem_8192x32.dcp"]

puts "pre_opt.tcl: Primary DCP path = $dcp_path"
puts "pre_opt.tcl: File exists = [file exists $dcp_path]"

# --- Strategy 2: Fallback paths if primary doesn't exist ---
if {![file exists $dcp_path]} {
    puts "pre_opt.tcl: Primary DCP not found, trying fallback paths..."
    
    # Try from the generated sources
    set fallback_paths [list \
        [file normalize "$ips_dir/xilinx_mem_8192x32/xilinx_mem_8192x32.gen/sources_1/ip/xilinx_mem_8192x32/xilinx_mem_8192x32.dcp"] \
        [file normalize "$ips_dir/xilinx_mem_8192x32/xilinx_mem_8192x32.runs/xilinx_mem_8192x32_synth_1/xilinx_mem_8192x32.dcp"] \
    ]
    
    # Also try glob
    set glob_dcps [glob -nocomplain $ips_dir/xilinx_mem_*/ip/*.dcp]
    foreach g $glob_dcps {
        lappend fallback_paths $g
    }
    set glob_dcps2 [glob -nocomplain $ips_dir/xilinx_mem_*/*.runs/*/xilinx_mem_*.dcp]
    foreach g $glob_dcps2 {
        lappend fallback_paths $g
    }
    
    foreach fb $fallback_paths {
        puts "pre_opt.tcl: Trying fallback: $fb (exists=[file exists $fb])"
        if {[file exists $fb]} {
            set dcp_path $fb
            puts "pre_opt.tcl: Using fallback DCP: $dcp_path"
            break
        }
    }
}

# --- Resolve the black boxes ---
set mem_cells [list \
    "pulpino_wrap_i/pulpino_i/core_region_i/data_mem/sp_ram_i" \
    "pulpino_wrap_i/pulpino_i/core_region_i/instr_mem/sp_ram_wrap_i/sp_ram_i" \
]

set resolved 0

if {[file exists $dcp_path]} {
    puts "pre_opt.tcl: DCP file confirmed: $dcp_path ([file size $dcp_path] bytes)"
    
    foreach cell $mem_cells {
        puts "pre_opt.tcl: Attempting to resolve: $cell"
        if {[catch {read_checkpoint -cell $cell $dcp_path} msg]} {
            puts "pre_opt.tcl: FAILED to read checkpoint for $cell"
            puts "pre_opt.tcl: Error message: $msg"
        } else {
            puts "pre_opt.tcl: SUCCESS - resolved $cell"
            incr resolved
        }
    }
} else {
    puts "pre_opt.tcl: CRITICAL ERROR - No DCP file found!"
    puts "pre_opt.tcl: Expected: $dcp_path"
    puts "pre_opt.tcl: Please regenerate the xilinx_mem_8192x32 IP:"
    puts "pre_opt.tcl:   cd fpga/ips/xilinx_mem_8192x32 && make"
}

puts "====================================================================="
puts "pre_opt.tcl: Resolved $resolved of [llength $mem_cells] memory black boxes"

# Verify by checking remaining black boxes
if {[catch {set bb_cells [get_cells -quiet -hierarchical -filter {IS_BLACKBOX == 1}]} ]} {
    set bb_cells {}
}
if {[llength $bb_cells] > 0} {
    puts "pre_opt.tcl: WARNING - Remaining unresolved black boxes:"
    foreach bb $bb_cells {
        catch {
            puts "  - $bb (type: [get_property REF_NAME $bb])"
        }
    }
} else {
    puts "pre_opt.tcl: All black boxes resolved successfully!"
}
puts "====================================================================="

# -----------------------------------------------------------------------
# Fix Route 35-19 / REQP-127: Fix OBUFs from pulpino.edn
# -----------------------------------------------------------------------
# Problem: pulpino.edn has OBUFs on its output ports. In pulpemu_top,
# some OBUF outputs drive BOTH a top-level port AND internal PS7 logic.
# An OBUF at an IOB site can only drive the external pad, not internal
# fabric. We must move internal loads from OBUF output to OBUF input.
puts "====================================================================="
puts "pre_opt.tcl: Fixing OBUFs/IBUFs from pulpino pre-synthesized netlist..."

# --- Fix OBUFs: move internal loads to pre-buffer signal ---
set obuf_cells [get_cells -quiet -hierarchical -filter {REF_NAME == OBUF && NAME =~ "pulpino_wrap_i/*"}]
set obuf_fixed 0
set obuf_removed 0
puts "pre_opt.tcl: Found [llength $obuf_cells] OBUF(s) in pulpino_wrap_i"

foreach obuf $obuf_cells {
    if {[catch {
        set o_pin [get_pins -quiet $obuf/O]
        set i_pin [get_pins -quiet $obuf/I]
        if {[llength $o_pin] == 0 || [llength $i_pin] == 0} { error "missing pins" }

        set o_net [get_nets -quiet -of_objects $o_pin]
        set i_net [get_nets -quiet -of_objects $i_pin]
        if {[llength $o_net] == 0 || [llength $i_net] == 0} { error "missing nets" }

        # Check what the OBUF output drives
        set ext_ports [get_ports -quiet -of_objects $o_net]

        # Use -leaf to find actual register/LUT input pins (not hierarchical ports)
        set leaf_pins [get_pins -quiet -leaf -of_objects $o_net]
        set internal_loads {}
        foreach p $leaf_pins {
            set pdir [get_property -quiet DIRECTION $p]
            set pcell [get_property -quiet PARENT_CELL $p]
            if {$pdir eq "IN" && $pcell ne $obuf} {
                lappend internal_loads $p
            }
        }
        # Also check non-leaf pins
        set all_pins [get_pins -quiet -of_objects $o_net]
        foreach p $all_pins {
            set pdir [get_property -quiet DIRECTION $p]
            set pcell [get_property -quiet PARENT_CELL $p]
            if {$pdir eq "IN" && $pcell ne $obuf && $p ni $internal_loads} {
                lappend internal_loads $p
            }
        }

        # Aggressively remove the pre-synthesized OBUF and let opt_design infer a fresh top-level one
        puts "  Removing OBUF and merging nets: $obuf"
        
        # 1. Move all internal loads
        foreach lp $internal_loads {
            disconnect_net -quiet -net $o_net -objects $lp
            connect_net -quiet -net $i_net -objects $lp
        }
        
        # 2. Move external ports
        foreach port $ext_ports {
            disconnect_net -quiet -net $o_net -objects $port
            connect_net -quiet -net $i_net -objects $port
        }
        
        # 3. Disconnect OBUF pins and remove cell
        disconnect_net -quiet -net $o_net -objects $o_pin
        disconnect_net -quiet -net $i_net -objects $i_pin
        remove_cell -quiet $obuf
        incr obuf_removed
    } msg]} {
        puts "  WARNING: Failed to process OBUF $obuf: $msg"
    }
}
puts "pre_opt.tcl: Fixed $obuf_fixed OBUF(s), removed $obuf_removed OBUF(s)"

# --- Fix IBUFs: move internal drivers to post-buffer signal ---
set ibuf_cells [get_cells -quiet -hierarchical -filter {REF_NAME == IBUF && NAME =~ "pulpino_wrap_i/*"}]
set ibuf_fixed 0
set ibuf_removed 0
puts "pre_opt.tcl: Found [llength $ibuf_cells] IBUF(s) in pulpino_wrap_i"

foreach ibuf $ibuf_cells {
    if {[catch {
        set i_pin [get_pins -quiet $ibuf/I]
        set o_pin [get_pins -quiet $ibuf/O]
        if {[llength $i_pin] == 0 || [llength $o_pin] == 0} { error "missing pins" }

        set i_net [get_nets -quiet -of_objects $i_pin]
        set o_net [get_nets -quiet -of_objects $o_pin]
        if {[llength $i_net] == 0 || [llength $o_net] == 0} { error "missing nets" }

        set ext_ports [get_ports -quiet -of_objects $i_net]

        if {[llength $ext_ports] == 0} {
            # IBUF not driven by a top-level port - remove it
            puts "  Removing IBUF (internal only): $ibuf"
            set load_pins [get_pins -quiet -leaf -of_objects $o_net -filter {DIRECTION == IN}]
            disconnect_net -quiet -net $i_net -objects $i_pin
            disconnect_net -quiet -net $o_net -objects $o_pin
            foreach lp $load_pins {
                disconnect_net -quiet -net $o_net -objects $lp
                connect_net -quiet -net $i_net -objects $lp
            }
            remove_cell -quiet $ibuf
            incr ibuf_removed
        }
    } msg]} {
        puts "  WARNING: Failed to process IBUF $ibuf: $msg"
    }
}
puts "pre_opt.tcl: Removed $ibuf_removed redundant IBUF(s)"
puts "pre_opt.tcl: Summary: $obuf_fixed OBUF fixed, $obuf_removed OBUF removed, $ibuf_removed IBUF removed"
puts "====================================================================="

