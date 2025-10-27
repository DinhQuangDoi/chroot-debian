#!/bin/bash
# Enter Debian chroot CLI (with optional X11 access)
BUSYBOX=$(command -v busybox)
CHROOT="/data/local/tmp/chrootDebian"
TMPX11="/data/data/com.termux/files/usr/tmp/.X11-unix"

echo "[*] Preparing mounts..."
$BUSYBOX mount -o remount,dev,suid /data
for d in dev proc sys; do
  $BUSYBOX mount --bind /$d "$CHROOT/$d"
done
mkdir -p "$CHROOT/dev/shm" "$CHROOT/tmp"
$BUSYBOX mount -t tmpfs -o size=128M tmpfs "$CHROOT/dev/shm"

# --- Bind X11 socket (only if not mounted) ---
mkdir -p "$CHROOT/tmp/.X11-unix"
if ! mountpoint -q "$CHROOT/tmp/.X11-unix"; then
  $BUSYBOX mount --bind "$TMPX11" "$CHROOT/tmp/.X11-unix"
fi

echo "[*] Entering Debian chroot..."
$BUSYBOX chroot "$CHROOT" /bin/bash
