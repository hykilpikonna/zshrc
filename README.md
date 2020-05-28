# HyDEV Server Setup
Notes about how to setup a Fedora 32 server for HyDEV

## Wifi Connection for Potato Laptop Servers

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
