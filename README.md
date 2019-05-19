# MiscThings

**kisspost.ps1**

Allows for some basic gcode prostproccesing of KISSlicer generated gcode.
* automatically copy generated/modfied gcode to specified outDir, all gcode files in one place
* -crownExtrusionModifier will modify the extrusion rated of crown paths ('gap fills'). 1 = 100%, 1.1 = 110%
* -rewritePrimeToPreload will rewrite all desting prime speeds to the speed specified for preload (Profiles -> Matl -> vP [mm/s]). IMPORTANT: Do not use this if you are working with KISSlicers Preload and set nozzle length to 0! (Profiles -> Printer -> Extruder Hardware -> NozLen1..4)
* If -rewritePrimeToPreload is not specified the script will search the gcode for '; preload_speed_mm_per_s = [number]'. This can be injected into the gcode by using the filament specific Matl Gcode found in profiles and <MATL> tag.

Set Post-Process in KISSlicer Profiles -> Printer -> Firmware
`powershell c:\apps\3dprint\kisspost.ps1 -inFile '<FILE>' -outDir 'C:\apps\gcode' -crownExtrusionModifier 1`
  
**kisspost.py**

Little brother to kisspost.ps1.
Does not include the crownExtrusionModifier and rewritePrimeToPreload. Prime speed is extracted from the same MATL token or provided via --speed paramter

Set Post-Process in KISSlicer Profiles -> Printer -> Firmware
`python c:\apps\3dprint\kisspost.py --inFile "<FILE>" --outDir "c:\apps\gcode"`
