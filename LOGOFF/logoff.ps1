$servers = get-content .\servers
$Log_Off={
param(
[Parameter(Mandatory=$true)]  $Server_Name,
[Parameter(Mandatory=$true)]  $User
)
$serverName = $Server_Name
$USR = $User
$sessions = qwinsta  | ?{ $_ -notmatch '^ SESSIONNAME' } | %{
$item = "" | Select "Active", "SessionName", "Username", "Id", "State", "Type", "Device"
$item.Active = $_.Substring(0,1) -match '>'
$item.SessionName = $_.Substring(1,18).Trim()
$item.Username = $_.Substring(19,20).Trim()
$item.Id = $_.Substring(39,9).Trim()
$item.State = $_.Substring(48,8).Trim()
$item.Type = $_.Substring(56,12).Trim()
$item.Device = $_.Substring(68).Trim()
$item
} 
foreach ($session in $sessions){
if ($session.Username -ne "" -or $session.Username.Length -gt 1){
if($session.Username -eq "$USR"){
$Status = $true
$Current = $session      
}
else{
$Status = $false
}
}
}
if($Status  -eq $true){
Write-Host ("="*33),$Server_Name,("="*33)-ForegroundColor Green
Write-Host "Server Name ------>",$Server_Name -ForegroundColor Green
Write-Host "Your User Name---->",$Current.Username -ForegroundColor Green
Write-Host "Your Session ID---->"$Current.Id -ForegroundColor Green
logoff  $Current.Id
Write-Warning "Kullanıcı Adınınız Server İcerisinden Logoff Yapıldı ------> $Server_Name"
}
else{
Write-Host ("="*33),$Server_Name,("="*33)-ForegroundColor Green
Write-Host "İlgili Kullanıcı Server İcerisinde Bulunmamaktadır.------>" $Server_Name $USR -ForegroundColor Yellow
}
}
$servers | %{
$SRV_NAME =$_
try{
Invoke-Command -ComputerName $_ -ErrorAction Stop -ScriptBlock $Log_Off -ArgumentList $_,$User 
}catch{
Write-Host ("="*33),$SRV_NAME,("="*33)-ForegroundColor Green
Write-Host "Sunucuya Bağlantı Sağlanamadı----->"$SRV_NAME
}
}