@echo off

cd /d "C:\apache-jmeter-5.6.3\Projeto Postman"

if exist results\load-20.jtl del results\load-20.jtl
if exist reports\load-20 rmdir /s /q reports\load-20

if not exist results mkdir results
if not exist reports mkdir reports

jmeter -n ^
-t ProjetoCSV.jmx ^
-Jusers=20 ^
-Jrampup=60 ^
-Jduration=300 ^
-l results\load-20.jtl ^
-e ^
-o reports\load-20