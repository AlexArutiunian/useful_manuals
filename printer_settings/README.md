# Setup printer device on Linux (Kali - Debian)

Useful links

* [video about settings trough lpadmin](https://www.youtube.com/watch?v=4hXg0-7qzC0)
* [discussion problems on stackexchenge](https://unix.stackexchange.com/questions/627597/hplip-cannot-be-installed-on-system-with-disabled-root-user-password-incorrect)

This helps on my home-server with connection to my printer 

Exactly these lines worked:
The user_conf file is located at ~/.hplip/hplip.conf. So if you create or modify that file to contain the following configs:
```
[authentication]
su_sudo=sudo
```
it will override the distro mapping and force use of sudo to obtain root access even on an su distribution, when the installer is run under your user account.

* [discussion on another forum](https://forums.linuxmint.com/viewtopic.php?t=282274)

This helps on my laptop (PC) with connection to my printer

```
apt install --reinstall hplip hplip-data
apt install --reinstall python3
```
BUT I think the approach from 2nd bullet-point is more suitable for a general case.
