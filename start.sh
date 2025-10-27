#!/bin/bash
# Start Debian XFCE in Termux-X11
BUSYBOX=$(command -v busybox)
CHROOT="/data/local/tmp/chrootDebian"
TMPX11="/data/data/com.termux/files/usr/tmp/.X11-unix"

echo "[*] Cleaning up old processes..."
killall -9 termux-x11 Xwayland pulseaudio termux-wake-lock 2>/dev/null

echo "[*] Launching Termux-X11..."
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >/dev/null 2>&1
sleep 2

echo "[*] Starting PulseAudio..."
pulseaudio --start \
  --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" \
  --exit-idle-time=-1 >/dev/null 2>&1

echo "[*] Preparing system mounts..."
$BUSYBOX mount -o remount,dev,suid /data
for d in dev proc sys; do
  $BUSYBOX mount --bind /$d "$CHROOT/$d"
done
mkdir -p "$CHROOT/dev/shm" "$CHROOT/tmp" "$CHROOT/sdcard"
$BUSYBOX mount -t tmpfs -o size=256M tmpfs "$CHROOT/dev/shm"
$BUSYBOX mount --bind /sdcard "$CHROOT/sdcard"

# Bind X11 socket
echo "[*] Checking X11 socket..."
mkdir -p "$CHROOT/tmp/.X11-unix"
if ! mountpoint -q "$CHROOT/tmp/.X11-unix"; then
  $BUSYBOX mount --bind "$TMPX11" "$CHROOT/tmp/.X11-unix"
  echo "[✓] X11 socket bound successfully."
else
  echo "[=] X11 socket already mounted — skipping."
fi

# Launch XFCE
USER=$(ls "$CHROOT/home" | head -n1)
echo "[*] Launching Debian XFCE as user: $USER"
$BUSYBOX chroot "$CHROOT" /bin/su - "$USER" -c '
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
export XDG_RUNTIME_DIR=/tmp
dbus-launch --exit-with-session startxfce4
'

echo "[✓] Debian XFCE launched successfully."
