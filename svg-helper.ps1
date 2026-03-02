#writes output to .\dijitle.svg

function cornerify { 
    param (
        $x,
        $y,
        $radius,
        $coordinate,
        $clockwise
    )
    $deltaX1 = 0
    $deltaX2 = 0
    $deltaY1 = 0
    $deltaY2 = 0
    $cw = $(if ($clockwise) { 1 } else { - 1 })

    if ($coordinate -eq "N") {
        $deltaX1 = -$radius / 2 * [math]::cos([math]::pi / 6) * $cw
        $deltaY1 = $radius / 2 * [math]::sin([math]::pi / 6)

        $deltaX2 = $radius / 2 * [math]::cos([math]::pi / 6) * $cw
        $deltaY2 = $radius / 2 * [math]::sin([math]::pi / 6)

    } elseif ($coordinate -eq "S") {
        $deltaX1 = $radius / 2 * [math]::cos([math]::pi / 6) * $cw
        $deltaY1 = -$radius / 2 * [math]::sin([math]::pi / 6) 

        $deltaX2 = -$radius / 2 * [math]::cos([math]::pi / 6) * $cw
        $deltaY2 = -$radius / 2 * [math]::sin([math]::pi / 6) 

    } elseif ($coordinate -eq "NE") {
        $deltaX1 = -$radius / 2 * [math]::cos([math]::pi / 6) * $cw
        $deltaY1 = -$radius / 2 * [math]::sin([math]::pi / 6)

        $deltaX2 = 0
        $deltaY2 = $radius / 2
        
    } elseif ($coordinate -eq "SE") {
        if($clockwise) {
            $deltaX1 = 0
            $deltaY1 = -$radius / 2

            $deltaX2 = -$radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY2 = $radius / 2 * [math]::sin([math]::pi / 6)
        } else {
            $deltaX1 = -$radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY1 = $radius / 2 * [math]::sin([math]::pi / 6)

            $deltaX2 = 0
            $deltaY2 = -$radius / 2
        }
        
    } elseif ($coordinate -eq "SW") {
        if($clockwise) {
            $deltaX1 = $radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY1 = $radius / 2 * [math]::sin([math]::pi / 6)

            $deltaX2 = 0
            $deltaY2 = -$radius / 2 
        } else {
            $deltaX1 = 0
            $deltaY1 = -$radius / 2 

            $deltaX2 = $radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY2 = $radius / 2 * [math]::sin([math]::pi / 6)
        }
        
    } elseif ($coordinate -eq "NW") {
        if($clockwise) {
            $deltaX1 = 0
            $deltaY1 = $radius / 2

            $deltaX2 = $radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY2 = -$radius / 2 * [math]::sin([math]::pi / 6)
        } else {
            $deltaX1 = $radius / 2 * [math]::cos([math]::pi / 6)
            $deltaY1 = -$radius / 2 * [math]::sin([math]::pi / 6)

            $deltaX2 = 0
            $deltaY2 = $radius / 2 
        }
    } else {
        throw "Invalid coordinate: $coordinate. Must be one of N, S, NE, SE, SW, NW."
    }
    
    return "$($x + $deltaX1) $($y + $deltaY1)
    Q $x $y $($x + $deltaX2) $($y + $deltaY2)"
}

$viewBoxSize = 100

#adjustable parameters
$innerRatio = 0.5
$cornerRadius = 8

#helper parameters
$outterEdgeLength = $viewBoxSize / 2
$innerEdgeLength = $outterEdgeLength * $innerRatio
$centerX = $viewBoxSize / 2
$centerY = $viewBoxSize / 2

$circleRadius = $innerEdgeLength / 2.66667

$NOuterX = $centerX
$NOuterY = 0

$NEOutterX = $centerX + $outterEdgeLength * [math]::cos([math]::pi / 6)
$NEOutterY = $centerX - $outterEdgeLength * [math]::sin([math]::pi / 6)

