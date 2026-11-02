# Wazuh Security Lab

Lab di VMware Workstation: server Wazuh memantau log sebuah target Ubuntu, lalu target di-hardening dan diaudit sebelum dan sesudahnya.

## Topologi

| Node | IP | Peran |
| --- | --- | --- |
| MikroTik CHR | 172.16.80.254 | Gateway dan NAT |
| `wazuh-srv` | 172.16.80.20 | Wazuh 4.14 (manager, indexer, dashboard) |
| `ubuntu-target` | 172.16.80.10 | Target hardening dan agent Wazuh |

Semua node berada di jaringan host-only `vmnet2` (172.16.80.0/24). Host: Linux Mint, RAM 12 GB.

## Dokumentasi

- [Instalasi Wazuh dan agent](docs/01-instalasi-wazuh-agent.md)
- [Hardening ubuntu-target](docs/02-hardening.md) (draf)

## Alat

VMware Workstation, MikroTik CHR, Wazuh, Lynis, nmap, UFW, fail2ban.

## Catatan

Repositori ini tidak memuat password maupun kunci privat.
