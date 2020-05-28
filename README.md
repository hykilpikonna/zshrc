# HyDEV Server Setup
Notes about how to setup a Fedora 30 server for HyDEV

### 1. Connection

Connect to ethernet first:

```bash
nmcli
nmcli d connect <device>
```

Setting up wifi:

```bash
dnf install NetworkManager-tui wpa_supplicant
systemctl enable wpa_supplicant
reboot
nmtui
```

And then select the wifi and connect.
