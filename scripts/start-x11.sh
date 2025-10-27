#!/bin/bash
# Debian XFCE starter for Termux-X11 (final clean build)

CHROOT="/data/local/tmp/chrootDebian"
USER=${1:-lixin}
BUSYBOX=$(command -v busybox)

# ----- Environment -----
export DISPLAY=:0
export PULSE_SERVER=tcp:127.0.0.1:4713
export XDG_RUNTIME_DIR=/tmp
export NO_AT_BRIDGE=1
export XDG_SESSION_TYPE=x11

# ----- Prepare D-Bus -----
$BUSYBOX mkdir -p "$CHROOT/run/dbus"
$BUSYBOX chmod 777 "$CHROOT/run/dbus"

# ----- Start XFCE -----
$BUSYBOX chroot "$CHROOT" /bin/sh -c "
if ! command -v xfce4-session >/dev/null 2>&1; then
  echo '[!] XFCE4 not installed. Please install manually inside chroot if needed.'
fi

echo '[*] Starting XFCE session for user $USER...'
if ! id \"$USER\" >/dev/null 2>&1; then
  echo '[+] Creating user $USER...'
  adduser --disabled-password --gecos '' \"$USER\"
  echo '$USER ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers
fi

runuser -l \"$USER\" -c 'DISPLAY=:0 PULSE_SERVER=tcp:127.0.0.1 XDG_RUNTIME_DIR=/tmp xfce4-session'
"
