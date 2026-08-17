@echo off

cd /d "C:\apache-jmeter-5.6.3\Projeto Postman"

if exist results\load-10.jtl del results\load-10.jtl
if exist reports\load-10 rmdir /s /q reports\load-10

if not exist results mkdir results
if not exist reports mkdir reports

jmeter -n ^
-t "ProjetoCSV.jmx" ^
-Jusers=10 ^
-Jrampup=60 ^
-Jduration=300 ^
-l "results\load-10.jtl" ^
-e ^
-o "reports\load-10"

pause