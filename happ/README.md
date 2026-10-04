# Happ: service diagnostics and recovery on Linux

Если Happ показывает ошибку:

```text
Happ Client Service is unavailable. Please reinstall Happ to fix this issue.
```

сначала не удаляйте `~/.config`, `~/.local/share` или другие каталоги Happ целиком — там могут лежать рабочие подписки и настройки.

## 1. Базовая диагностика

Проверить, установлен ли пакет Happ:

```bash
dpkg -l | grep -i happ
```

Проверить системные сервисы:

```bash
systemctl list-units --type=service --all | grep -i happ
```

Проверить пользовательские сервисы:

```bash
systemctl --user list-units --type=service --all | grep -i happ
```

Найти конфиги, данные и кэш Happ:

```bash
find ~/.config ~/.local/share ~/.cache \
  -maxdepth 2 -iname '*happ*' 2>/dev/null
```

Можно выполнить всё подряд:

```bash
dpkg -l | grep -i happ
systemctl list-units --type=service --all | grep -i happ
systemctl --user list-units --type=service --all | grep -i happ

find ~/.config ~/.local/share ~/.cache \
  -maxdepth 2 -iname '*happ*' 2>/dev/null
```

## 2. Если `happd.service` есть и он active/running

Если GUI Happ уже закрыт, перезапустить сервис и сразу собрать диагностику:

```bash
sudo systemctl restart happd
sleep 2

systemctl status happd --no-pager -l

echo "===== HAPPD LOG ====="
journalctl -u happd -b --no-pager -n 100

echo "===== SERVICE FILE ====="
systemctl cat happd

echo "===== SOCKETS ====="
sudo ss -lxnp | grep -Ei 'happ|xray' || true
sudo ss -lntup | grep -Ei 'happ|xray' || true
```

После этого открыть Happ заново. Если ошибка остаётся, сохранить вывод блока выше — особенно `journalctl` и `systemctl cat happd`.

## 3. Если проблема появилась после случайного импорта JSON

Если вместо VPN-конфига в Happ был открыт обычный JSON-файл, сначала:

1. Полностью закрыть Happ, включая процесс/иконку в трее.
2. Если `happd.service` активен — выполнить блок перезапуска и диагностики выше.
3. Запустить Happ заново.
4. Если приложение открывается — удалить ошибочно импортированную запись и импортировать корректный VPN-конфиг.
5. Не удалять все каталоги Happ вслепую до проверки их содержимого.

## 4. Что прислать для разбора

Сохраните вывод этих команд:

```bash
dpkg -l | grep -i happ
systemctl list-units --type=service --all | grep -i happ
systemctl --user list-units --type=service --all | grep -i happ
find ~/.config ~/.local/share ~/.cache -maxdepth 2 -iname '*happ*' 2>/dev/null
```

Если `happd.service` уже найден:

```bash
systemctl status happd --no-pager -l
journalctl -u happd -b --no-pager -n 100
systemctl cat happd
sudo ss -lxnp | grep -Ei 'happ|xray' || true
sudo ss -lntup | grep -Ei 'happ|xray' || true
```

По этому выводу можно понять, что мешает GUI связаться с `happd`, не затрагивая остальные VPN-настройки.
