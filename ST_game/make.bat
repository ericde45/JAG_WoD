clear 

@echo on
del %1.o
copy %1.s backups\%1.s
cd backups
ren %1.s "%1_ %date:/=-% %time::=-%.s"
cd ..
rmac -fb -s -u %1.s 
if %ERRORLEVEL% NEQ 0 exit 0
rln   -o %1.abs -w -rq -a 1a0000 x x %1.o -m -z
if %ERRORLEVEL% NEQ 0 exit 0
rln   -o %1.bin -w -rq -a 1a0000 x x %1.o -m -n -z
if %ERRORLEVEL% NEQ 0 exit 0

copy %1.bin edz.bin /y

rem loader
rmac -fb -s -u loader_rom_%1.s
if %ERRORLEVEL% NEQ 0 exit 0
rln  -o %1_edz.rom -w -rq -a 800000 x x loader_rom_%1.o -m -n -z
if %ERRORLEVEL% NEQ 0 exit 0

@echo off
rem C:\Jaguar\Emulateur\jiffi_1.4\JiFFI.Exe -i c:\jaguar\%1.abs -o c:\jaguar -rom -j64 -overwrite

echo -------------------- ALL OK -------------------- 

rem cp "c:\jaguar\hively_v1_edz.rom" "c:\jaguar\_____\hively1.rom"

