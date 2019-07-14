<#
.SYNOPSIS
Postprocessing for KISSlicer generated gcode

.DESCRIPTION
Rewrites KISSlicer generated gcode to modify the extrusion modifier of crown paths (single extrusion gap fills in other slicers) or to rewrite the prime speed (detraction speed).


.PARAMETER inFile
Full path to the gcode file

.PARAMETER outDir
Full path to the output directory. Filename will be amended from inFile 

.PARAMETER crownExtrusionModifier
Extrusionmodifier for Crown Paths. 1 = 100%

.PARAMETER rewriteLoopAccels
Changes Klippers acceleration based on path type. Definded via "solid_path_accel_mm_per_s_per_s = number",.. in gcode.

.LINK 
https://discordapp.com/channels/@me/dunar#5683/

#>
param(
[system.io.fileinfo]$inFile,
[string]$outDir,
[decimal]$crownExtrusionModifier=1,
[switch]$rewriteLoopAccels
)

$pathMatchEval = {
    param($match)
    try {
        switch ($match.Groups[1].Value) {

            Perimeter {
                if ($global:currentAccl -ne $perimeterPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $perimeterPathAccl, $match.Groups[3].Value);
                    $global:currentAccl = $perimeterPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            Loop {
                if ($global:currentAccl -ne $loopPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $loopPathAccl, $match.Groups[3].Value);
                    $global:currentAccl = $loopPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            Travel {
                if ($global:currentAccl -ne $travelPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $travelPathAccl, $match.Groups[3].Value);
                    $global:currentAccl = $travelPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            Solid {
                if ($global:currentAccl -ne $solidPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $solidPathAccl, $match.Groups[3].Value);
                    $global:currentAccl = $solidPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            'Stacked Sparse Infill' {
                if ($global:currentAccl -ne $infillPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $infillPathAccl,$match.Groups[3].Value);
                    $global:currentAccl = $infillPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }

            Infill {
                if ($global:currentAccl -ne $infillPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $infillPathAccl,$match.Groups[3].Value);
                    $global:currentAccl = $infillPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            Crown {
                if ($global:currentAccl -ne $crownPathAccl) {
                    $match.Groups[0].Value -replace $match.Groups[3].Value, ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $crownPathAccl,$match.Groups[3].Value);
                    $global:currentAccl = $crownPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }

            default {
                if ($global:currentAccl -ne $defaultPathAccl) {
                    $match.Groups[0] -replace $match.Groups[3], ("SET_VELOCITY_LIMIT ACCEL={0} ACCEL_TO_DECEL={0} SQUARE_CORNER_VELOCITY=5`n{1}" -f $defaultPathAccl,$match.Groups[3]);
                    $global:currentAccl = $defaultPathAccl;
                } else {
                    $match.Groups[0].Value;
                }
            }
            
        }
    } catch {
        write-host($match.Groups[0].Value)
        $match.Groups[0].Value;
    }
}

$eAxisMatchEval = {
    param($match)
    try {
        $ret = $match.Groups[0].Value -replace ("E{0}" -f $match.Groups[1]), ("E{0}" -f ($match.Groups[1].Value/1 * $crownExtrusionModifier));
        $ret;
    } catch {
        $match.Groups[0].Value;
    }
}

$crownPathMatchEval = {
    param($match)
    $eAxisMatcher.Replace(($match.Groups[0].Value), $eAxisMatchEval);
}

$primeMatchEval = {
    param($match)
    try {
        $ret = $match.Groups[0].Value -replace ("{0}" -f $match.Groups[1]), $primeSpeed;
        $ret;
    } catch {
        $match.Groups[0].Value;
    }
}


$fileContent = Get-Content $inFile.FullName -Raw;

$primeSpeed = 0;
$defaultPathAccl = 0;
$global:currentAccl = 0;

# search the gcode for the prime speed token
if ($fileContent -match '; prime_speed_mm_per_s = (\d+)') {
    try {
        $primeSpeed = $Matches[1]/1 * 60;
    } catch {
    }
}


# search for acceleration tokens in the gcode used to configure acceleration based on path type
# accel defined in printer tab will be used for all unconfigured types

# search the gcode for the default accleration 
if ($fileContent -match '; xy_accel_mm_per_s_per_s = (\d+)') {
    try {
        $defaultPathAccl = $Matches[1]/1;
    } catch {
    }
}

# set default values, use default if no overrides are specified in the gcode
$perimeterPathAccl = $defaultPathAccl;
$loopPathAccl = $defaultPathAccl;
$crownPathAccl = $defaultPathAccl;

$travelPathAccl = $defaultPathAccl;
$solidPathAccl = $defaultPathAccl;
$infillPathAccl = $defaultPathAccl;

# search the gcode for the perimeter path accel token
if ($fileContent -match '; perimeter_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $perimeterPathAccl = $Matches[1]/1;
    } catch {
    }
}

# search the gcode for the loop path accel token
if ($fileContent -match '; loop_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $loopPathAccl = $Matches[1]/1;
    } catch {
        $loopPathAccl = $defaultPathAccl; 
    }
}

# search the gcode for the crown path accel token
if ($fileContent -match '; crown_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $crownPathAccl = $Matches[1]/1;
    } catch {
        $crownPathAccl = $defaultPathAccl;
    }
}

# search the gcode for the travel path accel token
if ($fileContent -match '; travel_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $travelPathAccl = $Matches[1]/1;
    } catch {
        $travelPathAccl = $defaultPathAccl;
    }
}

# search the gcode for the solid path accel token
if ($fileContent -match '; solid_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $solidPathAccl = $Matches[1]/1;
    } catch {
        $solidPathAccl = $defaultPathAccl;
    }
}

