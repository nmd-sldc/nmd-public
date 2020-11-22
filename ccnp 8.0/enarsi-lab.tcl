# Title: CCNP ENARSI lab scenario loader
# Purpose: This file is used to quickly load pre-staged configuration files for CCNP ENARSI lab scenarios.
# Usage: Run this script using the following syntax tclsh ts.tcl {Device Name} {Lab Number} [Trouble Ticket Letter] [Custom Filename]
#        This script is designed to run on physical equipment inside an environment with pre-configured management IP addresses.


# Initialize variables globally to simplify proc variable declaration
set version_number "1.1"
set device_type "Unknown"
set device_name "Unknown"
set lab_number "Unknown"
set ticket_letter "Unknown"
set config_directory "flash:/ccnp/enarsi/"
set config_filename "Unknown"
set config_fq_filename "Unknown"
set file_ops "Unknown"
set access_switch_platforms "C2960|C2960X"
set distro_switch_platforms "C3650|C3750V2"
set router_platforms "CISCO2901|Cisco ISR4331"
set script_filename [info script]

#Retrieve classroom device list and store the contents of this file in a new array
set infile [open dev_list.txt]; 
set dev_list_content [read $infile]; 
array set device_id_array $dev_list_content;

# Search the array using device serials and store the IP address
proc get_ip {} {
	global device_id_array device_mgmt_ip; #establish global variables
	catch {set device_serial [exec "show version | inc board ID"]}; #run sh 
	regsub "Processor" $device_serial "" device_serial
	regsub "board" $device_serial "" device_serial
	regsub "ID" $device_serial "" device_serial
	set device_serial [regexp -inline {[A-Z|0-9]{3,}} $device_serial]
	catch {set var $device_id_array($device_serial)}
	catch {set device_mgmt_ip [lindex $var 0]}
}

# Search the array using device serials and store the device name
proc get_hostname {} {
  global device_id_array device_name
  catch {set device_serial [exec "show version | inc board ID"]}
  regsub "Processor" $device_serial "" device_serial
  regsub "board" $device_serial "" device_serial
  regsub "ID" $device_serial "" device_serial
  set device_serial [regexp -inline {[A-Z|0-9]{3,}} $device_serial]
  catch {set var $device_id_array($device_serial)}
  catch {set device_name [lindex $var 1]}
}

proc show_help {} {
  global version_number
  puts "----------------------------------------"
  puts "CCNP ENARSI Scenario Loader Version $version_number"
  puts "Author: CW4 Brandon M. Wilson"
  puts "----------------------------------------"
  show_syntax
}

proc show_syntax {} {
  global script_filename
  puts "SYNTAX: tclsh $script_filename {Device Name} {Lab Number} \[Custom Filename\]"
  puts "ALT SYNTAX: tclsh $script_filename {next|previous}"
  puts "***Only the optional filename parameter is case sensitive***"
  puts "EXAMPLES:"
  puts "      tclsh $script_filename r1 x.x.x.x"
  puts "      tclsh $script_filename next"
  puts "      tclsh $script_filename previous"
  puts "      tclsh $script_filename r1 x.x.x.x base.r1-config.txt"  
}

proc show_invalid_arguments {} {
  puts "***Invalid arguments***"
  show_syntax
}

proc parse_arguments {} {
#Parse and provided arguements, ensure all user inputs are converted to uppercase and assigned to named variables
}

# Set platform type
proc set_platform_type {} {
  global device_type access_switch_platforms distro_switch_platforms router_platforms
  set device_inventory [exec "show inventory"]
  if {[regexp "$router_platforms" $device_inventory] == 1} {
    set device_type "Router"
  } elseif {[regexp "$access_switch_platforms" $device_inventory] == 1} {
    set device_type "AccessSwitch"
  } elseif {[regexp "$distro_switch_platforms" $device_inventory] == 1} {
    set device_type "DistroSwitch"
  } else { set device_type "Unknown"}
}

# Set device type to lowercase
proc set_device_name {dn} {
  global device_name
  set device_name [string tolower $dn]
}

