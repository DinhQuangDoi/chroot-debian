# chroot-debian

Repo này được làm lại từ [DroidMaster](https://github.com/LinuxDroidMaster/Termux-Desktops/blob/main/Documentation/chroot/debian_chroot.md#first-steps-chroot)  
✨ Debian 12 XFCE chạy trực tiếp trong **Termux-X11**, không cần VNC.  
- Cài đặt dễ dàng  
- Hiển thị mượt mà  
- Có âm thanh thông qua PulseAudio
---

## 1. Yêu cầu
- Thiết bị của bạn đã root  
- [Termux](https://github.com/termux/termux-app/releases/tag/v0.118.3)  
- [Termux-X11](https://github.com/termux/termux-x11/releases/)  
- [BusyBox](https://github.com/Magisk-Modules-Repo/busybox-ndk)  
- ⚠️ Bỏ qua cài đặt BusyBox nếu bạn đang dùng **KSU** hoặc các bản fork của KSU
---

## 2. Cài đặt các gói cần thiết
> Dán các lệnh sau vào Termux:
```bash
pkg update -y
pkg install -y x11-repo
pkg install -y root-repo
pkg install -y termux-x11-nightly
pkg install -y tsu pulseaudio
```
---

## 3. Cài đặt Debian
- Cấp quyền **SU** cho Termux  
- Gõ `su` để truy cập shell root  
- Sau đó dán lệnh sau để bắt đầu quá trình cài đặt:
```bash
curl -fsSL https://raw.githubusercontent.com/DinhQuangDoi/chroot-debian/main/installer.sh | bash
```
---

## 4. Ghi chú
- Dùng lệnh:  
  - `debian` để khởi chạy giao diện **Debian XFCE** trong Termux-X11  
  - `debian-cli` để vào **Debian CLI** (dòng lệnh)  
- Đường dẫn rootfs Debian: `/data/local/tmp/chrootDebian`  
- XFCE kết nối trực tiếp qua socket X11: `/tmp/.X11-unix`  
- PulseAudio chạy qua TCP tại địa chỉ: `tcp:127.0.0.1:4713`
