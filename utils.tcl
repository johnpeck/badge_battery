namespace eval utils {

    variable seconds_per_day 86400

    proc add_section_header {section_name} {
	set dashes "-"
	while {(2*[string length $dashes] + [string length $section_name]) < 66} {
	    append dashes "-"
	}
	set dash_string "$dashes $section_name $dashes"
	puts ""
	puts $dash_string
	puts ""
    }

}
