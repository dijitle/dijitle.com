#writes output to .\dijitle.svg

function cornerify { 
    param (
        $x,
        $y,
        $radius,
        $coordinate
    )
    $deltaX = 0
    $deltaY = 0

    if ($coordinate -eq "N") {
        $deltaX = $radius / 2
        $deltaY = $radius / 2 * [math]::sin([math]::pi / 6)

        return "$($x - $deltaX) $($y + $deltaY)
        A $radius $radius 0 0 1 $($x + $deltaX) $($y + $deltaY)"
    } elseif ($coordinate -eq "S") {
        $deltaX = $radius / 2
        $deltaY = $radius / 2 * [math]::sin([math]::pi / 6)

        return "$($x + $deltaX) $($y - $deltaY)
        A $radius $radius 0 0 1 $($x - $deltaX) $($y - $deltaY)"
    } elseif ($coordinate -eq "NE") {
        $x += $radius
    } elseif ($coordinate -eq "SE") {
        $x += $radius
        $y += $radius
    } elseif ($coordinate -eq "SW") {
        $y += $radius
    } elseif ($coordinate -eq "NW") {
        #no change
    } else {
        throw "Invalid coordinate: $coordinate. Must be one of N, S, NE, SE, SW, NW."
    }
    `
    
}

$viewBoxSize = 100

#adjustable parameters
$innerRatio = 0.5
$cornerRadius = 10

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
     d="M $(cornerify -x $NOuterX -y $NOuterY -radius $cornerRadius -coordinate "N")
        L $OutterStemX $OutterStemY
        L $InnerStemX $InnerStemY
        L $NInnerX $NInnerY
        L $NWInnerX $NWInnerY
        L $SWInnerX $SWInnerY
        L $SInnerX $SInnerY
        L $SEInnerX $SEInnerY
        L $NEInnerX $NEInnerY
        L $NEOutterX $NEOutterY
        L $SEOutterX $SEOutterY
        L $(cornerify -x $SOuterX -y $SOuterY -radius $cornerRadius -coordinate "S")
        L $SWOutterX $SWOutterY
        L $NWOutterX $NWOutterY
        Z"/>
        
    <circle cx="$centerX" cy="$centerY" r="$circleRadius" fill="#000"/>
</svg>
"@

$svgContent | Out-File -FilePath .\dijitle.svg -Encoding utf8