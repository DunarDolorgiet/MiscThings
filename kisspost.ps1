<#
.SYNOPSIS
Postprocessing for KISSlicer generated gcode

.DESCRIPTION
Rewrites KISSlicer generated gcode to modify the extrusion modifiert of crown paths (single extrusion gap fills in other slicers) or to rewrite the prime speed (detraction speed).


.PARAMETER inFile
Full path to the gcode file

.PARAMETER outDir
Full path to the output directory. Filename will be amended from inFile 

.PARAMETER crownExtrusionModifier
Extrusionmodifier for Crown Paths. 1 = 100%

.PARAMETER rewritePrimeToPreload
Rewrites all desting prime speeds to the speed specified for preload (Profiles -> Matl -> vP [mm/s]). IMPORTANT: Set nozzle length to 0! Profiles -> Printer -> Extruder Hardware -> NozLen1..4
If rewritePrimeToPreload is not specified the script will search the gcode for '; preload_speed_mm_per_s = [number]'. This can be injected into the gcode by using the filament specific Matl Gcode found in profiles and <MATL> tag.

.LINK 
https://discordapp.com/channels/@me/dunar#5683/

#>
param(
[system.io.fileinfo]$inFile,
[string]$outDir,
[decimal]$crownExtrusionModifier=1,
[switch]$rewritePrimeToPreload
)


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


if ($rewritePrimeToPreload.IsPresent) {
    
    if ($fileContent -match '; preload_speed_mm_per_s = (\d+)') {
        try {
            $primeSpeed = $Matches[1]/1 * 60;
        } catch {
        }
    }
} else {
    if ($fileContent -match '; prime_speed_mm_per_s = (\d+)') {
        try {
            $primeSpeed = $Matches[1]/1 * 60;
        } catch {
        }
    }
}

if ($primeSpeed -ne 0) {
    $primeMatcher =  [regex]"(?smi); 'Destring Prime'\r?\nG1 E\d+ F(.*?)\r?\n";
    $fileContent = $primeMatcher.Replace($fileContent, $primeMatchEval) 
}

$crownPathMatcher = [regex]"(?smi)'Crown Path\'(.*?)^\;\s+^\;";
$eAxisMatcher = [regex]"(?m)G1 X.+E([\d\.]+)";

$crownPathMatcher.Replace($fileContent, $crownPathMatchEval) | Out-File ("{0}\{1}" -f $outDir, $inFile.Name) -Encoding utf8 -Force

