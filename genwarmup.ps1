$centerX = 125
$centerY = 125

$minX = 5
$minY = 5
$minZ = 20

$maxX = 245
$maxY = 245
$maxZ = 150

$minFeedrate = 30
$maxFeedrate = 120

$minFeedrateZ = 5
$maxFeedrateZ = 40



$feedRate = $minFeedrate;

"G28"

# initial 45° moves, move head 5mm up from minZ
    "G0 Z{0} F{1}" -f ($minZ+5), ($minFeedrateZ*60)
    "G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ($minFeedrate*60)
    $feedRate = [Math]::Min(($minFeedrate*2),$maxFeedrate)
    "G0 X{0} Y{1} F{2}" -f $minX, $minY, ($minFeedrate*60)
    "G0 X{0} Y{1} F{2}" -f $maxX, $maxY, ($minFeedrate*60)
    "G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ($minFeedrate*60)
    "G0 X{0} Y{1} F{2}" -f $minX, $maxX, ($minFeedrate*60)
    "G0 X{0} Y{1} F{2}" -f $maxX, $minY, ($minFeedrate*60)


# spiral paths at increasing speeds
$feedRate = $minFeedrate;
while ($feedRate -le $maxFeedrate) {

    "G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ($feedRate*60)
    Get-SpiralPath
    $feedRate += $feedRate
}

"G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ([Math]::Min(($minFeedrate*2*60),($maxFeedrate*60)))


# z moves
$feedRateZ = $minFeedrateZ;
while ($feedRateZ -le $maxFeedrateZ) {

    "G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ($minFeedrate*60)
    
    "G0 Z{0} F{1}" -f $maxZ,($feedRateZ*60)
    "G0 Z{0} F{1}" -f $minZ,($feedRateZ*60)

    $feedRateZ += $feedRateZ
}

while ($feedRateZ -ge $minFeedrateZ) {
    
    "G0 Z{0} F{1}" -f $maxZ,($feedRateZ*60)
    "G0 Z{0} F{1}" -f $minZ,($feedRateZ*60)

    $feedRateZ = $feedRateZ/2
}

"G0 Z{0} F{1}" -f ($minZ+5),($minFeedrateZ*60)

"G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ([Math]::Min(($minFeedrate*2*60),($maxFeedrate*60)))
Get-SpiralPath

$feedRateZ = $minFeedrateZ;
while ($feedRateZ -le $maxFeedrateZ) {

    "G0 X{0} Y{1} F{2}" -f $centerX, $centerY, ($minFeedrate*60)
    
    "G0 Z{0} F{1}" -f $maxZ,($feedRateZ*60)
    "G0 Z{0} F{1}" -f $minZ,($feedRateZ*60)

    $feedRateZ += $feedRateZ
}

while ($feedRateZ -ge $minFeedrateZ) {
    
    "G0 Z{0} F{1}" -f $maxZ,($feedRateZ*60)
    "G0 Z{0} F{1}" -f $minZ,($feedRateZ*60)

    $feedRateZ = $feedRateZ/2
}

"G0 Z{0} F{1}" -f ($minZ+5),($minFeedrateZ*60)

"G28"



function Get-SpiralPath { 
    param(
        $a = 0.5,
        $b = 1,
        $loops = 20,
        $step = 0.1
    )
    $theta = 0
    $r = $a

    while ($theta -lt 2 * $loops * [Math]::PI) {
        $theta += $step
        $r = $a + $b*$theta
        $x = $r * [Math]::Cos($theta) + $centerX
        $y = $r * [Math]::Sin($theta) + $centerY

        if ($x -lt $maxX -and $y -lt $maxY -and $x -gt $minX -and $y -gt $minY) {
            "G0 X{0} Y{1}" -f $x,$y
        } else {
            return
        }
    }
}