$SEOutterX = $centerX + $outterEdgeLength * [math]::cos([math]::pi / 6)
$SEOutterY = $centerX + $outterEdgeLength * [math]::sin([math]::pi / 6)

$SOuterX = $centerX
$SOuterY = $viewBoxSize

$SWOutterX = $centerX - $outterEdgeLength * [math]::cos([math]::pi / 6)
$SWOutterY = $centerX + $outterEdgeLength * [math]::sin([math]::pi / 6)

$NWOutterX = $centerX - $outterEdgeLength * [math]::cos([math]::pi / 6)
$NWOutterY = $centerX - $outterEdgeLength * [math]::sin([math]::pi / 6)



$NInnerX = $centerX
$NInnerY = $centerX - $innerEdgeLength

$NEInnerX = $centerX + $innerEdgeLength * [math]::cos([math]::pi / 6)
$NEInnerY = $centerX - $innerEdgeLength * [math]::sin([math]::pi / 6) - $NInnerY

$SEInnerX = $centerX + $innerEdgeLength * [math]::cos([math]::pi / 6)
$SEInnerY = $centerX + $innerEdgeLength * [math]::sin([math]::pi / 6)

$SInnerX = $centerX
$SInnerY = $centerX + $innerEdgeLength

$SWInnerX = $centerX - $innerEdgeLength * [math]::cos([math]::pi / 6)
$SWInnerY = $centerX + $innerEdgeLength * [math]::sin([math]::pi / 6)

$NWInnerX = $centerX - $innerEdgeLength * [math]::cos([math]::pi / 6)
$NWInnerY = $centerX - $innerEdgeLength * [math]::sin([math]::pi / 6)



$OutterStemX = $centerX + $circleRadius
$OutterStemY = $circleRadius * [math]::sin([math]::pi / 6) 

$InnerStemX = $OutterStemX
$InnerStemY = $OutterStemY + $NInnerY

$svgContent = @"
<svg viewBox="0 0 $viewBoxSize $viewBoxSize" xmlns="http://www.w3.org/2000/svg">
  <path fill="#000"  
     d="M $(cornerify -x $NOuterX -y $NOuterY -radius $cornerRadius -coordinate "N" -clockwise $true)
        L $OutterStemX $OutterStemY
        L $InnerStemX $InnerStemY
        L $(cornerify -x $NInnerX -y $NInnerY -radius ($cornerRadius * $innerRatio) -coordinate "N" -clockwise $false)
        L $(cornerify -x $NWInnerX -y $NWInnerY -radius ($cornerRadius * $innerRatio) -coordinate "NW" -clockwise $false)
        L $(cornerify -x $SWInnerX -y $SWInnerY -radius ($cornerRadius * $innerRatio) -coordinate "SW" -clockwise $false)
        L $(cornerify -x $SInnerX -y $SInnerY -radius ($cornerRadius * $innerRatio) -coordinate "S" -clockwise $false)
        L $(cornerify -x $SEInnerX -y $SEInnerY -radius ($cornerRadius * $innerRatio) -coordinate "SE" -clockwise $false)
        L $NEInnerX $NEInnerY
        L $(cornerify -x $NEOutterX -y $NEOutterY -radius $cornerRadius -coordinate "NE" -clockwise $true)
        L $(cornerify -x $SEOutterX -y $SEOutterY -radius $cornerRadius -coordinate "SE" -clockwise $true)
        L $(cornerify -x $SOuterX -y $SOuterY -radius $cornerRadius -coordinate "S" -clockwise $true)
        L $(cornerify -x $SWOutterX -y $SWOutterY -radius $cornerRadius -coordinate "SW" -clockwise $true)
        L $(cornerify -x $NWOutterX -y $NWOutterY -radius $cornerRadius -coordinate "NW" -clockwise $true)
        Z"/>
        
    <circle cx="$centerX" cy="$centerY" r="$circleRadius" fill="#000"/>
</svg>
"@

$svgContent | Out-File -FilePath .\dijitle.svg -Encoding utf8