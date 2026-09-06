$pref = @('act','amer','aml','art','grl','gun','hrs','inv','lnd','plt','spt','veh')
$out = [System.Collections.Generic.List[string]]::new()
foreach ($p in $pref) {
    foreach ($i in 1..12) {
        [void]$out.Add(('s_inv_cigcard_{0}_{1:D2}x' -f $p, $i))
    }
}
[System.IO.File]::WriteAllText((Join-Path $PSScriptRoot '_cigar.txt'), ($out -join ','), [System.Text.UTF8Encoding]::new($false))
