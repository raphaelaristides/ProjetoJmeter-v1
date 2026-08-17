@echo off

cd /d "C:\apache-jmeter-5.6.3\Projeto Postman"

if exist results\load-50.jtl del results\load-50.jtl
if exist reports\load-50 rmdir /s /q reports\load-50

if not exist results mkdir results
if not exist reports mkdir reports

jmeter -n ^
-t ProjetoCSV.jmx ^
-Jusers=50 ^
-Jrampup=120 ^
-Jduration=600 ^
-l results\load-50.jtl ^
-e ^
-o reports\load-50