# DNS Configuration Script

This script configures the DNS settings for your system. It updates the DNS servers and ensures that the configuration remains persistent by locking the `/etc/resolv.conf` file.

## How to Use

Follow these steps to download and execute the script:

### Download and Execute with `curl`

1. Open your terminal.
2. Download the script:
   ```bash
   sudo bash -c "$(curl -Lfo- https://raw.githubusercontent.com/ClassicDarkPack/dns-configuration-script/main/set-dns.sh)"
   ```
   
### Download and Execute with `wget`
1. Open your terminal
3. Download the script:
   ```bash
   wget https://raw.githubusercontent.com/ClassicDarkPack/dns-configuration-script/main/set-dns.sh
   ```
4. Make the script executable:
   ```bash
   chmod +x set-dns.sh
   ```
5. Execute the script:
   ```bash
   ./set-dns.sh
   ```
### Script Details
1. Sets DNS servers in `/etc/systemd/resolved.conf`.
2. Removes the existing `/etc/resolv.conf` file.
3. Creates a new `/etc/resolv.conf` file with the specified DNS servers.
4. Locks the `/etc/resolv.conf` file to prevent changes.
5. Restarts `NetworkManager`, `systemd-resolved`, and `resolvconf` services to apply t





