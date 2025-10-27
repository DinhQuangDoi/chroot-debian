#!/bin/bash
# Debian XFCE chroot installer remake

CHROOT="/data/local/tmp/chrootDebian"
ROOTFS_URL="https://github.com/LinuxDroidMaster/Termux-Desktops/releases/download/Debian/debian12-arm64.tar.gz"
BUSYBOX=$(command -v busybox)
PREFIX_PATH="/data/data/com.termux/files/usr/bin"

echo "=== Debian XFCE Installer ==="
[ "$(whoami)" != "root" ] && { echo "Run as root (su)"; exit 1; }

ping -c 1 8.8.8.8 >/dev/null 2>&1 || { echo "[!] No internet."; exit 1; }

# Download & extract
$BUSYBOX mkdir -p "$CHROOT"
[ -f "$CHROOT/debian12-arm64.tar.gz" ] || {
  echo "[*] Downloading Debian rootfs..."
 $BUSYBOX wget -O "$CHROOT/debian12-arm64.tar.gz" "$ROOTFS_URL" || exit 1
}
$BUSYBOX tar -xpf "$CHROOT/debian12-arm64.tar.gz" -C "$CHROOT" --numeric-owner || exit 1

echo "nameserver 8.8.8.8" > "$CHROOT/etc/resolv.conf"
echo "127.0.0.1 localhost" > "$CHROOT/etc/hosts"

# Execute some fixes
echo "[*] Configuring Debian environment..."
$BUSYBOX chroot "$CHROOT" /bin/sh -c '
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
apt update -y
apt upgrade -y
apt install -y nano vim net-tools sudo git
echo "Debian base configuration done."
'

# Install XFCE4 environment
echo "[*] Installing XFCE4 environment..."
$BUSYBOX chroot "$CHROOT" /bin/sh -c "
apt install -y dbus-x11 xfce4 xfce4-terminal policykit-1
"

# Create user
echo -n "Enter Debian username: "
read USERNAME
[ -z "$USERNAME" ] && { echo "[!] Username required."; exit 1; }

$BUSYBOX chroot "$CHROOT" /bin/sh -c "
adduser --disabled-password --gecos '' $USERNAME
echo '$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
usermod -aG aid_inet $USERNAME
"

# Download scripts
echo "[*] Downloading runtime scripts..."
wget -q -O "$HOME/start.sh" "https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/start.sh"
wget -q -O "$HOME/chroot.sh" "https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/chroot.sh"
chmod +x "$HOME/start.sh" "$HOME/chroot.sh"

# Create Termux launchers
ln -sf "$HOME/start.sh"  "$PREFIX_PATH/debian"
ln -sf "$HOME/chroot.sh" "$PREFIX_PATH/debian-cli"
chmod +x "$PREFIX_PATH/debian" "$PREFIX_PATH/debian-cli"

echo "=== Installation complete ==="
echo "• GUI Mode  →  debian"
echo "• CLI Mode  →  debian-cli"
