#!/bin/bash

# گرفتن DNS از کاربر
read -p "Enter primary DNS server (e.g., 8.8.8.8): " dns1
read -p "Enter secondary DNS server (e.g., 8.8.4.4): " dns2

# برداشتن قفل از resolv.conf در صورت نیاز
if lsattr /etc/resolv.conf | grep -q '\-i\-'; then
    echo "Unlocking /etc/resolv.conf"
    sudo chattr -i /etc/resolv.conf
fi

# تنظیم DNS در resolved.conf
echo "Configuring /etc/systemd/resolved.conf"
sudo sed -i '/^DNS=/d' /etc/systemd/resolved.conf
sudo sed -i '/^\[Resolve\]/a DNS='${dns1}' '${dns2}'' /etc/systemd/resolved.conf

# حذف resolv.conf و ایجاد symlink به systemd-resolved
echo "Re-linking /etc/resolv.conf to systemd-resolved"
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# فعال‌سازی و ریستارت systemd-resolved
echo "Restarting systemd-resolved"
sudo systemctl enable systemd-resolved
sudo systemctl restart systemd-resolved

echo "DNS successfully set to $dns1 and $dns2"
