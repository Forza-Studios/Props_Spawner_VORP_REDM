# Склеивает data/barrel_sets_boxes.json в data/bank_props.json (клиент читает только bank_props + spooni_catalog).
# После правок в gen_barrel_json.py: сначала gen_barrel_from_py.ps1, потом этот скрипт.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$bankPath = Join-Path $root "data\bank_props.json"
$barrelPath = Join-Path $root "data\barrel_sets_boxes.json"
$bankRaw = Get-Content -LiteralPath $bankPath -Raw -Encoding UTF8
$barrelRaw = Get-Content -LiteralPath $barrelPath -Raw -Encoding UTF8
$bp = $bankRaw | ConvertFrom-Json
$br = $barrelRaw | ConvertFrom-Json
$bp | Add-Member -NotePropertyName "Barrel Sets Boxes" -NotePropertyValue $br."Barrel Sets Boxes" -Force
$json = $bp | ConvertTo-Json -Depth 50
$utf8 = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($bankPath, $json + "`n", $utf8)
Write-Host "Merged Barrel Sets Boxes into bank_props.json"
