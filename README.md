# LNL3dOS
firmware repo for LNL3d Klipper Units

known issues:
firmware restart can create loop in which mcu continuously times out (mega2560), machine would need to be power cycled
removing restart_method: command from MCU seems to have solved the issue

TODO
## add instructions on initial setup
ie: board and printer model need to be un-commented

## add customs / some sort of file or section for customized parameters, ie horizontal_move_z, extruder nozzle size, etc

## add 
8bit
sensor type heater bed missing
MCU header may need to be lumped into just paths
fix euclid probe reference error -> [probe euclid] is invalid, needs to just be [probe]

## steppers.cfgs
https://learn.watterott.com/silentstepstick/comparison/
d3s are running 2208 stepper drivers, RMS max is 1.2a, supports 256 microsteps
motor voltage supply of 3-5 (logic), 5.5-35v motor supply
70-80% of stpper driver max RMS is 0.84-0.96, may use 0.9a
starting with 40-50% puts driver amps at ~0.6
goal amperage of
```
- possibly address steppers if needed
Identified steppers thus far
x on d6
42hd6021-03

x on d3
42HD4027-01[https://www.crcibernetica.com/nema-17-stepper-motor-42hd4027-01-a/]
1.5amp motor, 1.2a driver
start amp tests at 0.48-0.6, target maximum of 0.84 (70%), never to exceed 0.92(80%)

y
42hd6021-03
z
42hd2037-01
extruder
42hd2037-1
```

## add idependent idex configurations for each type of printer?

## independent heater/fans cfgs


## psu related cfgs
--> end up including these 
#[gcode_macro m80]
#gcode:
#SET_PIN PIN=ps_on VALUE=1

#[gcode_macro m81]
#gcode:
#SET_PIN PIN=ps_on VALUE=0


```
#[filament_switch_sensor my_sensor]
#pause_on_runout: True
#   When set to True, a PAUSE will execute immediately after a runout
#   is detected. Note that if pause_on_runout is False and the
#   runout_gcode is omitted then runout detection is disabled. Default
#   is True.
#runout_gcode:
#	RESPOND MSG="Filament runout detected. Print paused."
#   A list of G-Code commands to execute after a filament runout is
#   detected. See docs/Command_Templates.md for G-Code format. If
#   pause_on_runout is set to True this G-Code will run after the
#   PAUSE is complete. The default is not to run any G-Code commands.
#insert_gcode:
#   A list of G-Code commands to execute after a filament insert is
#   detected. See docs/Command_Templates.md for G-Code format. The
#   default is not to run any G-Code commands, which disables insert
#   detection.
#event_delay: 3.0
#   The minimum amount of time in seconds to delay between events.
#   Events triggered during this time period will be silently
#   ignored. The default is 3 seconds.
#pause_delay: 0.5
#   The amount of time to delay, in seconds, between the pause command
#   dispatch and execution of the runout_gcode. It may be useful to
#   increase this delay if OctoPrint exhibits strange pause behavior.
#   Default is 0.5 seconds.
#switch_pin: PA15
#   The pin on which the switch is connected. This parameter must be
#   provided.
```