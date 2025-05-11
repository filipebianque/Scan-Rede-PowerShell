<#
.SYNOPSIS
    Script completo de varredura de rede com detecção de MAC local
.DESCRIPTION
    Versão 2.5 com:
    - Detecção correta do MAC address para o host local
    - Tratamento especial para o IP da própria máquina
    - Compatibilidade com versões antigas do PowerShell
    - Interface aprimorada
.NOTES
    Autor: Filipe Bianque
    Versão: 2.5
    Data: $(Get-Date -Format "yyyy-MM-dd")
#>

# Configuração inicial
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Verifica e ajusta política de execução
if ((Get-ExecutionPolicy) -notin 'RemoteSigned', 'Bypass', 'Unrestricted') {
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
        Write-Host "`n[INFO] Política de execução ajustada para Bypass." -ForegroundColor Yellow
    } catch {
        Write-Host "`n[ERRO] Execute como administrador para ajustar a política." -ForegroundColor Red
        exit 1
    }
}

# Função para obter endereço de rede
function Get-NetworkAddress {
    param ([string]$IP)
    $bytes = [System.Net.IPAddress]::Parse($IP).GetAddressBytes()
    $bytes[3] = 0
    return [System.Net.IPAddress]::new($bytes).ToString()
}

# Função aprimorada para obter MAC address
function Get-MACAddress {
    param ([string]$IP)
    
    # Verifica se é o IP local
    $localIPs = @(Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -ne '127.0.0.1' } | Select-Object -ExpandProperty IPAddress)
    
    if ($localIPs -contains $IP) {
        try {
            $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
            if ($adapter) {
                return $adapter.MacAddress -replace '-', ':'
            }
            return "Local (não detectado)"
        } catch {
            return "Local (erro)"
        }
    }
    
    # Para outros IPs
    try {
        $arpOutput = arp -a | Select-String -Pattern "\s$IP\s"
        if ($arpOutput) {
            return ($arpOutput -split '\s+')[2] -replace '-', ':'
        }
        return "Indefinido"
    } catch {
        return "Erro"
    }
}

# Função para testar portas TCP
function Test-Port {
    param (
        [string]$IP,
        [int[]]$Ports = @(21, 22, 23, 80, 443, 3389, 8080),
        [int]$TimeoutMs = 300
    )
    $openPorts = @()
    foreach ($port in $Ports) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect($IP, $port, $null, $null)
            if ($asyncResult.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
                if ($tcpClient.Connected) {
                    $openPorts += $port
                    $tcpClient.EndConnect($asyncResult)
                }
            }
            $tcpClient.Close()
        } catch {}
    }
    return $openPorts
}

# Função para gerar intervalo de IPs
function Get-IPRange {
    param (
        [string]$StartIP,
        [string]$EndIP
    )
    try {
        $startBytes = [System.Net.IPAddress]::Parse($StartIP).GetAddressBytes()
        $endBytes = [System.Net.IPAddress]::Parse($EndIP).GetAddressBytes()
        
        if (-not ($startBytes[0..2] -join '.' -eq $endBytes[0..2] -join '.')) {
            throw "ERRO: Os IPs devem estar na mesma sub-rede /24"
        }
        
        $ipList = @()
        for ($i = $startBytes[3]; $i -le $endBytes[3]; $i++) {
            $ipList += ($startBytes[0..2] + $i) -join '.'
        }
        return $ipList
    } catch {
        Write-Host $_ -ForegroundColor Red
        exit 1
    }
}

# Interface do usuário
Clear-Host
Write-Host @"
=============================================
 SCRIPT DE VARREDURA DE REDE - v2.5
=============================================
"@ -ForegroundColor Cyan

# Mostra interfaces de rede
Write-Host "`n[INTERFACES DE REDE LOCAIS]" -ForegroundColor Green
Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object { $_.IPAddress -notmatch '^(127\.|169\.)' } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength |
    Format-Table -AutoSize

# Solicita intervalo de IPs
do {
    $validInput = $true
    $startIP = Read-Host "`nDigite o IP inicial (ex: 192.168.1.1)"
    $endIP = Read-Host "Digite o IP final (ex: 192.168.1.254)"
    
    try {
        $ipRange = Get-IPRange -StartIP $startIP -EndIP $endIP
        $networkIP = Get-NetworkAddress -IP $startIP
        
        if ($ipRange.Count -gt 256) {
            Write-Host "AVISO: Intervalo grande (>256 IPs). Continuar? (S/N)" -ForegroundColor Yellow
            $confirm = Read-Host
            if ($confirm -notmatch '^[sS]') { $validInput = $false }
        }
    } catch {
        Write-Host $_ -ForegroundColor Red
        $validInput = $false
    }
} while (-not $validInput)

# Execução da varredura
Write-Host "`n[CONFIGURACAO DA VARREDURA]" -ForegroundColor Yellow
Write-Host "Rede: $networkIP" -ForegroundColor Cyan
Write-Host "Intervalo: $startIP a $endIP ($($ipRange.Count) hosts)" -ForegroundColor Cyan
Write-Host "Portas verificadas: 21(FTP), 22(SSH), 23(Telnet), 80(HTTP), 443(HTTPS), 3389(RDP), 8080(Alt)" -ForegroundColor Cyan

$results = @()
$ping = New-Object System.Net.NetworkInformation.Ping
$totalIPs = $ipRange.Count
$current = 0

foreach ($ip in $ipRange) {
    $current++
    $progress = [math]::Round(($current/$totalIPs)*100)
    Write-Progress -Activity "Varrendo rede" -Status "$progress% completo - Testando $ip" -PercentComplete $progress
    
    try {
        $reply = $ping.Send($ip, 500)
        if ($reply.Status -eq 'Success') {
            Write-Host " [*] Host ativo: $ip" -ForegroundColor Green
            
            $hostname = try { 
                [System.Net.Dns]::GetHostEntry($ip).HostName 
            } catch { 
                "Desconhecido" 
            }
            
            $mac = Get-MACAddress -IP $ip
            $ports = Test-Port -IP $ip
            $portList = if ($ports.Count -gt 0) { $ports -join ", " } else { "Nenhuma" }
            
            $results += [PSCustomObject]@{
                IP = $ip
                Hostname = $hostname
                MAC = $mac
                PortasAbertas = $portList
                Status = "Ativo"
            }
        }
    } catch {
        Write-Debug "Erro no IP $ip"
    }
}

# Exibição dos resultados
Write-Progress -Activity "Varredura" -Completed

if ($results.Count -gt 0) {
    Write-Host "`n[RESULTADOS DA VARREDURA]" -ForegroundColor Green
    
    $results | Sort-Object { [System.Version]$_.IP } | Format-Table @(
        @{Label="IP"; Expression={$_.IP}; Width=15}
        @{Label="Hostname"; Expression={$_.Hostname}; Width=25}
        @{Label="Endereco MAC"; Expression={$_.MAC}; Width=17}
        @{Label="Portas Abertas"; Expression={$_.PortasAbertas}; Width=20}
        @{Label="Status"; Expression={$_.Status}}
    ) -AutoSize
    
    $csvFile = "Resultados_Varredura_$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    $results | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
    Write-Host "`nResultados exportados para: $csvFile" -ForegroundColor Cyan
} else {
    Write-Host "`nNenhum host ativo encontrado." -ForegroundColor Red
}

Write-Host "`nVarredura concluida.`n" -ForegroundColor Yellow