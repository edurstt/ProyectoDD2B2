# merge_vcd_buses.ps1
# Convierte un VCD de ModelSim (bits sueltos "signal [N]") en vectores agrupados
# Uso: powershell -ExecutionPolicy Bypass -File merge_vcd_buses.ps1 input.vcd output.vcd

param(
    [Parameter(Mandatory)][string]$InputFile,
    [Parameter(Mandatory)][string]$OutputFile
)

$lines = Get-Content $InputFile
$header   = @()
$body     = @()
$inHeader = $true

# Separar cabecera ($var...) del cuerpo (#tiempo...)
foreach ($line in $lines) {
    if ($line -match '^\s*#\d') { $inHeader = $false }
    if ($inHeader) { $header += $line } else { $body += $line }
}

# Recoger definiciones de variables bit a bit: "wire 1 ID signal [N]"
# Agruparlas por nombre base -> lista ordenada de (bit, id)
$buses = @{}   # nombre -> hashtable de bit->id
$allIds = @{}  # id -> nombre base y bit

foreach ($line in $header) {
    if ($line -match '\$var\s+wire\s+1\s+(\S+)\s+(\w+)\s+\[(\d+)\]\s+\$end') {
        $id   = $Matches[1]
        $name = $Matches[2]
        $bit  = [int]$Matches[3]
        if (-not $buses.ContainsKey($name)) { $buses[$name] = @{} }
        $buses[$name][$bit] = $id
        $allIds[$id] = @{ name=$name; bit=$bit }
    }
}

# Construir nueva cabecera: reemplazar bits sueltos por una sola entrada "wire N ID name"
# Asignar un nuevo ID compuesto por el nombre
$newHeader = @()
$busWritten = @{}
foreach ($line in $header) {
    if ($line -match '\$var\s+wire\s+1\s+(\S+)\s+(\w+)\s+\[(\d+)\]\s+\$end') {
        $name = $Matches[2]
        if (-not $busWritten.ContainsKey($name)) {
            $width = $buses[$name].Count
            # Nuevo ID = primer caracter del nombre (simplificado)
            $newId = "BUS_$name"
            $newHeader += "`$var wire $width $newId $name `$end"
            $busWritten[$name] = $newId
        }
        # Saltar la definicion de bit suelto
    } else {
        $newHeader += $line
    }
}

# Construir nuevo cuerpo: agrupar cambios de bits en vectores
# Estrategia: por cada timestamp, recoger todos los cambios, reconstruir vectores completos
$currentTime = ""
$timeChanges = [ordered]@{}   # tiempo -> nombre -> bit -> valor
$busCurrentVal = @{}           # nombre -> array de bits (inicializado a 'x')

foreach ($name in $buses.Keys) {
    $w = $buses[$name].Count
    $busCurrentVal[$name] = @('x') * $w
}

$newBody = @()
$pendingTime = ""

function Flush-Time {
    param($t, $changes)
    $out = @()
    if ($t -ne "") { $out += $t }
    foreach ($name in $changes.Keys) {
        foreach ($bit in $changes[$name].Keys) {
            $busCurrentVal[$name][$bit] = $changes[$name][$bit]
        }
        $newId = $busWritten[$name]
        $w = $buses[$name].Count
        $vec = ""
        for ($b = $w-1; $b -ge 0; $b--) {
            $vec += $busCurrentVal[$name][$b]
        }
        $out += "b$vec $newId"
    }
    return $out
}

$pendingChanges = [ordered]@{}

foreach ($line in $body) {
    if ($line -match '^\s*(#\d+)') {
        # Volcar cambios del timestamp anterior
        if ($pendingTime -ne "" -or $pendingChanges.Count -gt 0) {
            $newBody += Flush-Time $pendingTime $pendingChanges
        }
        $pendingTime = $line.Trim()
        $pendingChanges = [ordered]@{}
    } elseif ($line -match '^([01xzXZ])(\S+)') {
        $val = $Matches[1].ToLower()
        $id  = $Matches[2]
        if ($allIds.ContainsKey($id)) {
            $name = $allIds[$id].name
            $bit  = $allIds[$id].bit
            if (-not $pendingChanges.ContainsKey($name)) {
                $pendingChanges[$name] = @{}
            }
            $pendingChanges[$name][$bit] = $val
        } else {
            # Señal no agrupada, pasar tal cual
            if ($pendingTime -ne "") {
                $newBody += $pendingTime
                $pendingTime = ""
            }
            $newBody += $line
        }
    } else {
        if ($pendingChanges.Count -gt 0 -or $pendingTime -ne "") {
            $newBody += Flush-Time $pendingTime $pendingChanges
            $pendingTime = ""
            $pendingChanges = [ordered]@{}
        }
        $newBody += $line
    }
}
# Volcar lo que queda
if ($pendingTime -ne "" -or $pendingChanges.Count -gt 0) {
    $newBody += Flush-Time $pendingTime $pendingChanges
}

($newHeader + $newBody) | Set-Content $OutputFile
Write-Host "Generado: $OutputFile"
