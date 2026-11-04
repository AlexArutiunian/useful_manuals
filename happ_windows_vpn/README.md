# Раздача Happ VPN с Ubuntu на Windows по Ethernet

Проверенная схема: Ubuntu 24.04 с Happ/Xray раздает SOCKS5-прокси, Windows 10 с `tun2socks` и Wintun отправляет через него обычный IPv4-трафик. Оба ПК подключены к одному роутеру кабелями. Дополнительный VPN-клиент на Windows не нужен.

## Схема и адреса

| Узел | Пример адреса |
| --- | --- |
| Роутер | `192.168.0.1` |
| Ubuntu, Ethernet `enp47s0` | `192.168.0.154` |
| Windows, Ethernet | `192.168.0.109` |
| SOCKS5 Happ на Ubuntu | `192.168.0.154:10808` |
| Виртуальный интерфейс Windows `wintun` | `192.168.123.1/24` |

Трафик: `Windows -> wintun -> tun2socks -> 192.168.0.154:10808 -> Happ/Xray -> VPN`.

Адреса приведены для конкретной локальной сети. При повторном использовании заменить их на свои; желательно закрепить адреса ПК в DHCP роутера. **На Windows обычный шлюз Ethernet остается `192.168.0.1`.** Весь трафик перенаправляется отдельным маршрутом через Wintun. Не переводить Ethernet на шлюз Ubuntu.

## 1. Проверить Happ на Ubuntu

Подключить Happ к VPN, включить в нем разрешение LAN-подключений и SOCKS5. Проверить терминалом Ubuntu:

```bash
ip -br addr show enp47s0
ip route | head -5
sudo ss -lntp | grep ':10808'
curl -4 --connect-timeout 5 --max-time 15 --socks5-hostname 127.0.0.1:10808 https://api.ipify.org
```

В рабочем состоянии `xray` слушает `*:10808` и возвращается IP VPN. Настройка LAN в Happ может менять адрес прослушивания: для удаленного подключения нужно, чтобы порт был доступен по `192.168.0.154`, а не только по `127.0.0.1`.

**Не запускать `socat` на `10809`: Happ/Xray может занимать этот порт сам.** В данной схеме `socat` вообще не используется.

Убедиться, что порт SOCKS5 не открыт из интернета (нет проброса порта на роутере); доступ разрешать только доверенным устройствам LAN. При включенном UFW можно ограничить TCP/10808 адресом Windows, предварительно проверив уже действующие правила.

## 2. Доступ к Windows без физического переключения

На Windows должен быть включен OpenSSH Server. Если уже работает SSH, ничего устанавливать не надо. С Ubuntu:

```bash
ssh alex@192.168.0.109
```

При предупреждении об изменении SSH host key сначала сравнить отпечаток с ключом на Windows, а не отключать проверку. На Windows:

```cmd
ssh-keygen -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
```

В консоли Windows проверить прямой SOCKS5:

```cmd
curl.exe -4 --connect-timeout 5 --max-time 15 --socks5-hostname 192.168.0.154:10808 https://api.ipify.org
```

Если ответ не получен, дальше не менять маршруты. Проверить `ss` на Ubuntu, настройки LAN в Happ и firewall.

## 3. Установить tun2socks и Wintun на Windows

Нужны Windows x64, права администратора и папка `C:\happ-tun`.

