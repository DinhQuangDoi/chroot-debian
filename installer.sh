#!/system/bin/sh
# Debian 12 XFCE chroot installer for Termux-X11
# Run as root inside Termux:
# su
# busybox wget -O installer.sh https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/installer.sh
# chmod +x installer.sh && sh installer.sh

goodbye() { echo -e "\e[1;31m[!] Something went wrong. Exiting...\e[0m"; exit 1; }
progress() { echo -e "\e[1;36m[+] $1\e[0m"; }
success() { echo -e "\e[1;32m[✓] $1\e[0m"; }

CHROOT="/data/local/tmp/chrootDebian"
ROOTFS_URL="https://github.com/LinuxDroidMaster/Termux-Desktops/releases/download/Debian/debian12-arm64.tar.gz"

main() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "\e[1;31m[!] Run this script as root.\e[0m"; exit 1
    fi

    mkdir -p "$CHROOT" || goodbye
    cd "$CHROOT" || goodbye

    progress "Downloading Debian 12 rootfs..."
    if [ ! -f debian12-arm64.tar.gz ]; then
        busybox wget -O debian12-arm64.tar.gz "$ROOTFS_URL" || goodbye
    else
        echo "[!] Found existing rootfs, skipping download."
    fi

    progress "Extracting rootfs..."
    tar --numeric-owner -xpf debian12-arm64.tar.gz -C "$CHROOT" >/dev/null 2>&1 || goodbye
    success "Rootfs extracted successfully."

    progress "Applying Android mount and network setup..."
    busybox mount -o remount,dev,suid /data
    for d in dev sys proc; do busybox mount --bind /$d "$CHROOT/$d"; done
    mkdir -p "$CHROOT/dev/pts" "$CHROOT/dev/shm" "$CHROOT/sdcard"
    busybox mount -t devpts devpts "$CHROOT/dev/pts"
    busybox mount -t tmpfs -o size=256M tmpfs "$CHROOT/dev/shm"
    busybox mount --bind /sdcard "$CHROOT/sdcard"

    echo "nameserver 8.8.8.8" > "$CHROOT/etc/resolv.conf"
    echo "127.0.0.1 localhost" > "$CHROOT/etc/hosts"

    progress "Configuring base system..."
    busybox chroot "$CHROOT" /bin/sh -c '
        apt update -y && apt install -y sudo nano vim net-tools git dbus-x11 xfce4 xfce4-terminal policykit-1;
        groupadd -g 3003 aid_inet 2>/dev/null || true;
        groupadd -g 3004 aid_net_raw 2>/dev/null || true;
        groupadd -g 1003 aid_graphics 2>/dev/null || true;
        usermod -g 3003 -G 3003,3004 -a _apt 2>/dev/null || true;
        usermod -G 3003 -a root 2>/dev/null || true;
        echo "Base system configured."
    '
    success "Debian environment configured."

    echo -n "Enter username: "
    read USERNAME
    [ -z "$USERNAME" ] && USERNAME="user"
    busybox chroot "$CHROOT" /bin/sh -c "
        adduser --disabled-password --gecos '' $USERNAME || true
        echo '$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
        usermod -aG aid_inet $USERNAME || true
    "
    success "User $USERNAME added."

    progress "Downloading start and chroot scripts..."
    busybox wget -O "$CHROOT/start.sh" https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/start.sh
    busybox wget -O "$CHROOT/chroot.sh" https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/chroot.sh
    chmod +x "$CHROOT"/start.sh "$CHROOT"/chroot.sh

    ln -sf "$CHROOT/start.sh" /data/data/com.termux/files/usr/bin/debian
    ln -sf "$CHROOT/chroot.sh" /data/data/com.termux/files/usr/bin/debian-cli
    chmod +x /data/data/com.termux/files/usr/bin/debian*

    success "Installation complete!"
    echo "GUI Mode:  debian"
    echo "CLI Mode:  debian-cli"
}

main "$@"'

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