# Set lab type to lowercase
proc set_lab_number {ln} {
  global lab_number
  set lab_number [string tolower $ln]  
}

# Set filename
proc set_filename {cf} {
  global config_directory config_filename config_fq_filename lab_number device_name ticket_letter
  set config_filename $cf
  set config_directory "$config_directory/$device_name/"
  set config_fq_filename "$config_directory$config_filename"
}

# Set device type

proc next_ticket {} {
  global device_type device_name lab_number ticket_letter config_directory config_filename config_fq_filename script_filename
  
  # Read current motd banner
  set current_banner_string [exec "show running-config | include banner motd"]

  #Verify motd banner is set and not blank
  if {$current_banner_string == ""} {
    puts "Banner not set. Unable to determine current Lab Number."
    exit_notify
  } else {

    #Extract hostname from current motd banner
    set current_device_name [regex -inline -nocase {[a-z]*\d} $current_hostname_string]
    set current_device_name [string tolower $current_device_name]
    
    #Extract lab number from current motd banner
    set current_lab_number [regex - inline {\d*[.]\d} $current_banner_string]
    
    #Increment Lab number by 1
    #
    incr $current_lab_number
    

    puts "***************************"
    puts "Detected Parameters:"
    puts "***************************"
    puts "Device Name: $current_device_name"
    puts "Banner String: $current_banner_string"
    puts "Lab Number: $current_lab_number"
    puts "***************************"

    set device_name $current_device_name
    set lab_number $current_lab_number
    
    set config_directory "flash:ccnp/enarsi/$device_name/"
    set config_filename "$lab_number-$device_name-config.txt"
    set config_fq_filename "$config_directory$config_filename"
  } 
  
  if [validate_config] {configure_device} else {exit_notify}

} 

proc previous_ticket {} {
  global device_type device_name lab_number ticket_letter config_directory config_filename config_fq_filename script_filename
  set current_banner_string [exec "show running-config | include banner motd"]

  #Verify motd banner is set and not blank
  if {$current_banner_string == ""} {
    puts "No banner set. Unable to determine current Lab Number and Ticket Letter."
    exit_notify
  } else {

    #Extract hostname from current motd banner
    set current_device_name [regex -nocase -inline {[a-z]*\d} $current_hostname_string]
    set current_device_name [string tolower $current_device_name]
    
    #Extract lab number from current motd banner
    set current_lab_number [regex -inline {\d*[.]\d} $current_banner_string]
    
    #Decremenent Lab number by 1
    set current_lab_number $current_lab_number - 1
    
    #Extract lab number from current motd banner
    set current_lab_number [regex current_banner_string]

    puts "***************************"
    puts "Detected Parameters:"
    puts "***************************"
    puts "Device Name: $current_device_name"
    puts "Banner String: $current_banner_string"
    puts "Lab Number: $current_lab_number"
    puts "***************************"

    set device_name $current_device_name
    set lab_number $current_lab_number

    set config_directory "flash:/ccnp/enarsi/$device_name/"
    set config_filename "$lab_number-$device_name-config.txt"
    set config_fq_filename "$config_directory$config_filename"
  } 
  
  if [validate_config] {configure_device} else {exit_notify}

}

proc validate_config {} {
  global device_type device_name lab_number config_directory config_filename config_fq_filename script_filename
# Provide user the opportunity to validate parsed parameters
  puts "Device Type Detected: $device_type"
  puts "New Hostname: $device_name"
  puts "New Lab Number: $lab_number"
  puts "Config Directory: $config_directory"
  puts "Config File: $config_filename"
  puts -nonewline "Is this information correct? \[yes\]:"
  flush stdout
  set input [string tolower [gets stdin]]
  if {$input == "yes" || $input == "y" || $input == ""} {
    set response 1
  } else {
    set response 0
  }
  return $response
}