- Бинарный `tun2socks-windows-amd64.exe`: [xjasonlyu/tun2socks Releases](https://github.com/xjasonlyu/tun2socks/releases).
- `wintun.dll` (AMD64): [официальный Wintun](https://www.wintun.net/), выпуск 0.14.1.

Скачать `tun2socks-windows-amd64.zip` из Releases, распаковать `tun2socks-windows-amd64.exe` как `C:\happ-tun\tun2socks.exe`.

Если скачивание Wintun из Windows зависает, скачать ZIP на Ubuntu и переслать DLL по SSH:

```bash
cd /tmp
curl -fL --connect-timeout 10 --max-time 60 -o wintun.zip https://www.wintun.net/builds/wintun-0.14.1.zip
echo '07c256185d6ee3652e09fa55c0b673e2624b565e02c4b9091c79ca7d2f24ef51  wintun.zip' | sha256sum -c -
unzip -p wintun.zip wintun/bin/amd64/wintun.dll > wintun.dll
scp wintun.dll alex@192.168.0.109:C:/happ-tun/wintun.dll
```

Контрольная сумма соответствует официальной странице Wintun. Если проверка не прошла, не использовать архив.

На Windows:

```cmd
dir C:\happ-tun\tun2socks.exe C:\happ-tun\wintun.dll
```

В одной папке должны быть оба файла.

## 4. Ручной запуск и проверка

Запустить в Windows CMD с правами администратора:

```cmd
cd /d C:\happ-tun
start "tun2socks" /MIN C:\happ-tun\tun2socks.exe --device wintun --proxy socks5://192.168.0.154:10808 --interface Ethernet
netsh interface ipv4 show interfaces
```

Найти `wintun`. Его индекс, например `53`, **может меняться после перезапуска**. Настроить IP:

```cmd
netsh interface ipv4 set address name="wintun" source=static addr=192.168.123.1 mask=255.255.255.0 gateway=none
powershell -NoProfile -Command "Get-NetIPAddress -InterfaceAlias 'wintun' -AddressFamily IPv4"
```

Ожидается `192.168.123.1` со статусом `Preferred`.

Для безопасной проверки направить через Wintun лишь один IP. В примере ниже `53` надо заменить **текущим** индексом Wintun:

```cmd
route ADD 1.1.1.1 MASK 255.255.255.255 192.168.123.1 METRIC 1 IF 53
curl.exe --noproxy "*" -4 --connect-timeout 5 --max-time 15 https://1.1.1.1/cdn-cgi/trace
route DELETE 1.1.1.1
```

В успешном ответе Cloudflare поле `ip=` показывает VPN-адрес. После успешного теста добавить основной маршрут:

```cmd
netsh interface ipv4 add route 0.0.0.0/0 "wintun" 192.168.123.1 metric=1 store=active
curl.exe --noproxy "*" -4 --max-time 15 https://api.ipify.org
route print -4
```

В таблице маршрутов предпочтительна строка `0.0.0.0/0 On-link 192.168.123.1` с меньшей метрикой, чем у обычного роутера. В этом случае обычные IPv4 TCP-запросы идут через Happ. Соединения внутри подсети `192.168.0.0/24` продолжают идти напрямую, включая доступ к Ubuntu.

Чтобы вернуть обычный интернет:

```cmd
netsh interface ipv4 delete route 0.0.0.0/0 "wintun" 192.168.123.1 store=active
taskkill /F /IM tun2socks.exe
```

## 5. Автовосстановление Windows после перезагрузки

Готовый скрипт: [ensure-happ.ps1](ensure-happ.ps1). Он:
- проверяет прямой SOCKS5 Happ `192.168.0.154:10808`;
- запускает `tun2socks`, если процесса нет;
- заново находит индекс Wintun и возвращает IP `192.168.123.1`;
- восстанавливает активный маршрут `0.0.0.0/0` через Wintun;
- пишет состояние в `C:\happ-tun\autostart.log`.

С Ubuntu скопировать скрипт из клонированного репозитория на Windows:

```bash
git clone https://github.com/AlexArutiunian/useful_manuals.git
scp useful_manuals/happ_windows_vpn/ensure-happ.ps1 alex@192.168.0.109:C:/happ-tun/ensure-happ.ps1
```

В Windows CMD (администратор) создать задачу от SYSTEM, проверяющую состояние раз в минуту:

```cmd
schtasks /Create /F /TN "HappTunnel" /SC MINUTE /MO 1 /RU SYSTEM /RL HIGHEST /TR "powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\happ-tun\ensure-happ.ps1"
schtasks /Run /TN "HappTunnel"
type C:\happ-tun\autostart.log
```

Ожидаемый пример:

```text
11/04/2026 10:39:52 OK - Wintun 52 - VPN 31.170.22.200
```

Отключить автоматизацию:

```cmd
schtasks /Change /TN "HappTunnel" /Disable
netsh interface ipv4 delete route 0.0.0.0/0 "wintun" 192.168.123.1 store=active
taskkill /F /IM tun2socks.exe
```

Для удаления задачи: `schtasks /Delete /TN "HappTunnel" /F`.

**Happ на Ubuntu тоже должен быть подключен**. Включить его собственный автозапуск и автоподключение через настройки Happ, если они доступны. Эта инструкция не устанавливает отдельный systemd-сервис для Happ и не использует `socat`.

## 6. После перезагрузки

Перезагрузить только Windows, Ubuntu оставить включенной. Затем подключиться по SSH:

```bash
ssh alex@192.168.0.109
```

В Windows CMD:

```cmd
tasklist /FI "IMAGENAME eq tun2socks.exe"
type C:\happ-tun\autostart.log
route print -4
curl.exe --noproxy "*" -4 --max-time 15 https://api.ipify.org
```

Если `OK` есть, но VPN нет, проверить локальный SOCKS5 из Windows:

```cmd
curl.exe -4 --max-time 15 --socks5-hostname 192.168.0.154:10808 https://api.ipify.org
```

## Ограничения и диагностика

- **Не полноценный kill switch.** При остановке туннеля Windows может использовать обычный маршрут через `192.168.0.1`. Схема не гарантирует отсутствия утечек.
- **IPv6 не направляется этой конфигурацией через VPN.** Его отдельно проверить и при необходимости настроить/отключить.
- **DNS и UDP не гарантированы.** Проверить `nslookup`, приложения с UDP и утечки DNS отдельно. Настроенный SOCKS5/TUN и работающий браузер сами по себе не доказывают полный охват.
- **Смена IP Ubuntu нарушит подключение.** Закрепить `192.168.0.154` за Ubuntu в роутере.
- **Изменившийся индекс Wintun не ошибка.** При ручной настройке искать новый индекс в `netsh interface ipv4 show interfaces`; скрипт делает это автоматически.
- **Конфликт портов Happ:** не создавать сервис `socat` на `10809`. Если старая ошибочная служба `happ-lan-socks.service` осталась, отключить и удалить только ее:

```bash
sudo systemctl disable --now happ-lan-socks.service
sudo rm -f /etc/systemd/system/happ-lan-socks.service
sudo systemctl daemon-reload
sudo ss -lntp | grep -E ':10808|:10809'
```

В исправной конфигурации порты Happ обслуживает `xray`, а сторонний мост не нужен.

Источники: [tun2socks, официальные примеры для Windows](https://github.com/xjasonlyu/tun2socks/wiki/Examples), [Wintun](https://www.wintun.net/).
