# Seta o caminho de saída do arquivo 
$PastaCompartilhada = Get-Location
# Informações sobre as máquinas 
$HostName = ${env:COMPUTERNAME}
$User = ${env:USERNAME}
$IPList = ''
$AllIP = Get-NetIPAddress -AddressFamily IPv4
$AllIP  | ForEach-Object {
    if ($_.PrefixOrigin -ne "WellKnow" -and $_.InterfaceAlias -notlike "*WSL*" -and $_.InterfaceAlias -notlike "*VM*") {
        $IPList += $_.InterfaceAlias + ': ' + $_.IPAddress + '; ' 
    }
}
# Nome do sistema operacional
try {
    $OS = (Get-ComputerInfo -Property OSName -ErrorAction Stop).OSName 
}
catch {
    $OS = ((Get-WmiObject Win32_OperatingSystem).Name).split('|')[0]
}   
# Informações sobre o Antivírus
#try {
#    $EndpointSecurity = 'Defender'
#    $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
#}
#catch {
#    $EndpointSecurity = (Get-WmiObject -Namespace root/SecurityCenter2 -ClassName AntivirusProduct)[-1].displayName
#    $DefenderStatus = $null
#}
try {
    $DefenderStatus = Get-MpComputerStatus -ErrorAction Stop
}
catch {
    $DefenderStatus = $null
}
# Lista HotFix's Instalados e ordena por data de instalação
$AllHotFix = (Get-HotFix | Sort-Object -Property InstalledOn)
$UpdateList = ($AllHotFix | Where-Object -Property Description -Like 'Update')
$SecurityUpdateList = ($AllHotFix | Where-Object -Property Description -Like 'Security Update')
# Seta valores das variáveis
$HotFixList = ''
$LastUpdate = 'Sem atualizacoes'
$LastSecurityUpdate = 'Sem atualizacoes'

if ($null -ne $AllHotFix) {
    if ($null -ne $UpdateList) {
        # Data da última atualização
        $LastUpdate = $UpdateList[-1].InstalledOn
    }
    if ($null -ne $SecurityUpdateList) {
        # Data da última atualização de segurança
        $LastSecurityUpdate = $SecurityUpdateList[-1].InstalledOn
    }

    ForEach ($HotFix in $AllHotFix) { 
        if ($HotFixList -eq '') {
            $HotFixList += $HotFix.HotFixID 
        }
        else {
            $HotFixList += ', ' + $HotFix.HotFixID 
        } 
    }
}

# Cria o objeto de saída com as informações coletadas
$Ouptut = [PSCustomObject]@{
    # Computador
    'Computador'                       = $HostName 
    'Usuario'                          = $User
    'IP'                               = $IPList
    'Sistema Operacional'              = $OS

    # Gerais - Defender
    'Versao do Defender'               = $DefenderStatus.AMProductVersion
    'versao de Engenharia do Defender' = $DefenderStatus.AMEngineVersion
    'Versao de servico do Defender'    = $DefenderStatus.AMServiceVersion
    'Estado Defender'                  = if ($DefenderStatus.AMServiceEnabled -eq $true) { 'Habilitado' }else { 'Desabilitado' }

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

# Escreve a saída no terminal
# Write-Output $Ouptut

# Escreve a saída no arquivo 'defender.csv' no caminho de saída
Export-Csv -InputObject $Ouptut -LiteralPath "$PastaCompartilhada\defender.csv" -Append -NoTypeInformation 