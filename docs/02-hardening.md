# Instalasi Wazuh Server dan Agent

Jaringan lab: `vmnet2` host-only `172.16.80.0/24`, DHCP VMware dimatikan.

| Node | IP | Spesifikasi |
| --- | --- | --- |
| Host Linux Mint | 172.16.80.1 | adapter `vmnet2` |
| MikroTik CHR (gateway) | 172.16.80.254 | 1 vCPU, 256 MB |
| `wazuh-srv` | 172.16.80.20 | 4 vCPU, 6 GB RAM, 40 GB |
| `ubuntu-target` | 172.16.80.10 | 1 vCPU, 1,5 GB RAM, 20 GB |

## 1. Setup jaringan VMware

1. **Edit > Virtual Network Editor**, pilih `vmnet2`.
2. Host-only, matikan DHCP lokal, aktifkan host virtual adapter.
3. Subnet `172.16.80.0`, mask `255.255.255.0`, lalu Save.

```bash
sudo vmware-networks --stop
sudo vmware-networks --start
ip addr show vmnet2        # harus 172.16.80.1/24
```

Sebelum memilih subnet, uji `ping -c 2 -W 1 <alamat .1>`; tidak boleh ada balasan. Subnet 10.10.10.0/24 ditolak VMware karena alamat 10.10.10.1 dijawab perangkat di jaringan upstream.

## 2. Setup gateway CHR

CHR punya dua adapter: `ether1` ke `vmnet8` (NAT) dan `ether2` ke `vmnet2`.

```
/ip address add address=172.16.80.254/24 interface=ether2
/ip firewall nat add chain=srcnat out-interface=ether1 action=masquerade
/ip dns set servers=1.1.1.1,8.8.8.8 allow-remote-requests=yes
```

## 3. Instalasi Ubuntu Server 24.04 (kedua VM)

| Layar | Isian |
| --- | --- |
| IPv4 | Manual. Subnet `172.16.80.0/24` (bukan subnet mask), Address `.20` atau `.10`, Gateway `172.16.80.254`, DNS `1.1.1.1,8.8.8.8` |
| Storage | `ubuntu-lv` diubah ke Size `max` |
| Profile | Server name `wazuh-srv` atau `ubuntu-target`, username `labadmin` |
| SSH | Install OpenSSH server |
| Snaps | Tidak ada |

## 4. Instal Wazuh di `wazuh-srv`

Lisensi gratis CHR membatasi upload 1 Mbps per interface, jadi unduhan lewat CHR sangat lambat (terukur sekitar 28 KB/s). Selama instalasi, pindahkan adapter VM ke NAT dan ganti netplan ke DHCP:

```bash
sudo cp /etc/netplan/50-cloud-init.yaml ~/netplan-static.bak
sudo nano /etc/netplan/50-cloud-init.yaml
```

```yaml
network:
  version: 2
  ethernets:
    ens33:          # sesuaikan dengan hasil `ip -br a`
      dhcp4: true
```

```bash
sudo netplan apply
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y curl
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

Simpan password `admin` yang tampil di akhir proses. Lalu batasi heap indexer:

```bash
sudo nano /etc/wazuh-indexer/jvm.options    # ubah menjadi -Xms2g dan -Xmx2g
sudo systemctl restart wazuh-indexer
```

Kembalikan adapter ke `vmnet2` dan pulihkan IP statis:

```bash
sudo cp ~/netplan-static.bak /etc/netplan/50-cloud-init.yaml
sudo netplan apply
```

## 5. Pasang agent di `ubuntu-target`

Di dashboard (`https://172.16.80.20`): **Endpoints Summary > Deploy new agent**, pilih DEB amd64, Server address `172.16.80.20` (IP server, bukan IP target), Agent name `ubuntu-target`.

```bash
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.9-1_amd64.deb
sudo WAZUH_MANAGER='172.16.80.20' WAZUH_AGENT_GROUP='default' WAZUH_AGENT_NAME='ubuntu-target' dpkg -i ./wazuh-agent_4.14.9-1_amd64.deb
sudo systemctl daemon-reload
sudo systemctl enable --now wazuh-agent
```

## 6. Uji coba

```bash
# di wazuh-srv
sudo systemctl status wazuh-manager wazuh-indexer wazuh-dashboard --no-pager
sudo /var/ossec/bin/agent_control -l

# di ubuntu-target
sudo systemctl status wazuh-agent --no-pager
```

Hasil yang benar: ketiga layanan server `active (running)`, dan agent `ubuntu-target` berstatus **Active** di Endpoints Summary.

## Masalah yang pernah muncul

| Gejala | Penyebab | Solusi |
| --- | --- | --- |
| `Unit wazuh-agent.service does not exist` | Paket belum terpasang | Jalankan `dpkg -i` dulu |
| `dpkg frontend lock ... held by process` | `unattended-upgrade` sedang berjalan | Tunggu selesai, atau hentikan hanya jika masih fase unduhan (`ps --ppid <PID> -o pid,cmd` tanpa `dpkg`); nonaktifkan timer: `sudo systemctl disable --now apt-daily-upgrade.timer apt-daily.timer` |
| Agent tidak muncul di dashboard | Server address salah | Pastikan `172.16.80.20`, bukan IP target |

## Referensi

Wazuh, Inc. (n.d.). *Quickstart*. Wazuh documentation. Diakses 20 Oktober 2026, dari <https://documentation.wazuh.com/current/quickstart.html>

MikroTik. (n.d.). *CHR: Licensing* [RouterOS manual, versi 7.26]. Diakses 2 November 2026, dari <https://manual.mikrotik.com/docs/getting-started/routeros-licensing/chr/chr-licensing/>
