# CAU HINH DIA CHI IP CHO FIT-WEB
$adapter = "Ethernet0"
$ipaddress = "192.168.1.3"
$subnetmask = "255.255.255.0"
$defaultgateway = "192.168.1.1"
$dnsaddress = "192.168.1.2"

New-NetIPAddress -InterfaceAlias $adapter -IPAddress $ipaddress -PrefixLength 24 -DefaultGateway $defaultgateway

Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses $dnsaddress

# Doi ten may server
Rename-Computer -NewName "FIT-WEB" -Restart

# Join vao domain labtdtu.com
Add-Computer -DomainName "labtdtu.com" -Credential (Get-Credential) -Restart

# Cau hinh Web Server
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# -> CHUYEN QUA FIT-DC CAI DAT AD CS

# Tao Certificate Request

$CertName = "www.labtdtu.com"
$CSRPath = "C:\labtdtu.csr"
$INFPath = "C:\labtdtu.inf"

$INF =
@"
    [Version]

    [NewRequest]
    Subject = "CN=$CertName, OU=TDTU, O=TDTU, L=TDTU, S=TDTUs, C=US"
    KeySpec = 1
    KeyLength = 2048
    Exportable = TRUE
    MachineKeySet = TRUE
    SMIME = False
    PrivateKeyArchive = FALSE
    UserProtected = FALSE
    UseExistingKeySet = FALSE
    ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
    ProviderType = 12
    RequestType = PKCS10
    KeyUsage = 0xa0
    [EnhancedKeyUsageExtension]
    OID=1.3.6.1.5.5.7.3.1 
"@

$INF | Out-File -FilePath $INFPath -Force
certreq.exe -new $INFPath $CSRPath

# -> CHUYEN QUA IE DE TIEN HANH TAI FILE CER

$CertPath = "C:\Users\Administrator\AppData\Local\Microsoft\Windows\INetCache\IE\3S18VYG4\certnew.cer"

Import-Certificate -FilePath $CertPath -CertStoreLocation "Cert:\LocalMachine\My"

# Binding https cho default web site

$WebsiteName = "Default Web Site"

$Site = Get-Website -Name $WebsiteName

New-WebBinding -Name $Site.Name -IPAddress "*" -Port 443 -Protocol "https"

$Cert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -like "*www.labtdtu.com*" }
$Binding = Get-WebBinding -Name $Site.Name -Port 443
$Binding.AddSslCertificate($Cert.GetCertHashString(), "My")
