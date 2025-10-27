#!/bin/bash
# Debian 12 XFCE Installer for Termux-X11 (by DinhQuangDoi 2025)

set -e

DEBIANPATH="/data/local/tmp/chrootDebian"
BUSYBOX=$(command -v busybox)
PREFIX_PATH="/data/data/com.termux/files/usr"
ROOTFS_URL="https://github.com/LinuxDroidMaster/Termux-Desktops/releases/download/Debian/debian12-arm64.tar.gz"
SCRIPTS_URL="https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/scripts"

echo "=== Debian XFCE Installer ==="

info() { echo -e "\e[1;36m[+] $1\e[0m"; }
success() { echo -e "\e[1;32m[✓] $1\e[0m"; }
error() { echo -e "\e[1;31m[!] $1\e[0m"; exit 1; }

# Kiểm tra quyền root
info "Checking environment..."
[ "$(id -u)" != "0" ] && error "Run this installer as root (su)."

# Chuẩn bị thư mục
info "Preparing directories..."
$BUSYBOX mkdir -p "$DEBIANPATH"
cd "$DEBIANPATH"

# Tải Debian rootfs
info "Downloading Debian rootfs..."
if [ ! -f debian12-arm64.tar.gz ]; then
    $BUSYBOX wget -O debian12-arm64.tar.gz "$ROOTFS_URL" || error "Failed to download rootfs."
else
    echo "[!] Rootfs already exists, skipping download."
fi

# Giải nén
info "Extracting Debian rootfs..."
$BUSYBOX tar -xpf debian12-arm64.tar.gz --numeric-owner -C "$DEBIANPATH" || error "Extraction failed."

# Mount cần thiết
info "Mounting environment..."
$BUSYBOX mount -o remount,dev,suid /data
$BUSYBOX mount --bind /dev $DEBIANPATH/dev
$BUSYBOX mount --bind /sys $DEBIANPATH/sys
$BUSYBOX mount --bind /proc $DEBIANPATH/proc
$BUSYBOX mount -t devpts devpts $DEBIANPATH/dev/pts
$BUSYBOX mkdir -p $DEBIANPATH/dev/shm
$BUSYBOX mount -t tmpfs -o size=256M tmpfs $DEBIANPATH/dev/shm
$BUSYBOX mount --bind /sdcard $DEBIANPATH/sdcard

# Cấu hình Debian
info "Configuring base environment..."
$BUSYBOX chroot "$DEBIANPATH" /bin/sh -c "
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
echo '127.0.0.1 localhost' > /etc/hosts
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
apt update -y && apt upgrade -y
apt install -y sudo nano vim net-tools git dbus-x11 xfce4 xfce4-terminal
"

success "Base environment configured."

# Tạo người dùng
echo ""
read -p "Enter username for Debian: " USERNAME
[ -z "$USERNAME" ] && USERNAME="lixin"

info "Creating user '$USERNAME'..."
$BUSYBOX chroot "$DEBIANPATH" /bin/sh -c "
adduser --disabled-password --gecos '' '$USERNAME'
echo '$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
usermod -aG aid_inet '$USERNAME'
"

success "User '$USERNAME' added."

# Tải script runtime
info "Downloading runtime scripts..."
mkdir -p "$DEBIANPATH/scripts" "$PREFIX_PATH/bin"

for FILE in start-x11.sh start-cli.sh dx.sh dx-cli.sh; do
    $BUSYBOX wget -O "$DEBIANPATH/scripts/$FILE" "$SCRIPTS_URL/$FILE" || error "Failed to fetch $FILE"
done

# Copy launcher sang Termux
$BUSYBOX cp "$DEBIANPATH/scripts/dx.sh" "$PREFIX_PATH/bin/dx"
$BUSYBOX cp "$DEBIANPATH/scripts/dx-cli.sh" "$PREFIX_PATH/bin/dx-cli"

