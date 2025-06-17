#!/bin/bash

# گرفتن DNS از کاربر
read -p "Enter primary DNS server (e.g., 8.8.8.8): " dns1
read -p "Enter secondary DNS server (e.g., 8.8.4.4): " dns2

# بررسی فرمت IP آدرس
function valid_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

if ! valid_ip $dns1 || ! valid_ip $dns2; then
    echo "Error: One or both DNS entries are not valid IP addresses."
    exit 1
fi

# پشتیبان‌گیری از فایل پیکربندی قبلی
sudo cp /etc/systemd/resolved.conf /etc/systemd/resolved.conf.bak

# برداشتن قفل از resolv.conf در صورت نیاز
if lsattr /etc/resolv.conf | grep -q '\-i\-'; then
    echo "Unlocking /etc/resolv.conf"
    sudo chattr -i /etc/resolv.conf
fi

# تنظیم DNS در resolved.conf
echo "Configuring /etc/systemd/resolved.conf"
sudo sed -i '/^DNS=/d' /etc/systemd/resolved.conf
sudo sed -i '/^#DNS=/d' /etc/systemd/resolved.conf
sudo sed -i '/^\[Resolve\]/a DNS='${dns1}' '${dns2}'' /etc/systemd/resolved.conf

# حذف resolv.conf و ایجاد symlink به systemd-resolved
echo "Re-linking /etc/resolv.conf to systemd-resolved"
sudo rm -f /etc/resolv.conf
sudo ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# فعال‌سازی و ریستارت systemd-resolved
echo "Restarting systemd-resolved"
sudo systemctl enable systemd-resolved
sudo systemctl restart systemd-resolved

# بررسی وضعیت سرویس
echo "Checking systemd-resolved status"
sudo systemctl is-active systemd-resolved

echo "DNS successfully set to $dns1 and $dns2"
