#!/data/data/com.termux/files/usr/bin/bash
# Debian CLI launcher for Termux

CHROOT="/data/local/tmp/chrootDebian"
USER="lixin"
BUSYBOX=$(command -v busybox)

echo "[*] Preparing mounts..."
for d in dev sys proc dev/pts dev/shm tmp run/dbus sdcard; do
  su -c "$BUSYBOX mkdir -p $CHROOT/$d"
done

su -c "$BUSYBOX mount -o remount,dev,suid /data"
su -c "$BUSYBOX mount --bind /dev $CHROOT/dev"
su -c "$BUSYBOX mount --bind /sys $CHROOT/sys"
su -c "$BUSYBOX mount --bind /proc $CHROOT/proc"
su -c "$BUSYBOX mount -t devpts devpts $CHROOT/dev/pts"
su -c "$BUSYBOX mount -t tmpfs -o size=256M tmpfs $CHROOT/dev/shm"
su -c "$BUSYBOX mount --bind /sdcard $CHROOT/sdcard"

echo "[*] Entering Debian CLI as $USER..."
su -c "sh $CHROOT/scripts/start-cli.sh $USER"
