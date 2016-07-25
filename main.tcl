# Battery calculations for the badge

source utils.tcl

# ----------------------------- Battery -------------------------------

# Rated battery capacity (mAh)
#
# This is the number you'll read off the package, or from a datasheet.
# The badge uses two CR2430 3.3V Lithium button cells with the
# Novacell brand.  They have a nominal capacity of 290mAh each.
set rated_battery_capacity_mah 290

# The number of cells (batteries)
set cell_number 2

# Discharge curve factor (dimensionless)
#
# This is a number between 0 and 1 describing how battery capacity
# maps to battery energy.  It describes the area under the voltage vs
# expended charge curve.
#
# Lithium batteries maintain the same voltage for most of their lives,
# making this area look like a rectangle.  The curve factor here would
# be close to 1.
#
# Alkaline Manganese Dioxide batteries have a nominally linear
# discharge curve, making their curve factor closer to 0.5.
set discharge_curve_factor 0.75

# Fresh battery voltage (Volts)
set fresh_voltage 3

# Dead voltage (Volts).  The battery reaches this voltage after
# expending its rated capacity.
set dead_voltage 2

# 1 mAh = 3.6 C
set rated_battery_capacity_c [expr $rated_battery_capacity_mah * 3.6]

# The battery energy is the area under the voltage vs expended charge
# curve.  Batteries have a minimum usable voltage, so the area under
# this curve will look like some shape on top of a rectangle.
set battery_energy [expr $cell_number * ($dead_voltage * $rated_battery_capacity_c + \
			  ($fresh_voltage - $dead_voltage) * $discharge_curve_factor * \
					       $rated_battery_capacity_c)]

# The average battery voltage is the total energy divided by the total
# expended charge.  Our batteries are in parallel, so the charge
# expended will be twice the capacity of a single cell.
set average_battery_voltage [expr $battery_energy / ($cell_number * $rated_battery_capacity_c)]


utils::add_section_header "Battery and regulator"

set data "Each cell contributes [format {%0.0f} [expr $battery_energy / $cell_number]] joules, "
append data "sourcing [format {%0.0f} $rated_battery_capacity_c] coulombs "
append data "([format {%0.0f} $rated_battery_capacity_mah] mAh)."
puts $data

puts "Total battery energy is [format {%0.0f} $battery_energy] joules from $cell_number cells."

set data "Batteries drain from [format {%0.1f} $fresh_voltage] volts to "
append data "[format {%0.1f} $dead_voltage] volts with a shape factor of "
append data "[format {%0.1f} $discharge_curve_factor]."
puts $data

set data "Average battery voltage for $cell_number cells in parallel is "
append data "[format {%0.2f} $average_battery_voltage] volts."
puts $data


# ----------------------------- Radio --------------------------------- 

# Radio current expended constantly (A)
set radio_static_current 0.00002

# Radio current expended during a ping (A)
set radio_ping_current 0.004

# Radio ping frequency (Hz)
set radio_ping_frequency 3.5

# Time spent in a ping (seconds)
set radio_ping_time 0.001

# Energy expended by the radio during pings
set daily_radio_ping_energy [expr $utils::seconds_per_day * $radio_ping_frequency *\
				     $radio_ping_current * $radio_ping_time * $average_battery_voltage]

set daily_radio_static_energy [expr $utils::seconds_per_day * $radio_static_current * $average_battery_voltage]

utils::add_section_header "Radio"

set data "Daily radio static energy is [format {%0.0f} $daily_radio_static_energy] joules, "
append data "drawing [format {%0.0f} [expr $radio_static_current * 1e6]] uA continuously."
puts $data

set data "Daily radio dynamic energy is [format {%0.0f} $daily_radio_ping_energy] joules, "
append data "drawing [format {%0.0f} [expr $radio_ping_current * 1e3]] mA "
append data "each ping.  Ping frequency is [format {%0.1f} [expr $radio_ping_frequency]] Hz."
puts $data

# --------------------------- Total -----------------------------------

set total_daily_energy [expr $daily_radio_ping_energy +\
			     $daily_radio_static_energy]

# Calculate the static current that should be measured from a voltage
# source equal to the fresh battery voltage.
set total_static_battery_current $radio_static_current

# The total current that should be measured from a voltage source
# equal to the fresh battery voltage during a dispense event.
set total_ping_battery_current [expr $radio_ping_current + $radio_static_current]


utils::add_section_header "Total"

puts "Total daily energy expenditure is [format {%0.0f} $total_daily_energy] joules"
puts "Radio static share is [format {%0.0f} [expr $daily_radio_static_energy / $total_daily_energy * 100]]%"
puts "Radio active share is [format {%0.0f} [expr $daily_radio_ping_energy / $total_daily_energy * 100]]%"

set days_to_die [expr $battery_energy / $total_daily_energy]
set data  "Life expectancy is [format {%0.0f} $days_to_die] days "
append data "([format {%0.2f} [expr ($days_to_die / 365)]] years)."
puts $data

# ------------------------ Verification -------------------------------

# Time to spend averaging current samples (seconds)
set measurement_time 100

set averaged_current [expr (($measurement_time * $radio_ping_frequency * $radio_ping_time * $radio_ping_current) +\
			 ($measurement_time * $radio_static_current)) / $measurement_time]

utils::add_section_header "Verification"
set data "Static current draw from a [format {%0.2f} $fresh_voltage] volt source is "
append data "[format {%0.0f} [expr $total_static_battery_current * 1e6]] uA."
puts $data

set data "Current draw from a [format {%0.2f} $fresh_voltage] volt source "
append data "during a ping is [format {%0.2f} [expr $total_ping_battery_current * 1e3]] mA."
puts $data

set data "Average current draw measured over [format {%0.0f} $measurement_time] seconds is "
append data "[format {%0.0f} [expr $averaged_current * 1e6]] uA."
puts $data
puts ""







