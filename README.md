# MiscThings

**kisspost.ps1 / kisspostrrf.ps1**

Allows for some basic gcode prostproccesing of KISSlicer generated gcode.
* automatically copy generated/modfied gcode to specified outDir, all gcode files in one place
* -crownExtrusionModifier will modify the extrusion rate of crown paths ('gap fills'). 1 = 100%, 1.1 = 110%
* Nozzle prime speed: the script will search the gcode for '; prime_speed_mm_per_s = [number]' and adjust all nozzle primes to the specified speed. This can be injected into the gcode by using the filament specific Matl Gcode found in profiles and <MATL> tag.
* Per path type acceleration: if the -rewriteLoopAccels parameter is supplied the script will search the gcode for tokens and adjust Klippers/RepRapFirmwares acceleation based on the path type. Default acceleration will be used for all unconfigured path types. Supported tags:
  * '; perimeter_path_accel_mm_per_s_per_s = [number]'
  * '; loop_path_accel_mm_per_s_per_s = [number]'
  * '; crown_path_accel_mm_per_s_per_s = [number]'
  * '; travel_path_accel_mm_per_s_per_s = [number]'
  * '; solid_path_accel_mm_per_s_per_s = [number]'
  * '; infill_path_accel_mm_per_s_per_s = [number]'
  

Set Post-Process in KISSlicer Profiles -> Printer -> Firmware
`powershell c:\apps\3dprint\kisspost.ps1 -inFile '<FILE>' -outDir c:\apps\gcode -crownExtrusionModifier 1.005 -rewriteLoopAccels`

`powershell c:\apps\3dprint\kisspostrff.ps1 -inFile '<FILE>' -outDir c:\apps\gcode -crownExtrusionModifier 1.005 -rewriteLoopAccels`
  
**kisspost.py**

Little brother to kisspost.ps1.
Does not include the crownExtrusionModifier and rewriteLoopAccels. Prime speed is extracted from the same MATL token or provided via --speed paramter

Set Post-Process in KISSlicer Profiles -> Printer -> Firmware
`python c:\apps\3dprint\kisspost.py --inFile "<FILE>" --outDir "c:\apps\gcode"`


**kiss_profile.zip**

My KISSlicer 2 profile

**Voron 2.1.fff**

My Simplify3D profile
