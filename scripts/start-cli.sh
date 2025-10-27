#!/bin/bash
# Debian CLI launcher (non-X11) for Termux

CHROOT="/data/local/tmp/chrootDebian"
USER=${1:-lixin}
BUSYBOX=$(command -v busybox)

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

echo "[*] Entering Debian CLI as $USER..."
$BUSYBOX chroot "$CHROOT" /bin/su - "$USER"
