#===========================Central Control=======================================
Clear-Content .\Control\result.txt
$servers = get-content .\server
$request_tot=0
$istek_sayisi=0
function prompt {
Write-Host "###############################################"
Write-Host "|       Check Servers System Situation        |"
Write-Host "###############################################"
Write-Host "| 1) Check CPU And MEMORY Situation           |"
Write-Host "| 2) Check WORKER - PROCCESS Situation        |"
Write-Host "| 3) Check WEB SERVİCE Situation              |"
Write-Host "| 4) Check FREE SPACE Situation               |"
Write-Host "| 5) Check Event Messages Situation           |"
Write-Host "| 6) Check DB Connection Situation            |"
Write-Host "| 7) Check QUEU Count Situation               |"
Write-Host "| 8) Check ALL Situation                      |"
Write-Host "|_____________________________________________|"
$prompt= Read-Host("Which one do you want the control from me")
Switch ($prompt)
      {
       1 {cpu_memory}
       2 {worker_procsess}
       3 {web-svcs}
       4 {free-space}       
       5 {EventViewer}
       6 {DB_Connection}       
       7 {Queu_Count}
       8 {all}      
      }
}
$count=0
#Get-CimInstance -Class Win32_LogicalDisk | Select-Object @{Name="Size(GB)";Expression={$_.size/1gb}}, @{Name="Free Space(GB)";Expression={$_.freespace/1gb}}, @{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}, DeviceID, DriveType | Where-Object DriveType -EQ '3'

function cpu_memory { # CPU And Memory Check
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|-----------------------------Check Memory And CPU Usage Situation------------------------------------------------|" >>D:\Control\result.txt
Write-Output "" >> D:\Control\result.txt
#Clear-Content .\Control\result.txt
foreach ($server in $servers) {
$Session = New-PSSession -ComputerName $server
$Getcpuusage = Invoke-command -Session $Session -ScriptBlock { (Get-Counter -counter "\Processor(_Total)\% Processor Time").CounterSamples.CookedValue }
if ($Getcpuusage -gt 80) {
        $color_c = "X"
        }
    else{
        $color_c = "✓"
        }
$Memory= {  
    $system = Get-WmiObject win32_OperatingSystem
    $T_memory = $system.TotalVisibleMemorySize
    $F_memory = $system.FreePhysicalMemory
    $U_memory = $T_memory - $F_memory
    $U_memory_percent = [math]::Round(($U_memory / $T_memory) * 100,2);
    Write-Output $U_memory_percent
        }
    $GetMemoryUsage = Invoke-command -Session $Session -ScriptBlock $Memory    
    if ($GetMemoryUsage -gt 80) {
        $color_m = "X"
        }
    else{
        $color_m= "✓"
        }
$CPU = [math]::Round($Getcpuusage,2)
Write-Output "$count-Sunucu Adı:---> $server CPU(%)--->$CPU, MEM(%)--->$GetMemoryUsage Status:---> CPU($color_c) MEM($color_m)"  >>D:\Control\result.txt
$count=$count+1
        }
}
function worker_procsess{
$count_app=0
$count_web=0
Write-Output "" >>D:\Control\result.txt
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|-----------------------------Check Worker Proccess Count Situation-----------------------------------------------|" >>D:\Control\result.txt
$Session = New-PSSession -ComputerName $server
#Clear-Content .\Control\result.txt
foreach ($server in $servers) {    
    $Session = New-PSSession -ComputerName $server             
    if($server -match  "APP"){    
    
	$request = Invoke-command -Session $Session -ScriptBlock {Get-Item IIS:\AppPools\appsvc | Get-WebRequest }
    if ($request -eq $null) {    
        $request_tot=0 
        Start-Sleep -m 700            
        }
    else{          
        $istek_sayisi=$request.Count
        if($istek_sayisi -lt 2){
        $istek_sayisi=1
        }  
        
        $request_tot=$istek_sayisi
        Start-Sleep -m 700
        }    
    if ($Getcpuusage -gt 80) {
        $req_stts = "X"
        }
    else {
        $req_stts = "✓"
        }
      Write-Output "" >>D:\Control\result.txt
      Write-Output "$count_app-Sunucu Adı:---> $server REQ_COUNT --->$request_tot, Status:---> $req_stts"  >>D:\Control\result.txt       
      $count_app=$count_app+1
        }   
    if($server -match  "WEB"){
    $request = Invoke-command -Session $Session -ScriptBlock {Get-Item IIS:\AppPools\api | Get-WebRequest }
    if ($request -eq $null) {
        Start-Sleep -m 700
        $request_tot=0  
        }
    else{    
        $istek_sayisi=$request.Count
        if($istek_sayisi -lt 2){
        $istek_sayisi=1
        }       
        $request_tot=$istek_sayisi
        Start-Sleep -m 700
        }
    if ($Getcpuusage -gt 80) {
        $req_stts = "X"
        }
    else{
        $req_stts = "✓"
        }   
    Write-Output "" >>D:\Control\result.txt
    Write-Output "$count_web -Sunucu Adı:---> $server REQ_COUNT --->$request_tot, Status:---> $req_stts"  >>D:\Control\result.txt     
    $count_web=$count_web+1    
        }    
	    }
}
function web-svcs{
Write-Output "" >>D:\Control\result.txt
#Write-Host "-------------------------------------Check Web svc Situation---------------------------------------------------------"
Write-Output "|-----------------------------------------------------------------------------------------------------------------|">>D:\Control\result.txt
Write-Output "|---------------------------------------Check Web svc Situation-----------------------------------------------|" >>D:\Control\result.txt
$servers = get-content .\server
$SERVER_LIST = @{  
     WEB01 = "0.0.0.0","0.0.0.0.0", "0.0.0.0.0"
     WEB02 = "0.0.0.0","0.0.0.0.0", "0.0.0.0.0"
     WEB03 = "0.0.0.0","0.0.0.0.0", "0.0.0.0.0"
        }
$SERVER_LIST_APP = @{  
    WEB01 = "APP01"," APP03 "
    WEB02 = "APP02"," APP04 "
    WEB03 = "APP05"," APP07 "
        }
$CHECK_LIST_WEB = ("")
$CHECK_LIST_APP = ("")
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            svcPoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
        }
