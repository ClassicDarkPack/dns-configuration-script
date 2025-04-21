#!/bin/bash

# دریافت DNS از کاربر
read -p "Enter primary DNS server (e.g., 8.8.8.8): " dns1
read -p "Enter secondary DNS server (e.g., 8.8.4.4): " dns2

# باز کردن قفل فایل resolv.conf اگر قفل شده باشد
if lsattr /etc/resolv.conf | grep -q '\-i\-'; then
    echo "Unlocking /etc/resolv.conf"
    sudo chattr -i /etc/resolv.conf
fi

# تنظیم DNS در فایل systemd-resolved
echo "Updating /etc/systemd/resolved.conf"
sudo sed -i '/^DNS=/d' /etc/systemd/resolved.conf
sudo sed -i '/^\[Resolve\]/a DNS='${dns1}' '${dns2}'' /etc/systemd/resolved.conf

# حذف فایل resolv.conf و ایجاد symlink به systemd-resolved
echo "Re-linking /etc/resolv.conf to /run/systemd/resolve/stub-resolv.conf"
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# راه‌اندازی مجدد سرویس‌ها
echo "Restarting systemd-resolved"
sudo systemctl restart systemd-resolved

# بررسی فعال بودن systemd-resolved
echo "Enabling systemd-resolved"
sudo systemctl enable systemd-resolved

echo "DNS configuration completed successfully: $dns1 and $dns2"
