[Tiếng Việt](./docs/vi/index.md)
# chroot-debian

This repo is remake from [DroidMaster](https://github.com/LinuxDroidMaster/Termux-Desktops/blob/main/Documentation/chroot/debian_chroot.md#first-steps-chroot)
✨ Debian 12 XFCE **Termux-X11**, no VNC.
- Easy to install
- Smooth display
- Have audio via PulseAudio
---

## 1. Requirement
- Your device is rooted
- [Termux](https://github.com/termux/termux-app/releases/tag/v0.118.3)
- [Termux-X11](https://github.com/termux/termux-x11/releases/)
- [BusyBox](https://github.com/Magisk-Modules-Repo/busybox-ndk)
- ⚠️ Skip install BusyBox if you using KSU and fork of KSU.
---

## 2. Install the necessary packages
- Paste in Termux
```bash
pkg update -y
pkg install -y x11-repo
pkg install -y root-repo
pkg install -y termux-x11-nightly
pkg install -y tsu pulseaudio
```
---

## 3. Install Debian
- Grant SU permission for Termux
- Enter `su` to access root shell
- Paste this command and the installation process will start
```bash
busybox curl -fsSL https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/installer.sh | bash
```
---

## 4. Notes
- Using command
 `debian` to launch Chroot Debian XFCE inside Termux-X11
 `debian-cli` launch Chroot Debian CLI
- Debian rootfs path: /data/local/tmp/chrootDebian
- XFCE connects directly via X11 socket: / tmp/.X11-unix
- PulseAudio runs via TCP at tcp: 127.0.0.1:4713
  
