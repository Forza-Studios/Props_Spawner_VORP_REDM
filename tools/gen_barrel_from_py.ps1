$ErrorActionPreference = "Stop"
$pyPath = Join-Path $PSScriptRoot "gen_barrel_json.py"
$raw = Get-Content -LiteralPath $pyPath -Raw -Encoding UTF8

function Get-Block([string]$name) {
    $pat = "(?s)${name} = ""{3}(.*?)""{3}"
    if ($raw -notmatch $pat) { throw "Block $name not found" }
    $lines = $Matches[1] -split "`r?`n" | ForEach-Object { $_.Trim().TrimEnd('|') } | Where-Object { $_ }
    $uniq = New-Object System.Collections.Generic.List[string]
    $seen = @{}
    foreach ($x in $lines) {
        if (-not $seen.ContainsKey($x)) {
            $seen[$x] = $true
            [void]$uniq.Add($x)
        }
    }
    return $uniq
}

$barrel = Get-Block "BARREL"
$boxes = Get-Block "BOXES"
$sack = Get-Block "SACK"
$sets = Get-Block "SETS"

$outObj = [ordered]@{
    "Barrel Sets Boxes" = [ordered]@{
        Barrel = $barrel
        Boxes  = $boxes
        Sack   = $sack
        Sets   = $sets
    }
}

$outFile = Join-Path (Split-Path $PSScriptRoot -Parent) "data\barrel_sets_boxes.json"
$json = $outObj | ConvertTo-Json -Depth 20
# UTF-8 без BOM — иначе json.decode в RedM может не прочитать файл
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($outFile, $json + "`n", $utf8NoBom)
Write-Host "Wrote $outFile Barrel=$($barrel.Count) Boxes=$($boxes.Count) Sack=$($sack.Count) Sets=$($sets.Count)"