"@
[System.Net.svcPointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
foreach ($server in $servers) {
if($server -match  "WEB"){
    for($i=0; $i -lt $SERVER_LIST.$server.Count; $i++){
    $ilk=0;
	if ($i -le 0){
    for($j=0; $j -lt $CHECK_LIST_WEB.Count; $j++){
    $ipweb = $SERVER_LIST.$server.Item(0)
    $CHECK_LIST_WEB = (
    "https://$ipweb/api/svc.ashx",
    "https://$ipweb/api/hb.ashx"    
    )
    if($ilk -eq 0){
	#Write-Host "$server "  
    Write-Output "" >>D:\Control\result.txt
    Write-Output " $server "  >>D:\Control\result.txt 
    $ilk = 1
	}		  
    #Write-Host $CHECK_LIST_WEB[$j] -NoNewline
    #Write-Output $CHECK_LIST_WEB[$j]  >>D:\Control\result.txt 
	$request = Invoke-WebRequest -Uri $CHECK_LIST_WEB[$j] -MaximumRedirection 3 -ErrorAction SilentlyContinue -UseBasicParsing
    if($request.Content.Contains("Not Authorized") -eq "True" -or $request.Content.Contains("SUCCESS") -eq "True" -or $request.Content.Contains("OK") -eq "True" -or $request.RawContent.Contains("appsvcClient")){
    $status=" ✓"
	#Write-Host "-->Success" 
    }
    else{
    $status=" X"
	#Write-Host " Not Successfull"  
    }   
    #Write-Output $CHECK_LIST_WEB[$j],$status -NoNewline >>D:\Control\result.txt
	Add-Content "D:\Serkan\Control\result.txt" -Value $CHECK_LIST_WEB[$j]," ",$status -NoNewline
    Write-Output "" >>D:\Control\result.txt
    Write-Output "_______________________" >>D:\Control\result.txt
    }    
    }
    elseif($i -gt 0){ 
    $ilk1=0;   
    for($k=0; $k -lt $CHECK_LIST_APP.Count; $k++){ 
    $ipapp = $SERVER_LIST.$server.Item($i)
    $CHECK_LIST_APP = (
    "http://$ipapp/hb.UI/Default.aspx",
    "https://$ipapp/appsvc/svc.svc",
    "https://$ipapp/appsvc/Maintenance/StatusCheckHandler.ashx?status=check"
    )
    if($i -eq 1){
    if($ilk1 -eq 0){
	#Write-Host "$server "; 
    #Write-Host $SERVER_LIST_APP.$server  
	#Write-Output $SERVER_LIST_APP.$server  >>D:\Control\result.txt
    Write-Output "" >>D:\Control\result.txt
    Add-Content "D:\Serkan\Control\result.txt" -Value $SERVER_LIST_APP.$server -NoNewline
    Write-Output "" >>D:\Control\result.txt
    $ilk1 = 1
	}		 
    }
    #Write-Host $CHECK_LIST_APP[$k] -NoNewline      
    
	$request = Invoke-WebRequest -Uri $CHECK_LIST_APP[$k] -MaximumRedirection 3 -ErrorAction SilentlyContinue -UseBasicParsing    
    if($request.Content.Contains("Not Authorized") -eq "True" -or $request.Content.Contains("SUCCESS") -eq "True" -or $request.Content.Contains("OK") -eq "True" -or $request.RawContent.Contains("appsvcClient")){
    #Write-Host "-->Success" 
    $status=" ✓"
	}
    else{
    #Write-Host " Not Successfull"  
    $status=" X"
	}     
    #Write-Output $CHECK_LIST_APP[$k],$status  >>D:\Control\result.txt
	Add-Content "D:\Serkan\Control\result.txt" -Value $CHECK_LIST_APP[$k]," ",$status -NoNewline
    Write-Output "" >>D:\Control\result.txt
    Write-Output "_______________________" >>D:\Control\result.txt
    }      
    }    
    } 
    }            
    }
}
function free-space{
Write-Output "" >>D:\Control\result.txt
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|----------------------------------------Check Free Space Situation-----------------------------------------------|" >>D:\Control\result.txt
$servers = get-content .\server
foreach ($server in $servers) {
$Session = New-PSSession -ComputerName $server
$FreeSpace= Invoke-Command -Session $Session -ScriptBlock { 
#Get-WmiObject -Class Win32_logicaldisk | Select-Object @{Name="Size(GB)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb));}} , DeviceID, DriveType | Where-Object DriveType -EQ '3'
Get-CimInstance -Class CIM_LogicalDisk | Select-Object @{Name="Size(GB)"  
Expression={$_.size/1gb}}, @{Name="Free Space(GB)";
Expression={$_.freespace/1gb}}, @{Name="Free (%)";
Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}, DeviceID, DriveType | Where-Object DriveType -EQ '3'
    }
Write-Output "" >>D:\Control\result.txt
Write-Output $server >>D:\Control\result.txt
Write-Output "Free Space (GB)" >>D:\Control\result.txt
for ($i=0; $i -lt $FreeSpace.count; $i++){
$Res= [math]::Round($FreeSpace[$i].'Free Space(GB)',2)
if($FreeSpace[$i].'Free Space(GB)' -lt 10){
$disc_stts = "X"
    }
else{
$disc_stts = "✓"
    }
#Write-Host $FreeSpace[$i].'DeviceID'$Res,$disc_stts"" -NoNewline
#Write-Output $FreeSpace[$i].'DeviceID'$Res,$disc_stts >>D:\Control\result.txt
Add-Content "D:\Serkan\Control\result.txt" -Value " ",$FreeSpace[$i].'DeviceID',$Res," ",$disc_stts -NoNewline
#Write-Output "" >>D:\Control\result.txt   
    } 
    }
Write-Output "" >>D:\Control\result.txt
    }
