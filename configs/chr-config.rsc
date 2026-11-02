# 2026-11-03 00:57:44 by RouterOS 7.23.8
# system id = 3zdBQ6EUwGG
#
/interface ethernet
set [ find default-name=ether1 ] disable-running-check=no
set [ find default-name=ether2 ] disable-running-check=no
/ip address
add address=172.16.80.254/24 interface=ether2 network=172.16.80.0
/ip dhcp-client
add interface=ether1 name=client1
/ip dns
set servers=1.1.1.1@main,8.8.8.8
/ip firewall nat
add action=masquerade chain=srcnat out-interface=ether1
/system identity
set name=CHR-WAN
