#requires -RunAsAdministrator

# Coleta informações sobre as máquinas 
$HostName = ${env:COMPUTERNAME}
$User = ${env:USERNAME}
$IP = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp).IPAddress
# Coleta Informações sobre o Windows Defender
$DefenderStatus = Get-MpComputerStatus
# Coleta o nome do sistema operacional
$OS = (Get-ComputerInfo -Property OSName).OSName

$DefenderInformation = [PSCustomObject]@{
    # Computador
    'Computador'                     = $HostName 
    'Usuario'                        = $User
    'IP'                             = $IP
    'Sistema Operacional'            = $OS
    # Gerais Defender
    'Versao do produto'              = $DefenderStatus.AMProductVersion
    'Versao do engenharia'           = $DefenderStatus.AMEngineVersion
    'Versao do servico'              = $DefenderStatus.AMServiceVersion
    'Estado Defender'                = $DefenderStatus.AMServiceEnabled
    # Antivírus 
    'Estado Antivirus'               = if ($DefenderStatus.AntivirusEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (Antivirus)' = $DefenderStatus.AntivirusSignatureLastUpdated
    'Analise de Comportamento'       = if ($DefenderStatus.BehaviorMonitorEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    # Antispyware
    'Estado Spyware'                 = if ($DefenderStatus.AntispywareEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (Spyware)'   = $DefenderStatus.AntivirusSignatureLastUpdated
    # NIS (Network Inspection)
    'Estado NIS'                     = if ($DefenderStatus.AntivirusEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (NIS)'       = $DefenderStatus.AntivirusSignatureLastUpdated
    # Real Time
    'Estado Protecao em Tempo Real'  = if ($DefenderStatus.RealTimeProtectionEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }

}

# $PastaCompartilhada = 'D:\PROOF\SCCM-Scipt-Collector'

$DefenderInformation | Export-Csv "defender.csv" -Append -Force -NoTypeInformation
# $DefenderInformation | Export-Csv -Path "$PastaCompartilhada\sccm.csv" -Append -Force -NoTypeInformation