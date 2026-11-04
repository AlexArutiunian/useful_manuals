# Автовосстановление Windows -> Wintun -> SOCKS5 Happ на Ubuntu.
# Запускается планировщиком Windows от SYSTEM с правами администратора.
$ErrorActionPreference = "Stop"
$dir = "C:\happ-tun"
$log = "$dir\autostart.log"
$proxy = "192.168.0.154:10808"

try {
    # Проверяем именно SOCKS5 Happ, а не обычный интернет Windows.
    $ip = & curl.exe -sS -4 --connect-timeout 4 --max-time 10 `
        --socks5-hostname $proxy https://api.ipify.org 2>$null

    if ($LASTEXITCODE -ne 0 -or
        $ip -notmatch '^\d{1,3}(\.\d{1,3}){3}$') {
        Set-Content $log "$(Get-Date) Happ SOCKS5 unavailable"
        exit 0
    }

    # Поднимаем процесс, если его нет.
    if (-not (Get-Process tun2socks -ErrorAction SilentlyContinue)) {
        Start-Process -FilePath "$dir\tun2socks.exe" `
            -WorkingDirectory $dir `
            -ArgumentList @(
                "--device", "wintun",
                "--proxy", "socks5://$proxy",
                "--interface", "Ethernet"
            ) -WindowStyle Hidden
    }

    # Индекс интерфейса при каждом запуске может меняться.
    $adapter = $null
    for ($i = 0; $i -lt 12; $i++) {
        $adapter = Get-NetAdapter -Name "wintun" -ErrorAction SilentlyContinue
        if ($adapter -and $adapter.Status -eq "Up") { break }
        Start-Sleep -Seconds 1
    }
    if (-not $adapter -or $adapter.Status -ne "Up") {
        throw "Wintun is unavailable"
    }

    # Адрес Wintun (не адрес локальной сети).
    $addr = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex `
        -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -eq "192.168.123.1" }

    if (-not $addr) {
        & netsh.exe interface ipv4 set address `
            "name=wintun" "source=static" `
            "addr=192.168.123.1" "mask=255.255.255.0" `
            "gateway=none" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to set Wintun IP" }
        Start-Sleep -Seconds 2
    }

    # Предпочтительный IPv4-маршрут через Wintun.
    $route = Get-NetRoute -InterfaceIndex $adapter.ifIndex `
        -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue

    if (-not $route) {
        & netsh.exe interface ipv4 add route `
            "0.0.0.0/0" "wintun" "192.168.123.1" `
            "metric=1" "store=active" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "Failed to set default route" }
    }

    Set-Content $log "$(Get-Date) OK - Wintun $($adapter.ifIndex) - VPN $ip"
}
catch {
    Set-Content $log "$(Get-Date) ERROR: $_"
}
