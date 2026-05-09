@echo off
:: Script de compilacion y simulacion batch – Fase 1 + Fase 2 + Fase 3
:: Resuelve el problema de la ruta con caracter especial (n~) usando ruta 8.3

set VSIM_DIR=C:\altera\16.0\modelsim_ase\win32aloem

:: Obtener ruta 8.3 para evitar el caracter especial en la ruta (n~)
for /f "tokens=*" %%i in ('cmd /c "for %%j in ("%~dp0.") do echo %%~sfj"') do set SRC_DIR=%%i

cd /d "%SRC_DIR%"

echo === Preparando libreria work ===
if exist work rmdir /s /q work
"%VSIM_DIR%\vlib.exe" work
mkdir work\_temp
"%VSIM_DIR%\vmap.exe" work work

echo.
echo === Compilando FASE 1 ===
"%VSIM_DIR%\vcom.exe" -93 -work work ^
    fase1\bcd_to_bin.vhd ^
    fase1\bin_to_bcd.vhd ^
    fase1\tb_bcd_to_bin.vhd ^
    fase1\tb_bin_to_bcd.vhd
if errorlevel 1 ( echo ERROR fase1. Abortando. & pause & exit /b 1 )

echo.
echo === Compilando FASE 2 ===
"%VSIM_DIR%\vcom.exe" -93 -work work ^
    fase2\lpm_mult.vhd ^
    fase2\alu.vhd ^
    fase2\timer.vhd ^
    fase2\clk_div.vhd ^
    fase2\ctrl_tec.vhd ^
    fase2\interfaz_teclado.vhd ^
    fase2\displays.vhd ^
    fase2\tb_alu.vhd
if errorlevel 1 ( echo ERROR fase2. Abortando. & pause & exit /b 1 )

echo.
echo === Compilando FASE 3 ===
"%VSIM_DIR%\vcom.exe" -93 -work work ^
    fase3\controlador.vhd ^
    fase3\calculadora.vhd ^
    fase3\tb_calculadora.vhd
if errorlevel 1 ( echo ERROR fase3. Abortando. & pause & exit /b 1 )

echo.
echo === Simulando tb_bcd_to_bin ===
"%VSIM_DIR%\vsim.exe" -c work.tb_bcd_to_bin -do "debug\dump_bcd_to_bin.do"

echo.
echo === Simulando tb_bin_to_bcd ===
"%VSIM_DIR%\vsim.exe" -c work.tb_bin_to_bcd -do "debug\dump_bin_to_bcd.do"

echo.
echo === Simulando tb_alu ===
"%VSIM_DIR%\vsim.exe" -c work.tb_alu -do "debug\dump_alu.do"

echo.
echo === Simulando tb_calculadora ===
"%VSIM_DIR%\vsim.exe" -c work.tb_calculadora -do "debug\dump_calculadora.do"

echo.
echo === Corrigiendo formato VCD (bug ModelSim 10.4d) ===
for %%f in (debug\tb_bcd_to_bin.vcd debug\tb_bin_to_bcd.vcd debug\tb_alu.vcd debug\tb_calculadora.vcd) do (
    powershell -ExecutionPolicy Bypass -Command "$f='%%f'; $c=Get-Content $f -Raw; if(-not $c.TrimStart().StartsWith('$date')){Set-Content $f ('$date'+\"`r`n\"+$c) -NoNewline; Write-Host 'Corregido: '$f}else{Write-Host 'OK: '$f}"
)

echo.
echo === Agrupando senales en buses (para VaporView/Surfer) ===
python debug\merge_vcd_buses.py debug\tb_bcd_to_bin.vcd   debug\tb_bcd_to_bin_bus.vcd
python debug\merge_vcd_buses.py debug\tb_bin_to_bcd.vcd   debug\tb_bin_to_bcd_bus.vcd
python debug\merge_vcd_buses.py debug\tb_alu.vcd           debug\tb_alu_bus.vcd
python debug\merge_vcd_buses.py debug\tb_calculadora.vcd   debug\tb_calculadora_bus.vcd

echo.
echo === Listo ===
echo VCDs en debug\  -  Abrir tb_*_bus.vcd en VS Code con VaporView o Surfer
pause
