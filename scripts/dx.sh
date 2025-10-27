#!/data/data/com.termux/files/usr/bin/bash
# Debian-XFCE launcher (Termux-side)

CHROOT="/data/local/tmp/chrootDebian"
USER="lixin"
BUSYBOX=$(command -v busybox)
XSOCK="/data/data/com.termux/files/usr/tmp/.X11-unix"

echo "[*] Cleaning up old processes..."
pkill -f termux.x11 >/dev/null 2>&1
pkill -f pulseaudio >/dev/null 2>&1
pkill -f virgl_test_server_android >/dev/null 2>&1
sleep 1

termux-wake-lock
export XDG_RUNTIME_DIR=${TMPDIR}

if ! pgrep -f termux.x11 >/dev/null; then
  echo "[*] Starting Termux-X11..."
  termux-x11 :0 -ac >/dev/null 2>&1 &
  sleep 2
  am start -n com.termux.x11/.MainActivity >/dev/null 2>&1
else
  echo "[!] Termux-X11 already running."
fi

echo "[*] Starting PulseAudio..."
pulseaudio --kill >/dev/null 2>&1
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1 >/dev/null 2>&1

echo "[*] Preparing mounts..."
for d in dev sys proc dev/pts dev/shm tmp run/dbus sdcard; do
  su -c "$BUSYBOX mkdir -p $CHROOT/$d"
done
su -c "$BUSYBOX mount -o remount,dev,suid /data"
su -c "$BUSYBOX mount --bind /dev $CHROOT/dev"
su -c "$BUSYBOX mount --bind /sys $CHROOT/sys"
su -c "$BUSYBOX mount --bind /proc $CHROOT/proc"
su -c "$BUSYBOX mount -t devpts devpts $CHROOT/dev/pts"
su -c "$BUSYBOX mount -t tmpfs -o rw,nosuid,nodev,noexec,relatime,mode=1777 tmpfs $CHROOT/tmp"
su -c "$BUSYBOX mount -t tmpfs -o size=256M tmpfs $CHROOT/dev/shm"
su -c "$BUSYBOX mount --bind /sdcard $CHROOT/sdcard"

su -c "mkdir -p $CHROOT/tmp/.X11-unix && chmod 1777 $CHROOT/tmp/.X11-unix"
su -c "mount --bind $XSOCK $CHROOT/tmp/.X11-unix" || echo '[!] Could not bind X11 socket.'

echo "[*] Launching Debian-XFCE..."
su -c "env DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1 sh $CHROOT/scripts/start-x11.sh $USER"
