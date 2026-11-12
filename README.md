# DNS Configuration Script

A small Bash CLI for **systemd-resolved** on Linux. It configures global IPv4 DNS through a dedicated drop-in file, without deleting or locking `/etc/resolv.conf`.

> **Important:** This project intentionally supports **systemd-resolved only**. NetworkManager, resolvconf, and interface-specific settings can affect the final DNS used. Changing DNS remotely can interrupt access; keep a console or rollback path available.

## Requirements

- Linux with an **active** `systemd-resolved` service
- Bash and standard utilities (`systemctl`, `install`, `mktemp`)
- Root privileges for applying or restoring changes
- IPv4 resolvers (IPv6 is not yet supported)

## Get started

Download and inspect the script before executing it:

```bash
curl -fL -o set-dns.sh https://raw.githubusercontent.com/ClassicDarkPack/dns-configuration-script/main/set-dns.sh
bash -n set-dns.sh
bash set-dns.sh --help
```

Preview the change (no privileges or service restart required):

```bash
bash set-dns.sh --primary 1.1.1.1 --secondary 1.0.0.1 --dry-run
```

Apply interactively:

```bash
sudo bash set-dns.sh --primary 1.1.1.1 --secondary 1.0.0.1
```

For unattended automation, explicitly add `--yes`.

Inspect the resulting settings:

```bash
bash set-dns.sh --status
resolvectl status
```

Remove **only the configuration managed by this tool**:

```bash
sudo bash set-dns.sh --restore
```

`--restore` removes the tool's drop-in; it does not rewrite other system configuration or recreate a previous `/etc/resolv.conf`.

## What changes?

| Path | Purpose |
| --- | --- |
| `/etc/systemd/resolved.conf.d/90-dns-configuration-script.conf` | Dedicated global DNS override |
| `/var/lib/dns-configuration-script/managed` | Marker to prevent overwriting unrelated existing configurations |

The script validates both IPv4 addresses, refuses to overwrite an unmanaged target file or a symlink, requires a running `systemd-resolved` service for writes, asks for confirmation, and tries to roll back its configuration if the service restart fails. It **does not** modify `/etc/resolv.conf`, restart NetworkManager, disable DNS services, or make the file immutable.

## Caveats and safety

- DNS lookups may temporarily fail during a resolver restart. **Do not apply blindly to a remote production server**.
- The tool manages **global DNS**, which may not override per-interface DNS or other drop-ins. Confirm actual DNS routing with `resolvectl status`.
- DNS address validation checks IPv4 format, **not whether the resolver is reachable**.
- The restore operation returns control to the rest of the existing system configuration, not necessarily the specific DNS values that were active before installation.
- It is recommended to back up settings and test on a disposable VM before deployment.
- No guarantee of transactional rollback for power loss, out-of-disk conditions, or external changes.

## توسعه / راهنمای فارسی

این ابزار برای تنظیم DNS روی سیستم‌های لینوکسیِ دارای `systemd-resolved` طراحی شده است. برخلاف نسخه قبلی، فایل `/etc/resolv.conf` را حذف یا قفل نمی‌کند.

ابتدا با `--dry-run` تغییرات را مشاهده کنید. سپس با `sudo` تنظیمات را اعمال کرده و با `resolvectl status` نتیجه را بررسی کنید. برای حذف تنظیماتی که خود ابزار اضافه کرده، از `--restore` استفاده کنید.

**هشدار:** تغییر DNS روی سرور راه‌دور ممکن است ارتباط شما را قطع کند. پیش از اجرای واقعی، دسترسی بازیابی یا کنسول داشته باشید.

## Contributing

Please open an issue or pull request for bugs or improvements. Run `bash -n set-dns.sh` and `bash tests/test-cli.sh` before submitting.

## License

MIT (see [LICENSE](LICENSE)).