function EventViewer{
$choose = Read-Host "Specific or All (S | A | L(Latest Error Record))"
Write-Output "" >>D:\Control\result.txt
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|----------------------------------------Check Event Viewer Situation---------------------------------------------|" >>D:\Control\result.txt
if($choose -eq  "S"){
$server_name = Read-Host "Which Server Do You Want Me To Check ? (For Examp. MOBAPP01):"
$Prompt={
$kind = Read-Host "Which Event Kind Do You Want Me To Check ? (System, Application)"
$type=Read-Host "Which Event Type Do You Want Me To Check ? (Critical,Error,Warning,Information)"
$time=Read-Host "How Many time Do You Want Before At The Moment(Just Write Number For.Exmp. 1,2,....24)"
$Begin =Get-Date
$Start = $Begin.AddHours(-$time)
$End = Get-Date
Get-EventLog  -LogName $kind -EntryType $type -After $start -Before $End
#Write-Output $Event
    }
$Session = New-PSSession  -ComputerName $server_name
$Event_Log = Invoke-Command -Session $Session -ScriptBlock $Prompt
if($Event_Log -eq $null){
    Write-Output "I could not find Event Record" >>D:\Control\result.txt
    }else{
    Write-Output $Event_Log >>D:\Control\result.txt 
    }

    }
    elseif($choose -eq  "A") {
$servers = get-content .\server
$kind = Read-Host "Which Event Kind Do You Want Me To Check ? (System, Application)"
$type=Read-Host "Which Event Type Do You Want Me To Check ? Please Write Number Like This(1 or 1,2) (1=Critical,2=Error,3=Warning,4=Information)"
$time=Read-Host "How Many time Do You Want Before At The Moment(Just Write Number For.Exmp. 1,2,....24)"
$Begin =Get-Date
$Start = $Begin.AddHours(-$time)
$End = Get-Date
foreach ($server in $servers) {
$Event_Log = Get-WinEvent @{logname=$kind; level=$type} -ComputerName $server | Where-Object {$_.TimeCreated -gt $Start -and $_.timecreated -lt $End} | Select-Object TimeCreated, Id, LevelDisplayName,Message
Write-Output $server >>D:\Control\result.txt
   if($Event_Log -eq $null){
    $status = "I Could Not Find Record"
   }
   else{
   Write-Output $Event_Log >>D:\Control\result.txt
   }
   }
   }elseif($choose -eq  "L"){
   $count=Read-Host "How Many Do You Want Last Event Record"
foreach ($server in $servers) {
Write-Output "======================$server==========================" >>D:\Control\result.txt
$Event_Log=Get-EventLog  -ComputerName $server -LogName System -EntryType Error -Newest $count
#$Begin = Get-Date -Date '5/11/2021 00:00:00'
#$End = Get-Date -Date '5/15/2021 00:00:00'
#$Event_Log=Get-EventLog  -ComputerName $server -LogName System -EntryType Error  -After $Begin -Before $End
if ($Event_Log -eq $null){
    Write-Output "I Could Not Find Error Event Records" >>D:\Control\result.txt
    }
    else{
    Write-Output $Event_Log >>D:\Control\result.txt
    }
    }
    }else{
    Write-Host "This Script Does Not Contain Your Choosen Command" >>D:\Control\result.txt
    }  
   
   
   
   } 
