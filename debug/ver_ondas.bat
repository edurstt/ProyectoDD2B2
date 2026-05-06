@echo off
:: Abre ModelSim en modo GUI con formas de onda
:: Uso: elegir que testbench visualizar

set VSIM_DIR=C:\altera\16.0\modelsim_ase\win32aloem

for /f "tokens=*" %%i in ('cmd /c "for %%j in ("%~dp0.") do echo %%~sfj"') do set SRC_DIR=%%i

cd /d "%SRC_DIR%"

echo Elige testbench:
echo   1) bcd_to_bin  (combinacional)
echo   2) bin_to_bcd  (secuencial, Double Dabble)
set /p OPT="Opcion [1/2]: "

if "%OPT%"=="1" (
    "%VSIM_DIR%\vsim.exe" work.tb_bcd_to_bin -do "wave_bcd_to_bin.do"
) else if "%OPT%"=="2" (
    "%VSIM_DIR%\vsim.exe" work.tb_bin_to_bcd -do "wave_bin_to_bcd.do"
) else (
    echo Opcion no valida.
    pause
)
