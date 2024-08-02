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

   1. Open your terminal.
2. Download the script:
   ```sh
   wget https://raw.githubusercontent.com/ClassicDarkPack/dns-configuration-script/main/set-dns.sh
   ```
3. Make the script executable:
   ```sh
   chmod +x set-dns.sh
   ```
4. Execute the script:
   ```sh
   ./set-dns.sh
   ```
### Script Details
The script performs the following actions:

1.Sets DNS servers in /etc/systemd/resolved.conf.
2.Removes the existing /etc/resolv.conf file.
3.Creates a new /etc/resolv.conf file with the specified DNS servers.
4.Locks the /etc/resolv.conf file to prevent changes.
5.Restarts NetworkManager, systemd-resolved, and resolvconf services to apply the changes.