# search the gcode for the solid path accel token
if ($fileContent -match '; infill_path_accel_mm_per_s_per_s = (\d+)') {
    try {
        $infillPathAccl = $Matches[1]/1;
    } catch {
        $infillPathAccl = $defaultPathAccl;
    }
}

# gcode contained a prime speed token that sucessfully parsed, find all nozzles primes and rewrite the speed
if ($primeSpeed -ne 0) {
    Write-Host ("Prime Speed: `t{0}" -f $primeSpeed);
    $primeMatcher =  [regex]"(?smi); 'Destring Prime'\r?\nG1 E\d+ F(.*?)\r?\n";
    $fileContent = $primeMatcher.Replace($fileContent, $primeMatchEval) 
}


$pathTypeMatcher = [regex]"(?smi)'(.*?) Path\'(.*?)^(.*?); head speed.*?^\;\s+^\;";

# should 
if ($rewriteLoopAccels.IsPresent) {   
    Write-Host ("Default Accel: `t{0}" -f $defaultPathAccl);
    Write-Host ("Loop Accel: `t{0}" -f $loopPathAccl);
    Write-Host ("Perimeter Accel: `t{0}" -f $perimeterPathAccl);
    Write-Host ("Crown Accel: `t{0}" -f $crownPathAccl);
    Write-Host ("Solid Accel: `t{0}" -f $solidPathAccl);
    Write-Host ("Infill Accel: `t{0}" -f $infillPathAccl);
    Write-Host ("Travel Accel: `t{0}" -f $travelPathAccl);

    $fileContent = $pathTypeMatcher.Replace($fileContent, $pathMatchEval) 
}

$crownPathMatcher = [regex]"(?smi)'Crown Path\'(.*?)^\;\s+^\;";
$eAxisMatcher = [regex]"(?m)G1 X.+E([\d\.]+)";

$crownPathMatcher.Replace($fileContent, $crownPathMatchEval) | Out-File ("{0}\{1}" -f $outDir, $inFile.Name) -Encoding utf8 -Force

pause