#!/bin/bash
# Debian XFCE installer (clean + fixed by Lixin & ChatGPT 2025-10)

set -e

DEBIANPATH="/data/local/tmp/chrootDebian"
BUSYBOX=$(command -v busybox)
PREFIX_PATH="/data/data/com.termux/files/usr"
ROOTFS_URL="https://github.com/LinuxDroidMaster/Termux-Desktops/releases/download/Debian/debian12-arm64.tar.gz"
SCRIPTS_URL="https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/scripts"

echo "=== Debian XFCE Installer ==="

# Root check
[ "$(id -u)" != "0" ] && { echo "[!] Please run as root (su)"; exit 1; }
[ -z "$BUSYBOX" ] && { echo "[!] BusyBox not found!"; exit 1; }

# Prepare directories
echo "[*] Preparing directories..."
$BUSYBOX mkdir -p "$DEBIANPATH"

# Download Debian rootfs
if [ ! -f "$DEBIANPATH/debian12-arm64.tar.gz" ]; then
    echo "[*] Downloading Debian rootfs..."
    $BUSYBOX wget -O "$DEBIANPATH/debian12-arm64.tar.gz" "$ROOTFS_URL"
else
    echo "[!] Rootfs already exists, skipping download."
fi

# Extract rootfs
if [ ! -d "$DEBIANPATH/bin" ]; then
    echo "[*] Extracting Debian rootfs..."
    cd "$DEBIANPATH"
    tar -xpf debian12-arm64.tar.gz --numeric-owner
else
    echo "[!] Rootfs already extracted, skipping."
fi
if [ -d "$DEBIANPATH/debian12-arm64" ]; then
    DEBIANPATH="$DEBIANPATH/debian12-arm64"
fi

# Mount necessary paths
echo "[*] Mounting system paths..."
for d in dev sys proc dev/pts dev/shm sdcard; do
    $BUSYBOX mkdir -p "$DEBIANPATH/$d"
done
$BUSYBOX mount -o remount,dev,suid /data
$BUSYBOX mount --bind /dev "$DEBIANPATH/dev" || true
$BUSYBOX mount --bind /sys "$DEBIANPATH/sys" || true
$BUSYBOX mount --bind /proc "$DEBIANPATH/proc" || true
$BUSYBOX mount -t devpts devpts "$DEBIANPATH/dev/pts" || true
$BUSYBOX mount -t tmpfs -o size=256M tmpfs "$DEBIANPATH/dev/shm" || true
$BUSYBOX mount --bind /sdcard "$DEBIANPATH/sdcard" || true

# Configure base environment (silent, no /etc/profile call)
echo "[*] Configuring base environment..."
$BUSYBOX chroot "$DEBIANPATH" /bin/bash -c '
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "127.0.0.1 localhost" > /etc/hosts
groupadd -g 3003 aid_inet 2>/dev/null || true
groupadd -g 3004 aid_net_raw 2>/dev/null || true
groupadd -g 1003 aid_graphics 2>/dev/null || true
usermod -g 3003 -G 3003,3004 -a _apt 2>/dev/null || true
usermod -G 3003 -a root 2>/dev/null || true
apt update -y >/dev/null 2>&1
apt install -y sudo nano vim net-tools git dbus-x11 xfce4 xfce4-terminal >/dev/null 2>&1
'
echo "[✓] Base environment configured."

# Ask for username
echo -n "Enter username for Debian [default: lixin]: "
read USERNAME
[ -z "$USERNAME" ] && USERNAME="lixin"

# Create user
$BUSYBOX chroot "$DEBIANPATH" /bin/bash -c "
if ! id $USERNAME >/dev/null 2>&1; then
  adduser --disabled-password --gecos '' $USERNAME
  echo '$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
  usermod -aG aid_inet $USERNAME
fi
"
echo "[✓] User '$USERNAME' created."

# Download scripts
echo "[*] Downloading runtime scripts..."
$BUSYBOX mkdir -p "$DEBIANPATH/scripts"
for FILE in start-x11.sh start-cli.sh dx.sh dx-cli.sh; do
    $BUSYBOX wget -q -O "$DEBIANPATH/scripts/$FILE" "$SCRIPTS_URL/$FILE"
done
chmod +x "$DEBIANPATH/scripts/"*.sh

# Copy launchers to Termux
$BUSYBOX cp "$DEBIANPATH/scripts/dx.sh" "$PREFIX_PATH/bin/dx"
$BUSYBOX cp "$DEBIANPATH/scripts/dx-cli.sh" "$PREFIX_PATH/bin/dx-cli"
chmod +x "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# Inject username
$BUSYBOX sed -i "s|USER=.*|USER=\"$USERNAME\"|g" "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# Add aliases
if ! grep -q "alias debian=" "$PREFIX_PATH/etc/bash.bashrc" 2>/dev/null; then
    echo "alias debian='dx'" >> "$PREFIX_PATH/etc/bash.bashrc"
    echo "alias debian-cli='dx-cli'" >> "$PREFIX_PATH/etc/bash.bashrc"
fi

echo ""
echo "[✓] Installation complete!"
echo "• GUI Mode  →  debian"
echo "• CLI Mode  →  debian-cli"
echo "• RootFS    →  $DEBIANPATH"
