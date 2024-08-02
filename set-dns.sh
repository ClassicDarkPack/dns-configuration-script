#!/bin/bash

# تنظیم DNS سرورها در فایل resolved.conf
echo "Setting DNS servers in /etc/systemd/resolved.conf"
sudo bash -c 'cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8 1.1.1.1
EOF'

# حذف فایل /etc/resolv.conf
echo "Removing /etc/resolv.conf"
sudo rm /etc/resolv.conf

# ایجاد فایل /etc/resolv.conf با DNS سرورهای جدید
echo "Creating /etc/resolv.conf with new DNS servers"
sudo bash -c 'cat << EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF'

# قفل کردن فایل /etc/resolv.conf برای جلوگیری از تغییرات
echo "Locking /etc/resolv.conf to prevent changes"
sudo chattr +i /etc/resolv.conf

# راه‌اندازی مجدد سرویس‌های شبکه و resolved
echo "Restarting NetworkManager, systemd-resolved, and resolvconf services"
sudo systemctl restart NetworkManager
sudo systemctl restart systemd-resolved.service
sudo systemctl restart resolvconf.service

echo "DNS configuration is complete."