chmod +x "$DEBIANPATH/scripts/"*.sh "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# Ghi đè USER vào script Termux
$BUSYBOX sed -i "s|USER=.*|USER=\"$USERNAME\"|g" "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# Thêm alias
info "Adding convenient aliases..."
if ! grep -q "alias debian=" "$PREFIX_PATH/etc/bash.bashrc" 2>/dev/null; then
    echo "alias debian='dx'" >> "$PREFIX_PATH/etc/bash.bashrc"
    echo "alias debian-cli='dx-cli'" >> "$PREFIX_PATH/etc/bash.bashrc"
fi

success "Aliases added (debian / debian-cli)."

# Hoàn tất
echo ""
success "Installation complete!"
echo "• GUI Mode  →  debian"
echo "• CLI Mode  →  debian-cli"
echo "• RootFS    →  $DEBIANPATH"
echo ""info "Extracting Debian rootfs..."
$BUSYBOX tar -xpf debian12-arm64.tar.gz --numeric-owner -C "$DEBIANPATH" || error "Extraction failed."

# ────────────────────────────────
info "Configuring base environment..."
$BUSYBOX chroot "$DEBIANPATH" /bin/sh -c "
echo 'nameserver 8.8.8.8' > /etc/resolv.conf
echo '127.0.0.1 localhost' > /etc/hosts
groupadd -g 3003 aid_inet
groupadd -g 3004 aid_net_raw
groupadd -g 1003 aid_graphics
usermod -g 3003 -G 3003,3004 -a _apt
usermod -G 3003 -a root
apt update -y && apt upgrade -y
apt install -y sudo nano vim net-tools git dbus-x11 xfce4 xfce4-terminal
"

success "Base environment configured."

# ────────────────────────────────
echo ""
read -p "Enter username for Debian: " USERNAME
[ -z "$USERNAME" ] && USERNAME="lixin"

info "Creating user '$USERNAME'..."
$BUSYBOX chroot "$DEBIANPATH" /bin/sh -c "
adduser --disabled-password --gecos '' '$USERNAME'
echo '$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
usermod -aG aid_inet '$USERNAME'
"

success "User '$USERNAME' added."

# ────────────────────────────────
info "Downloading runtime scripts..."
mkdir -p "$DEBIANPATH/scripts" "$PREFIX_PATH/bin"

for FILE in start-x11.sh start-cli.sh dx.sh dx-cli.sh; do
    $BUSYBOX wget -O "$DEBIANPATH/scripts/$FILE" "$SCRIPTS_URL/$FILE" || error "Failed to fetch $FILE"
done

# Termux-side launchers
$BUSYBOX cp "$DEBIANPATH/scripts/dx.sh" "$PREFIX_PATH/bin/dx"
$BUSYBOX cp "$DEBIANPATH/scripts/dx-cli.sh" "$PREFIX_PATH/bin/dx-cli"

chmod +x "$DEBIANPATH/scripts/"*.sh "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# Update username inside scripts
$BUSYBOX sed -i "s|USER=.*|USER=\"$USERNAME\"|g" "$PREFIX_PATH/bin/dx" "$PREFIX_PATH/bin/dx-cli"

# ────────────────────────────────
info "Adding convenient aliases..."
if ! grep -q "alias debian=" "$PREFIX_PATH/etc/bash.bashrc" 2>/dev/null; then
    echo "alias debian='dx'" >> "$PREFIX_PATH/etc/bash.bashrc"
    echo "alias debian-cli='dx-cli'" >> "$PREFIX_PATH/etc/bash.bashrc"
fi

success "Aliases added (debian / debian-cli)."

# ────────────────────────────────
echo ""
success "Installation complete!"
echo "• GUI Mode  →  debian"
echo "• CLI Mode  →  debian-cli"
echo "• RootFS    →  $DEBIANPATH"
echo ""    mkdir -p "$CHROOT/dev/pts" "$CHROOT/dev/shm" "$CHROOT/sdcard"
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
