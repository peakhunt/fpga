
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name mojo_blink -dir "/home/hawk/sandbox/fpga/mojo_blink/planAhead_run_3" -part xc6slx4tqg144-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/hawk/sandbox/fpga/mojo_blink/mojo_blink_top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/hawk/sandbox/fpga/mojo_blink} }
set_property target_constrs_file "mojo_blink.ucf" [current_fileset -constrset]
add_files [list {mojo_blink.ucf}] -fileset [get_property constrset [current_run]]
link_design
