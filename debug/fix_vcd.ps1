# fix_vcd.ps1 - Corrige VCDs generados por ModelSim 10.4d (falta el tag $date)
param([string]$file)

$content = Get-Content $file -Raw

# Si el archivo no empieza con $date, lo añade
if (-not $content.TrimStart().StartsWith('$date')) {
    $content = '$date' + "`r`n" + $content
    Set-Content $file $content -NoNewline
    Write-Host "Corregido: $file"
} else {
    Write-Host "OK (no necesita correccion): $file"
}
