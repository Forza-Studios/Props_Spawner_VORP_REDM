$ErrorActionPreference = 'Stop'
$here = $PSScriptRoot
$dataDir = Join-Path $here '..\data'
$bp = Join-Path $dataDir 'bank_props.json'
$compactFiles = Get-ChildItem -LiteralPath $dataDir -Filter 'deco_compact*.txt' | Sort-Object Name
if (-not $compactFiles) { throw 'No deco_compact*.txt in data folder' }

$sections = [ordered]@{}
$current = $null
foreach ($f in $compactFiles) {
    Get-Content -LiteralPath $f.FullName -Encoding UTF8 | ForEach-Object {
        $line = ([string]$_).TrimStart([char]0xFEFF).TrimEnd("`r").Trim()
        if ($line -match '^\s*>>(.+)$') {
            $current = $matches[1].Trim()
            if (-not $sections.Contains($current)) {
                $sections[$current] = [System.Collections.Generic.List[string]]::new()
            }
        }
        elseif ($current -and $line -match '^\s*@(.+)$') {
            $inc = $matches[1].Trim()
            $incPath = if ([System.IO.Path]::IsPathRooted($inc)) {
                $inc
            } else {
                $c1 = Join-Path $dataDir $inc
                if (Test-Path -LiteralPath $c1) { $c1 } else { Join-Path $here $inc }
            }
            if (-not (Test-Path -LiteralPath $incPath)) { throw "Include not found: $incPath" }
            $incText = [System.IO.File]::ReadAllText($incPath).Trim()
            foreach ($part in ($incText -split ',')) {
                $p = $part.Trim()
                if ($p) { [void]$sections[$current].Add($p) }
            }
        }
        elseif ($current -and $line) {
            foreach ($part in ($line -split ',')) {
                $p = $part.Trim()
                if ($p) { [void]$sections[$current].Add($p) }
            }
        }
    }
}

$decoOrdered = [ordered]@{}
foreach ($sec in $sections.Keys) {
    $seen = @{}
    $u = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $sections[$sec]) {
        if ($seen.ContainsKey($m)) { continue }
        $seen[$m] = $true
        [void]$u.Add($m)
    }
    $decoOrdered[$sec] = @($u)
}

$decoJson = ([pscustomobject]$decoOrdered | ConvertTo-Json -Compress -Depth 25)
$raw = [System.IO.File]::ReadAllText($bp)
if ($raw.StartsWith([char]0xFEFF)) { $raw = $raw.Substring(1) }
$normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
$needle = "                                            `"p_campfiredirtsml01x`"`n                                        ]`n                  },`n    `"Body Parts`":  {"
if (-not $normalized.Contains($needle)) {
    throw 'Anchor not found (Campfire Various -> Body Parts). Already merged?'
}
$nl = [char]10
$insert = '                                            "p_campfiredirtsml01x"' + $nl + '                                        ]' + $nl + '                  },' + $nl + '    "Deco":  ' + $decoJson + ',' + $nl + '    "Body Parts":  {'
$normalized = $normalized.Replace($needle, $insert)
$out = $normalized -replace "`n", "`r`n"
if (-not $out.TrimStart().StartsWith('{')) {
    throw 'bank_props.json would be written without root { — aborting'
}
[System.IO.File]::WriteAllText($bp, $out, [System.Text.UTF8Encoding]::new($false))
$modelTotal = 0
foreach ($arr in $decoOrdered.Values) { $modelTotal += $arr.Count }
Write-Host ('Deco blocks: ' + $decoOrdered.Count + ', models total: ' + $modelTotal)
