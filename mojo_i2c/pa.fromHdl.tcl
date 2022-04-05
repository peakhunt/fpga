
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name mojo_i2c -dir "/home/hawk/sandbox/fpga/mojo_i2c/planAhead_run_1" -part xc6slx9tqg144-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "mojo_top.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {led_controller.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {i2c_slave.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {mojo_top.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top mojo_top $srcset
add_files [list {mojo_top.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9tqg144-2
