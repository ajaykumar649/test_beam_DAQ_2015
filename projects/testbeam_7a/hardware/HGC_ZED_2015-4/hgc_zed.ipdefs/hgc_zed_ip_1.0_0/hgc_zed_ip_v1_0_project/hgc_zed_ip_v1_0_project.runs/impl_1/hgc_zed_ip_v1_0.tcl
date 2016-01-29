proc start_step { step } {
  set stopFile ".stop.rst"
  if {[file isfile .stop.rst]} {
    puts ""
    puts "*** Halting run - EA reset detected ***"
    puts ""
    puts ""
    return -code error
  }
  set beginFile ".$step.begin.rst"
  set platform "$::tcl_platform(platform)"
  set user "$::tcl_platform(user)"
  set pid [pid]
  set host ""
  if { [string equal $platform unix] } {
    if { [info exist ::env(HOSTNAME)] } {
      set host $::env(HOSTNAME)
    }
  } else {
    if { [info exist ::env(COMPUTERNAME)] } {
      set host $::env(COMPUTERNAME)
    }
  }
  set ch [open $beginFile w]
  puts $ch "<?xml version=\"1.0\"?>"
  puts $ch "<ProcessHandle Version=\"1\" Minor=\"0\">"
  puts $ch "    <Process Command=\".planAhead.\" Owner=\"$user\" Host=\"$host\" Pid=\"$pid\">"
  puts $ch "    </Process>"
  puts $ch "</ProcessHandle>"
  close $ch
}

proc end_step { step } {
  set endFile ".$step.end.rst"
  set ch [open $endFile w]
  close $ch
}

proc step_failed { step } {
  set endFile ".$step.error.rst"
  set ch [open $endFile w]
  close $ch
}

set_msg_config -id {Common 17-41} -limit 10000000
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000

start_step init_design
set rc [catch {
  create_msg_db init_design.pb
  set_property design_mode GateLvl [current_fileset]
  set_property webtalk.parent_dir /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.cache/wt [current_project]
  set_property parent.project_path /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.xpr [current_project]
  set_property ip_repo_paths {
  /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.cache/ip
  /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0
  /home/jlow/Work/Vivado/Cristian/CodeLib/VHDLCodeLib/Vivado142/CodeLib/prepdiscr
  /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0
  /home/jlow/Work/Vivado/Cristian/CodeLib/VHDLCodeLib/Vivado142/CodeLib/prepdiscr
} [current_project]
  set_property ip_output_repo /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.cache/ip [current_project]
  add_files -quiet /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.runs/synth_1/hgc_zed_ip_v1_0.dcp
  add_files -quiet /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.runs/tdpram_32x256_synth_1/tdpram_32x256.dcp
  set_property netlist_only true [get_files /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.runs/tdpram_32x256_synth_1/tdpram_32x256.dcp]
  read_xdc -mode out_of_context -ref tdpram_32x256 -cells U0 /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.srcs/sources_1/ip/tdpram_32x256/tdpram_32x256_ooc.xdc
  set_property processing_order EARLY [get_files /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.srcs/sources_1/ip/tdpram_32x256/tdpram_32x256_ooc.xdc]
  read_xdc /home/jlow/Work/Vivado/testbeam_7a/HGC_ZED_0/ip_repo/hgc_zed_ip_1.0/hgc_zed_ip_v1_0_project/hgc_zed_ip_v1_0_project.srcs/constrs_1/new/hgc_zed_ip.xdc
  link_design -top hgc_zed_ip_v1_0 -part xc7z020clg484-1
  close_msg_db -file init_design.pb
} RESULT]
if {$rc} {
  step_failed init_design
  return -code error $RESULT
} else {
  end_step init_design
}

start_step opt_design
set rc [catch {
  create_msg_db opt_design.pb
  catch {write_debug_probes -quiet -force debug_nets}
  opt_design 
  write_checkpoint -force hgc_zed_ip_v1_0_opt.dcp
  report_drc -file hgc_zed_ip_v1_0_drc_opted.rpt
  close_msg_db -file opt_design.pb
} RESULT]
if {$rc} {
  step_failed opt_design
  return -code error $RESULT
} else {
  end_step opt_design
}

start_step place_design
set rc [catch {
  create_msg_db place_design.pb
  catch {write_hwdef -file hgc_zed_ip_v1_0.hwdef}
  place_design 
  write_checkpoint -force hgc_zed_ip_v1_0_placed.dcp
  report_io -file hgc_zed_ip_v1_0_io_placed.rpt
  report_utilization -file hgc_zed_ip_v1_0_utilization_placed.rpt -pb hgc_zed_ip_v1_0_utilization_placed.pb
  report_control_sets -verbose -file hgc_zed_ip_v1_0_control_sets_placed.rpt
  close_msg_db -file place_design.pb
} RESULT]
if {$rc} {
  step_failed place_design
  return -code error $RESULT
} else {
  end_step place_design
}

start_step route_design
set rc [catch {
  create_msg_db route_design.pb
  route_design 
  write_checkpoint -force hgc_zed_ip_v1_0_routed.dcp
  report_drc -file hgc_zed_ip_v1_0_drc_routed.rpt -pb hgc_zed_ip_v1_0_drc_routed.pb
  report_timing_summary -warn_on_violation -max_paths 10 -file hgc_zed_ip_v1_0_timing_summary_routed.rpt -rpx hgc_zed_ip_v1_0_timing_summary_routed.rpx
  report_power -file hgc_zed_ip_v1_0_power_routed.rpt -pb hgc_zed_ip_v1_0_power_summary_routed.pb
  report_route_status -file hgc_zed_ip_v1_0_route_status.rpt -pb hgc_zed_ip_v1_0_route_status.pb
  report_clock_utilization -file hgc_zed_ip_v1_0_clock_utilization_routed.rpt
  close_msg_db -file route_design.pb
} RESULT]
if {$rc} {
  step_failed route_design
  return -code error $RESULT
} else {
  end_step route_design
}

