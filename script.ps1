# Informações sobre as máquinas 
$HostName = ${env:COMPUTERNAME}
$User = ${env:USERNAME}
$IP = (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp).IPAddress
# Informações sobre o Windows Defender
$DefenderStatus = Get-MpComputerStatus
# Nome do sistema operacional
$OS = (Get-ComputerInfo -Property OSName).OSName
# Data da última atualização
$LastUpdate = ((Get-HotFix -Description Update | Sort-Object InstalledOn -Descending)[0]).InstalledOn
# Data da última atualização de segurança
$LastSecurityUpdate = ((Get-HotFix -Description Security* | Sort-Object InstalledOn -Descending)[0]).InstalledOn
# Lista com HotFix's Instalados
$HotFixList = ''
Get-HotFix | ForEach-Object { if ($HotFixList -eq ''){$HotFixList += $_.HotFixID}else { $HotFixList += ', ' + $_.HotFixID } }

$Ouptut = [PSCustomObject]@{
    # Computador
    'Computador'                       = $HostName 
    'Usuario'                          = $User
    'IP'                               = $IP
    'Sistema Operacional'              = $OS
    # Gerais - Defender
    'Versao do Defender'               = $DefenderStatus.AMProductVersion
    'versao de Engenharia do Defender' = $DefenderStatus.AMEngineVersion
    'Versao de servico do Defender'    = $DefenderStatus.AMServiceVersion
    'Estado Defender'                  = if ($DefenderStatus.AMServiceEnabledf -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    # Antivírus - Defender 
    'Estado Antivirus'                 = if ($DefenderStatus.AntivirusEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (Antivirus)'   = $DefenderStatus.AntivirusSignatureLastUpdated
    'Analise de Comportamento'         = if ($DefenderStatus.BehaviorMonitorEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    # Antispyware - Defender
    'Estado Spyware'                   = if ($DefenderStatus.AntispywareEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (Spyware)'     = $DefenderStatus.AntivirusSignatureLastUpdated
    # NIS (Network Inspection) - Defender
    'Estado NIS'                       = if ($DefenderStatus.AntivirusEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    'Ultima atualizacao (NIS)'         = $DefenderStatus.AntivirusSignatureLastUpdated
    # Real Time - Defender
    'Estado Protecao em Tempo Real'    = if ($DefenderStatus.RealTimeProtectionEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }
    # Atualizações do Windwos
    'Ultima atualizacao no OS'         = $LastUpdate
    'Ultima atualizacao de seguranca'  = $LastSecurityUpdate 
    'Lista de HotFix'                  = $HotFixList
}

$PastaCompartilhada = Get-Location
Write-Output $Ouptut
$Ouptut | Export-Csv "$PastaCompartilhada\defender.csv" -Append -NoTypeInformation -UseQuotes AsNeeded