Import-Module WebAdministration
#================================Variables=============================================
function prompt {
Write-Host "###############################################"
Write-Host "|      SERVERS APPLICATION POOLS CONTROLS     |"
Write-Host "###############################################"
Write-Host "| 1) STOP APPLICATION POOLS                   |"
Write-Host "| 2) START APPLICATION POOLS                  |"
Write-Host "| 3) GET APPLICATION POOLS RECYCLE TIME       |"
Write-Host "| 4) SET APPLICATION POOLS RECYCLE TIME       |"
Write-Host "|_____________________________________________|"

$prompt= Read-Host("Which one do you want the control from me")
if(($prompt -gt 4) -or ($prompt -lt 1)){
Write-Warning "THIS SCRIPT DO NOT CONTAIN YOUR COMMAND"
break;
}
Switch ($prompt)
      {
       1 {STOP_POOL}
       2 {START_POOL}     
       3 {GET_RECYCLE}
       4 {SET_RECYCLE}
      }
}

$Application_Pools_Conf = Import-Csv .\APP_POOL_CONF.txt
$Application_Pools_Pre = Import-Csv .\APP_POOL_PRE.txt
$Application_Pools_Normal = Import-Csv .\APP_POOL_NORMAL.txt
$SERVERS = Import-Csv .\Sunucu_Listesi.csv
$LIST=Import-Csv -Path '.\APP_POOL_LIST.txt'
$TIME = 15
$POOLS_CONF = $Application_Pools_Conf.Configuration
$POOLS_PRE = $Application_Pools_Pre.Pre_Application
$POOLS_NRML = $Application_Pools_Normal.Application_Pools
$JOBS_START = New-Object -TypeName System.Collections.ArrayList
$JOBS_STOP = New-Object -TypeName System.Collections.ArrayList
$SYMBOL="="
$MULTIPLE=33
$LIST_APPPOOL=$LIST.APP_POOLS
$LIST_TIME=$LIST.TIME
$LIST_TIME_=$LIST.TIME1
$Start_POOLS={
    param($CHOOSE)
    Import-Module WebAdministration
    $POOLS_CONF1 = $using:POOLS_CONF
    $POOLS_PRE1 = $using:POOLS_PRE
    $POOLS_NORML1 = $using:POOLS_NRML
    $TIME1 = $using:TIME
    #$POOLS_CONF1 | %{
    if($CHOOSE -eq "CONF"){$CH =$POOLS_CONF1 }
    elseif($CHOOSE -eq "PRE"){$CH =$POOLS_PRE1 }
    elseif($CHOOSE -eq "NRML"){$CH =$POOLS_NORML1 }
    foreach($NAME in $CH){
    if(Test-Path IIS:\AppPools\$NAME ){
    if((Get-WebAppPoolState -Name $NAME).value -eq "Stopped"){
    Write-Warning "I FOUND THIS APPLICATION TO STARTED"
    Start-WebAppPool -Name $NAME
    Write-Host "$NAME" ,(Get-WebAppPoolState -Name $NAME).value -ForegroundColor Green
    }
    else{
    Write-Host "$NAME-------------->""ALREADY THIS APPLICATION POOL IS STARTED" -ForegroundColor Red
    }  
    }
    else{
    Write-HOST "$NAME-------------->","WE COULD NOT FOUND THIS APLLICATION "
    }
    }
}
$Stop_POOLS={
    param($CHOOSE)
    Import-Module WebAdministration
    $POOLS_CONF1 = $using:POOLS_CONF
    $POOLS_PRE1 = $using:POOLS_PRE
    $POOLS_NORML1 = $using:POOLS_NRML
    $TIME1 = $using:TIME
    #$POOLS_CONF1 | %{
    if($CHOOSE -eq "CONF"){$CH =$POOLS_CONF1 }
    elseif($CHOOSE -eq "PRE"){$CH =$POOLS_PRE1 }
    elseif($CHOOSE -eq "NRML"){$CH =$POOLS_NORML1 }
    foreach($NAME in $CH){
    if(Test-Path IIS:\AppPools\$NAME ){
    if((Get-WebAppPoolState -Name $NAME).value -eq "Started"){
    Write-Warning "I FOUND THIS APPLICATION TO STOP"
    Stop-WebAppPool -Name $NAME
    Write-Host "$NAME" ,(Get-WebAppPoolState -Name $NAME).value -ForegroundColor Green
    }
    else{
    Write-Host "$NAME-------------->""ALREADY THIS APPLICATION POOL IS STOOPED" -ForegroundColor Red
    }  
    }
    else{
    Write-HOST "$NAME-------------->","WE COULD NOT FOUND THIS APLLICATION "
    }
    }
}
function START_POOL(){
$ENV= Read-Host("Which environment do you want to the start from me( DEV | TEST | PREPROD | PROD)")
if(!$SERVERS[0].$ENV){Write-Warning "THIS SCRIPT DOES NOT CONTAINS YOUR ENVIRONMENT";break;}
foreach($server in $SERVERS.$ENV){
Write-Host ""
Write-Host "SERVER : $server" -ForegroundColor Yellow
$NAME = "CONF","PRE","NRML"
$NAME | %{
Write-Host ("="*33),$_,("="*33)
Invoke-Command  -ComputerName $server -ScriptBlock  $Start_POOLS -ArgumentList $_
if($_ -eq "CONF"){Start-Sleep -s 1}
}
}
}
function STOP_POOL(){
$ENV= Read-Host("Which environment do you want to the start from me( DEV | TEST | PREPROD | PROD)")
if(!$SERVERS[0].$ENV){Write-Warning "THIS SCRIPT DOES NOT CONTAINS YOUR ENVIRONMENT";break;}
foreach($server in $SERVERS.$ENV){
Write-Host ""
Write-Host "SERVER : $server" -ForegroundColor Yellow
$NAME = "CONF","PRE","NRML"
$NAME | %{
Write-Host ("="*33),$_,("="*33)
Invoke-Command  -ComputerName $server -ScriptBlock  $Stop_POOLS -ArgumentList $_
}
}
}
$SET_RECYCLE_TIME={
Import-Module WebAdministration
param($TIME_)
$APPLICATION_POOLS=Get-IISAppPool |  Select-Object Name
$LIST_APPPOOL1=$using:LIST_APPPOOL
if($TIME_ -eq "TIME1" ){$LIST_TIME1=$using:LIST_TIME}elseif($TIME_ -eq "TIME2"){$LIST_TIME1=$using:LIST_TIME_}
#$LIST_TIME1=$using:LIST_TIME
#Write-Host $APPLICATION_POOLS1
#Write-Host $LIST_APPPOOL1
#Write-Host $LIST_TIME1
for ($i=0 ; $i -lt $APPLICATION_POOLS.Count ; $i++){
    $SERVER_POOLS=$APPLICATION_POOLS[$i].Name
    Write-Host $SERVER_POOLS
    if($LIST_APPPOOL1.Contains($SERVER_POOLS)){
    $APP_POOLS_INDEX =$LIST_APPPOOL1.IndexOf($SERVER_POOLS)
    Set-ItemProperty -Path IIS:\AppPools\$SERVER_POOLS -Name recycling.periodicRestart.schedule -value @{value = $LIST_TIME1[$APP_POOLS_INDEX]}
    Write-Host "$SERVER_POOLS ---->  TIME OF APPLICATION POOL HAS BEEN CHANGED BY SYSTEM" -ForegroundColor Green
    Set-ItemProperty -Path IIS:\AppPools\$SERVER_POOLS -Name Recycling.periodicRestart.time -Value "00:00:00"
    }
    else{
    Write-Warning "$SERVER_POOLS ----> SERVER LIST FILE DOES NOT CONTAIN THIS APPLICATION POOLS" 
    }
    #if(!$APPLICATION_POOLS.Contains($LIST.APP_POOLS[$i])){
    #Write-Warning "THIS SYSTEM DOESNOT CONTAINS YOUR APPLICATION WRITED ON YOUR LIST"
   # }
    #I MUST WRITE TO CHECK SERVER POOLS FROM SERVER LIST.MEAN ,IF THIS SERVER DOES NOT CONTAINS APPLICATIOON POOL WHERE IN THE LIST FILE, I MUST SEE NOTICE FOR THIS SITUATION.  
    }
}
$GET_RECYCLE_TIME={
    Import-Module WebAdministration
    $APPLICATION_POOLS=Get-IISAppPool |  Select-Object Name
    for ($i=0 ; $i -lt $APPLICATION_POOLS.Count ; $i++){
    $SERVER_POOLS=$APPLICATION_POOLS[$i].Name
    Write-host $SERVER_POOLS,"" -ForegroundColor Green -NoNewline
    #(Get-ItemProperty  "IIS:\AppPools\$SERVER_POOLS" -Name Recycling.periodicRestart.schedule.collection) | Select-Object Name
    $VALUE=(Get-ItemProperty  "IIS:\AppPools\$SERVER_POOLS" -Name Recycling.periodicRestart.schedule.collection) | Select-Object Value
    Write-host $VALUE,"" -ForegroundColor Magenta
}
}
function SET_RECYCLE(){
$ENV= Read-Host("Which environment do you want to the start from me( DEV | TEST | PREPROD | PROD)")
if(!$SERVERS[0].$ENV){Write-Warning "THIS SCRIPT DOES NOT CONTAINS YOUR ENVIRONMENT";break;}
Write-Host $LIST_TIME[0],$LIST_TIME1[0]
foreach($server in $SERVERS.$ENV){
if($server -eq "SERVERAAP14"){$T="TIME1"}elseif($server -eq "SERVERAAP15"){$T="TIME2"}
elseif($server -eq "SERVERAAP01"){$T="TIME1"}elseif($server -eq "SERVERAP02"){$T="TIME2"}
Write-Host ""
Write-Host "SERVER : $server" -ForegroundColor Yellow
Invoke-Command  -ComputerName $server -ScriptBlock  $SET_RECYCLE_TIME -ArgumentList $T
}
}

function GET_RECYCLE(){
$ENV= Read-Host("Which environment do you want to the start from me( DEV | TEST | PREPROD | PROD)")
if(!$SERVERS[0].$ENV){Write-Warning "THIS SCRIPT DOES NOT CONTAINS YOUR ENVIRONMENT";break;}
foreach($server in $SERVERS.$ENV){
Write-Host ""
Write-Host "SERVER : $server" -ForegroundColor Yellow
Invoke-Command  -ComputerName $server -ScriptBlock  $GET_RECYCLE_TIME 
}
}
