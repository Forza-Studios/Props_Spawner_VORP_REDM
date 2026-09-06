# Export prop catalog from SPOONI site (Supabase REST), same data as https://spooni.pages.dev/props
# Previews on site: https://pub-baba8ba72b514b59b37deb644a62a310.r2.dev/props/<id>.webp
#
# Anon key is public (same as site JS). Get from DevTools → Network → any *.supabase.co request
#   header apikey, or set env SPOONI_SUPABASE_ANON_KEY.
#
# Run (from tools folder):
#   powershell -ExecutionPolicy Bypass -File .\fetch_spooni_catalog.ps1 -SupabaseAnonKey "eyJ..."
#
# Data rights belong to SPOONI Development; use per their content license.

param(
    [string]$SupabaseUrl = "https://gzddqqtajsoqeaknhykn.supabase.co",
    [string]$SupabaseAnonKey = $env:SPOONI_SUPABASE_ANON_KEY,
    [string]$OutFile = "",
    [int]$PageSize = 1000,
    [switch]$DownloadWebp,
    [int]$DownloadLimit = 0
)

$ErrorActionPreference = "Stop"

if (-not $SupabaseAnonKey) {
    Write-Error "Pass -SupabaseAnonKey or set SPOONI_SUPABASE_ANON_KEY."
}

if (-not $OutFile) {
    $OutFile = Join-Path (Split-Path $PSScriptRoot -Parent) "data\spooni_catalog.json"
}

$select = "id,categories!props_category_id_fkey(name),subcategories!props_subcategory_id_fkey(name)"
$baseUri = "$SupabaseUrl/rest/v1/props?select=$select&order=id"

$tree = @{}
$all = [System.Collections.Generic.List[string]]::new()
$start = 0

while ($true) {
    $end = $start + $PageSize - 1
    $h = @{
        "apikey"         = $SupabaseAnonKey
        "Authorization"  = "Bearer $SupabaseAnonKey"
        "Accept-Profile" = "public"
        "Range"          = "$start-$end"
        "Prefer"         = "count=exact"
    }

    $resp = Invoke-WebRequest -Uri $baseUri -Headers $h -Method GET -UseBasicParsing
    $rows = $resp.Content | ConvertFrom-Json
    if ($null -eq $rows) { break }
    if ($rows -isnot [System.Array]) { $rows = @($rows) }
    if ($rows.Count -eq 0) { break }

    foreach ($row in $rows) {
        $id = [string]$row.id
        if (-not $id) { continue }
        $cat = "uncategorized"
        $sub = "uncategorized"
        if ($row.categories -and $row.categories.name) {
            $cat = [string]$row.categories.name
        }
        if ($row.subcategories -and $row.subcategories.name) {
            $sub = [string]$row.subcategories.name
        }
        if (-not $tree.ContainsKey($cat)) {
            $tree[$cat] = @{}
        }
        if (-not $tree[$cat].ContainsKey($sub)) {
            $tree[$cat][$sub] = [System.Collections.Generic.List[string]]::new()
        }
        if (-not $tree[$cat][$sub].Contains($id)) {
            [void]$tree[$cat][$sub].Add($id)
        }
        if (-not $all.Contains($id)) {
            [void]$all.Add($id)
        }
    }

    $cr = $resp.Headers["Content-Range"]
    if (-not $cr) { break }
    # "0-999/14856"
    $total = [int]($cr -split '/' | Select-Object -Last 1)
    $start = $end + 1
    Write-Host "Loaded through $end / $total"
    if ($start -ge $total) { break }
}

# Nested Lists -> arrays, sorted
$outTree = [ordered]@{}
foreach ($ck in ($tree.Keys | Sort-Object)) {
    $subMap = [ordered]@{}
    foreach ($sk in ($tree[$ck].Keys | Sort-Object)) {
        $arr = @($tree[$ck][$sk] | Sort-Object)
        $subMap[$sk] = $arr
    }
    $outTree[$ck] = $subMap
}

$obj = [ordered]@{
    _meta        = [ordered]@{
        source      = "spooni.pages.dev / Supabase"
        generatedAt = (Get-Date).ToString("o")
        propCount   = $all.Count
    }
    categories   = $outTree
}

$json = $obj | ConvertTo-Json -Depth 20
$dir = Split-Path $OutFile -Parent
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($OutFile, $json + "`n", $utf8NoBom)
Write-Host "Written: $OutFile ($($all.Count) props)"

if ($DownloadWebp) {
    $imgRoot = Join-Path (Split-Path $PSScriptRoot -Parent) "html\img"
    if (-not (Test-Path $imgRoot)) { New-Item -ItemType Directory -Path $imgRoot | Out-Null }
    $baseImg = "https://pub-baba8ba72b514b59b37deb644a62a310.r2.dev/props"
    $n = 0
    foreach ($id in ($all | Sort-Object)) {
        if ($DownloadLimit -gt 0 -and $n -ge $DownloadLimit) { break }
        $url = "$baseImg/$id.webp"
        $dest = Join-Path $imgRoot "$id.webp"
        if (Test-Path $dest) { $n++; continue }
        try {
            Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
            $n++
            if (($n % 50) -eq 0) { Write-Host "Downloaded webp: $n" }
        } catch {
            Write-Warning "Missing file: $id"
        }
    }
    Write-Host "Webp download done: $n files in $imgRoot"
}
