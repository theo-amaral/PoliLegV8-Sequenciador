set_global_assignment -entity "ip_clock" -library "lib_ip_clock" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "ip_clock" -library "lib_ip_clock" -name IP_TOOL_VERSION "25.1"
set_global_assignment -entity "ip_clock" -library "lib_ip_clock" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_ip_clock" -name SPD_FILE [file join $::quartus(sip_path) "ip_clock.spd"]

set_global_assignment -library "lib_ip_clock" -name MISC_FILE [file join $::quartus(sip_path) "ip_clock_sim/ip_clock.vho"]