proc configure_device {} {
  global device_type config_fq_filename config_directory script_filename device_mgmt_ip
  if {[file exists $config_fq_filename]==1} {
    switch $device_type {
      "AccessSwitch" {
		get_ip
        puts "Initializing as access switch..."
        typeahead "\n"
        delete /force vlan.dat
        delete /force multiple-fs
        ios_config "sdm prefer lanbase-routing"
        puts "Applying  $config_fq_filename to startup-config"
		set file_ops [open "$config_fq_filename" r]
		set file_data [read $file_ops]
		close $file_ops
		regsub "abracadabra" $file_data "$device_mgmt_ip" file_data
		set temp_file [open "flash:/temp_file.cfg" w+]
		puts $temp_file $file_data
		close $temp_file
        exec "copy flash:/temp_file.cfg startup-config"
        puts "\r\n"
		puts "\r"
		typeahead "\r\n"
		exec "delete flash:/temp_file.cfg"
		puts "\r"
		puts "\r"
        puts "Reloading the switch in 1 minute, type 'reload cancel' to halt"
        typeahead "\r\n"
		reload in 1
      }
      "DistroSwitch" {
		get_ip
		puts "$device_mgmt_ip"
        puts "Initializing as distribution switch..."
        typeahead "\n"
        delete /force vlan.dat
        delete /force multiple-fs
        ios_config "sdm prefer advanced"
        puts "Applying  $config_fq_filename to startup-config"
		set file_ops [open "$config_fq_filename" r]
		set file_data [read $file_ops]
		close $file_ops
		regsub "abracadabra" $file_data "$device_mgmt_ip" file_data
		set temp_file [open "flash:/temp_file.cfg" w+]
		puts $temp_file $file_data
		close $temp_file
        exec "copy flash:/temp_file.cfg startup-config"
        puts "\r\n"
		puts "\r"
		typeahead "\r\n"
		exec "delete flash:/temp_file.cfg"
		puts "\r"
		puts "\r"
        puts "Reloading the switch in 1 minute, type 'reload cancel' to halt"
        typeahead "\r\n"
		reload in 1
      } 
      "Router" {
		get_ip
        puts "Initializing router..."
        puts "Applying  $config_fq_filename to startup-config"
		set file_ops [open "$config_fq_filename" r]
		set file_data [read $file_ops]
		close $file_ops
		regsub "abracadabra" $file_data "$device_mgmt_ip" file_data
		set temp_file [open "flash:/temp_file.cfg" w+]
		puts $temp_file $file_data
		close $temp_file
        exec "copy flash:/temp_file.cfg startup-config"
        puts "\r\n"
		puts "\r"
		typeahead "\r\n"
		exec "delete flash:/temp_file.cfg"
		puts "\r"
		puts "\r"
        puts "Reloading the router in 1 minute, type 'reload cancel' to halt"
        typeahead "\r\n"
        reload in 1
      }
      default {puts "No initialization performed, device type not recognized"}
    }
  } else { 
    puts "\n"
    puts "************************************************************"
    puts "Invalid filename: $config_fq_filename"
    puts "************************************************************"
    puts "\n"
    puts "Verify filename with \'dir $config_directory\'"
    puts "For non-standard filenames use:"
    puts "\'tclsh $script_filename {Device Name} {Lab #} \[Custom Filename\]\'"
    exit_notify
  }
}

proc exit_notify {} {
  puts "Exiting..."
  #exit
}

set_platform_type

switch $::argc {
  0 {show_help}
  1 {
      switch [lindex $::argv 0] {
      "next" { 
        next_ticket 
      }
      "previous" { 
        previous_ticket
      }
      "?" {show_help}
      "help" {show_help}
      default {show_invalid_arguments}
      }
    }
  2 {
      set_device_name [lindex $::argv 0] 
      set_lab_number [lindex $::argv 1]
      set_filename "$lab_number-$device_name-config.txt"
      if [validate_config] {configure_device} else {exit_notify}
    } 
  3 {
      set_device_name [lindex $::argv 0] 
      set_lab_number [lindex $::argv 1]
      set_filename [lindex $::argv 2]
      if [validate_config] {configure_device} else {exit_notify}
    }

  default {show_invalid_arguments}
}
Tclquit
!