#========================================================================================================
function Db_Connection{
Write-Output "" >>D:\Control\result.txt
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|----------------------------------------Check DB CONNECT Situation-----------------------------------------------|" >>D:\Control\result.txt
$servers = get-content .\server
$count_app = 1
foreach ($server in $servers) {
if($server -match  "APP"){
$Session = New-PSSession  -ComputerName $server
$db_con = Invoke-command -Session $Session -ScriptBlock {netstat -ano | findstr "1433"}
$db_count = $db_con.Count
if ($db_count -eq 0){
$db_con_status= "May Have Problem"
}else {
$db_con_status= "Normal"
}
Write-Output "$count_app-Sunucu Adı:---> $server DB_CON_COUNT --->$db_count, Status:---> $db_con_status"  >>D:\Control\result.txt         
$count_app=$count_app+1;    
    }
    }
    }
#========================================================================================================
function Queu_Count{
Write-Output "" >>D:\Control\result.txt
Write-Output "|-----------------------------------------------------------------------------------------------------------------|" >>D:\Control\result.txt
Write-Output "|----------------------------------------Check QUEU COUNT Situation-----------------------------------------------|" >>D:\Control\result.txt
$servers = get-content .\server
foreach ($server in $servers) {
if($server -match  "APP"){
$Session = New-PSSession  -ComputerName $server
$queu = Invoke-command -Session $Session -ScriptBlock {Get-WmiObject Win32_PerfFormattedData_msmq_MSMQQueue}
Write-Output "Sunucu Adı:---> $server "  >>D:\Control\result.txt
Write-Output " "  >>D:\Control\result.txt
for($i=0; $i -lt $queu.count; $i++){
$queu_name=$queu[$i].Name.Split('\')[-1]
$queu_count=$queu[$i].MessagesinQueue
if($queu_count -gt 1000){$status_queu=" X"}else{$status_queu= " ✓"}
Write-Output "QUEU_NAME= $queu_name  QUEU_COUNT= $queu_count $status_queu"  >>D:\Control\result.txt
    }
Write-Output " "  >>D:\Control\result.txt     
    }
    }
}
function all{
cpu_memory
worker_procsess
free-space
web-svcs
Db_Connection
Queu_Count    
    }