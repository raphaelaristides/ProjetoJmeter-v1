@echo off

if exist results\baseline-3.jtl del results\baseline-3.jtl
if exist reports\baseline-3 rmdir /s /q reports\baseline-3

if not exist results mkdir results
if not exist reports mkdir reports


jmeter -n ^
-t ProjetoCSV.jmx ^
-Jusers=3 ^
-Jrampup=30 ^
-Jduration=180 ^
-l results\baseline-3.jtl ^
-e ^
-o reports\baseline-3