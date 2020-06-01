# HyDEV Server Setup
Notes about how to setup a Fedora 32 server for HyDEV

## 1. Wifi Connection for Potato Laptop Servers

Connect to ethernet first, and then:

```bash
nmcli
nmcli d connect <device>
```

Setting up wifi:
(If `wpa_supplicant` isn't installed, it would say "unavailable")

```bash
dnf install NetworkManager-tui wpa_supplicant
systemctl enable wpa_supplicant
reboot
```

And then select the wifi and connect:

```bash
nmtui
```

If you are using 811AC usb wifi adapter too, install the driver:

```bash
dnf install make automake gcc gcc-c++ kernel-devel dkms
mkdir drivers
cd drivers
git clone https://github.com/brektrou/rtl8821CU
cd rt18821CU
./dkms-install.sh
```

Toggle USB wifi adapter mode: (Find the coresponding device ID eg. `0bda:c811`)

```bash
lsusb
sudo usb_modeswitch -KW -v 0bda -p c811
reboot
nmtui
```

### Laptop Close Lid

```bash
nano /etc/systemd/logind.conf
# Add HandleLidSwitch=ignore
systemctl restart systemd-logind
```

## 2. Mariadb

Files: None

Steps:

```bash
dnf install mariadb mariadb-server
sctl enable mariadb
sctl start mariadb
mysql_secure_installation
mysql -p
GRANT ALL PRIVILEGES ON *.* TO 'root'@'...ip...' IDENTIFIED BY '...password...' WITH GRANT OPTION;
```

## 3. Nginx

Files:

* /etc/nginx/nginx.conf
* /etc/nginx/html/*
* /etc/letsencrypt/*
* /app/hres/*

Steps:

```bash
dnf install nginx certbot certbot-nginx
# And then you copy the config files
chron -Rt httpd_sys_content_t /app/
```

## 4. Shadowsocks

Files:

`/etc/shadowsocks-libev/hydev.json`:

```json
{
    "server": "0.0.0.0",
    "server_port": <Port>,
    "password": "<Password>",
    "method": "aes-256-cfb",
    "mode": "tcp_and_udp"
}
```

Steps:

```bash
dnf copr enable librehat/shadowsocks
dnf update
dnf install shadowsocks-libev
# And then you copy the config files
sctl enable shadowsocks-libev-server@hydev
sctl start shadowsocks-libev-server@hydev
```

## 5. Java Application Servers

Files:

* /app/depl/\<application\>
* /etc/systemd/system/\<application\>.service

```ini
[Unit]
Description=<name>

[Service]
WorkingDirectory=/app/depl/<application>/
ExecStart=/bin/bash launch.sh
User=jvmapps
Type=simple
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Steps:

```bash
groupadd -r appmgr
useradd -r -s /bin/false -g appmgr jvmapps
chown -R jvmapps:appmgr /app/depl/<application>/
sctl start <application>
sctl enable <application>
```

## 6. LAN File Servers (SMB)

https://www.jianshu.com/p/cc9da3a154a0

Files:

* /etc/samba/smb.conf

```ini
[global]
    workgroup = HYDEV
    security = user
    passdb backend = tdbsam

[data]
    comment = Shared data
    path = /mnt/data
    public = no
    admin users = admin
    valid users = @admin smb-user
    browseable = yes
    writable = yes
    create mask = 0777
    directory mask = 0777
    force directory mode = 0777
    force create mode = 0777
```

Steps:

```bash
dnf install samba
nano /etc/samba/smb.conf
groupadd -r samba
useradd -r -s /bin/false -g samba smb-user
smbpasswd -a smb-user
sctl enable smb nmb
sctl start smb nmb
```

If you are still using an NTFS drive:

```bash
dnf install ntfs-3g fuse
modprobe fuse
mount -t ntfs-3g /dev/sdb1 /mnt/data
nano /etc/fstab
# Add line: /dev/sdb1	        /mnt/data	        ntfs-3g	defaults        0 0
```

# 7. Firewall (UFW)

```bash
sctl disable firewalld
sctl stop firewalld
dnf install ufw
sctl enable ufw
sctl start ufw
ufw status
```
