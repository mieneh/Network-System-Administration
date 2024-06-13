# CAU HINH DIA CHI IP CHO FIT-DC
$adapter = "Ethernet0"
$ipaddress = "192.168.1.2"
$subnetmask = "255.255.255.0"
$defaultgateway = "192.168.1.1"

New-NetIPAddress -InterfaceAlias $adapter -IPAddress $ipaddress -PrefixLength 24 -DefaultGateway $defaultgateway

Set-DnsClientServerAddress -InterfaceAlias $adapter -ServerAddresses $ipaddress

# CAU HINH DOMAIN CONTROLLER
# Cai dat AD DS
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Tao forest moi
Install-ADDSForest -DomainName "labtdtu.com" -InstallDns -Force:$true

# Kiem tra DC
Get-ADDomainController -Filter * | Select Name, Domain, IsGlobalCatalog, OperationMasterRoles


# Doi ten may server
Rename-Computer -NewName "FIT-DC" -Restart

# Cau hinh lai DNS
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses "192.168.1.2"

# Cau hinh ban ghi cho www.labtdtu.com
$webServerIP = "192.168.1.3"
$recordName = "www"
$zoneName = "labtdtu.com"
$dnsServer = "FIT-DC"

Add-DnsServerResourceRecordA -Name $recordName -ZoneName $zoneName -IPv4Address $webServerIP -ComputerName $dnsServer

Get-DnsServerResourceRecord -ZoneName "labtdtu.com" -Name "www" -RRType A -ComputerName "FIT-DC"

# -> CHUYEN QUA FIT-WEB

# CAI DAT AD CS
Install-WindowsFeature -Name AD-Certificate -IncludeManagementTools
Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools
Install-WindowsFeature -Name ADCS-Web-Enrollment 

# Cau hinh AD CS
Install-ADcsCertificationAuthority `
    –Credential (Get-Credential) `
    -CAType EnterpriseRootCA `
    –CACommonName “LABTDTU-CA” `
    –CADistinguishedNameSuffix “DC=labtdtu,DC=com” `
    –CryptoProviderName “RSA#Microsoft Software Key Storage Provider” `
    -KeyLength 2048 `
    –HashAlgorithmName SHA1 `
    –ValidityPeriod Years `
    –ValidityPeriodUnits 3 `
    –DatabaseDirectory “C:\windows\system32\certLog” `
    –LogDirectory “c:\windows\system32\CertLog” `
    –Force

Install-AdcsWebEnrollment

Install-WindowsFeature -Name ADCS-Online-Cert
Install-AdcsOnlineResponder

# -> CHUYEN QUA FIT-WEB
