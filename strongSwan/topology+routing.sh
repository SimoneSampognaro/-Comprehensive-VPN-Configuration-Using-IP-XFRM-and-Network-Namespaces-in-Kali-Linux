#!/bin/bash

sudo apt update

# Initial setup
sudo bash -c 'echo 0 > /proc/sys/net/ipv4/conf/all/send_redirects'
sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
sudo apt-get install bridge-utils -y

# Create namespaces
sudo ip netns add ce1
sudo ip netns add ce2
sudo ip netns add ce3
sudo ip netns add ce4
sudo ip netns add ce5
sudo ip netns add pe1
sudo ip netns add pe2
sudo ip netns add pe3
sudo ip netns add pe4
sudo ip netns add pe5

# Create and configure the bridge
sudo brctl addbr bridge
sudo brctl stp bridge off
sudo ip link set dev bridge up

# Function to create veth Pair, Assign IP and MAC Addresses
# and Connect to Network Namespace
create_veth() {
    sudo ip link add $1 type veth peer name $2
    sudo ip link set $1 netns $3
    sudo ip netns exec $3 ip link set $1 up
    sudo ip netns exec $3 ip addr add $4 dev $1
    sudo ip netns exec $3 ifconfig $1 hw ether $5
    sudo ip netns exec $3 ip link set dev lo up

    # Disable receiving ICMP redirect packets with iptables
    sudo ip netns exec $3 iptables -I INPUT -p icmp --icmp-type redirect -j DROP
    
    # Enable ARP Filtering for Network Namespace Interface
    sudo ip netns exec $3 sysctl -w net.ipv4.conf.$1.arp_filter=1
}

# CE1
create_veth eth01 veth01 ce1 172.16.0.2/24 00:00:00:00:00:01
sudo brctl addif bridge veth01
sudo ip link set dev veth01 up

# PE1
create_veth eth02 veth02 pe1 172.16.0.1/24 00:00:00:00:00:02
sudo brctl addif bridge veth02
sudo ip link set dev veth02 up

create_veth eth03 veth03 pe1 10.200.0.1/30 00:00:00:00:00:03
sudo brctl addif bridge veth03
sudo ip link set dev veth03 up

create_veth eth04 veth04 pe1 10.200.0.5/30 00:00:00:00:00:04
sudo brctl addif bridge veth04
sudo ip link set dev veth04 up

# CE2
create_veth eth05 veth05 ce2 192.168.1.2/24 00:00:00:00:00:05
sudo brctl addif bridge veth05
sudo ip link set dev veth05 up

# PE2
create_veth eth06 veth06 pe2 192.168.1.1/24 00:00:00:00:00:06
sudo brctl addif bridge veth06
sudo ip link set dev veth06 up

create_veth eth07 veth07 pe2 10.200.0.14/30 00:00:00:00:00:07
sudo brctl addif bridge veth07
sudo ip link set dev veth07 up

create_veth eth08 veth08 pe2 10.200.0.17/30 00:00:00:00:00:08
sudo brctl addif bridge veth08
sudo ip link set dev veth08 up

# CE3
create_veth eth09 veth09 ce3 192.168.2.2/24 00:00:00:00:00:09
sudo brctl addif bridge veth09
sudo ip link set dev veth09 up

# PE3
create_veth eth10 veth10 pe3 192.168.2.1/24 00:00:00:00:00:0a
sudo brctl addif bridge veth10
sudo ip link set dev veth10 up

create_veth eth11 veth11 pe3 10.200.0.2/30 00:00:00:00:00:0b
sudo brctl addif bridge veth11
sudo ip link set dev veth11 up

create_veth eth12 veth12 pe3 10.200.0.9/30 00:00:00:00:00:0c
sudo brctl addif bridge veth12
sudo ip link set dev veth12 up

# CE4
create_veth eth13 veth13 ce4 192.168.3.2/24 00:00:00:00:00:0d
sudo brctl addif bridge veth13
sudo ip link set dev veth13 up

# PE4
create_veth eth14 veth14 pe4 192.168.3.1/24 00:00:00:00:00:0e
sudo brctl addif bridge veth14
sudo ip link set dev veth14 up

create_veth eth15 veth15 pe4 10.200.0.6/30 00:00:00:00:00:0f
sudo brctl addif bridge veth15
sudo ip link set dev veth15 up

create_veth eth16 veth16 pe4 10.200.0.18/30 00:00:00:00:00:10
sudo brctl addif bridge veth16
sudo ip link set dev veth16 up

create_veth eth22 veth22 pe4 10.200.0.22/30 00:00:00:00:00:16
sudo brctl addif bridge veth22
sudo ip link set dev veth22 up

# CE5
create_veth eth17 veth17 ce5 172.16.1.2/24 00:00:00:00:00:11
sudo brctl addif bridge veth17
sudo ip link set dev veth17 up

# PE5
create_veth eth18 veth18 pe5 172.16.1.1/24 00:00:00:00:00:12
sudo brctl addif bridge veth18
sudo ip link set dev veth18 up

create_veth eth19 veth19 pe5 10.200.0.10/30 00:00:00:00:00:13
sudo brctl addif bridge veth19
sudo ip link set dev veth19 up

create_veth eth20 veth20 pe5 10.200.0.13/30 00:00:00:00:00:14
sudo brctl addif bridge veth20
sudo ip link set dev veth20 up

create_veth eth21 veth21 pe5 10.200.0.21/30 00:00:00:00:00:15
sudo brctl addif bridge veth21
sudo ip link set dev veth21 up

# Enable IP forwarding in PE namespaces
for ns in pe1 pe2 pe3 pe4 pe5; do
    sudo ip netns exec $ns sysctl -w net.ipv4.ip_forward=1
done

# Static routing

# Connect GWs
sudo ip netns exec pe1 ip route add 10.200.0.8/30 via 10.200.0.2 dev eth03

sudo ip netns exec pe1 ip route add 10.200.0.12/30 via 10.200.0.2 dev eth03

sudo ip netns exec pe1 ip route add 10.200.0.16/30 via 10.200.0.6 dev eth04

sudo ip netns exec pe1 ip route add 10.200.0.20/30 via 10.200.0.6 dev eth04

sudo ip netns exec pe2 ip route add 10.200.0.0/30 via 10.200.0.13 dev eth07

sudo ip netns exec pe2 ip route add 10.200.0.4/30 via 10.200.0.18 dev eth08

sudo ip netns exec pe2 ip route add 10.200.0.8/30 via 10.200.0.13 dev eth07

sudo ip netns exec pe3 ip route add 10.200.0.4/30 via 10.200.0.1 dev eth11

sudo ip netns exec pe3 ip route add 10.200.0.12/30 via 10.200.0.10 dev eth12

sudo ip netns exec pe3 ip route add 10.200.0.16/30 via 10.200.0.10 dev eth12

sudo ip netns exec pe4 ip route add 10.200.0.0/30 via 10.200.0.5 dev eth15

sudo ip netns exec pe4 ip route add 10.200.0.8/30 via 10.200.0.21 dev eth22

sudo ip netns exec pe4 ip route add 10.200.0.12/30 via 10.200.0.17 dev eth16

sudo ip netns exec pe5 ip route add 10.200.0.0/30 via 10.200.0.9 dev eth19

sudo ip netns exec pe5 ip route add 10.200.0.4/30 via 10.200.0.22 dev eth21

sudo ip netns exec pe5 ip route add 10.200.0.16/30 via 10.200.0.14 dev eth20

# Routing for s2s

sudo ip netns exec pe2 ip route add 192.168.2.0/24 via 10.200.0.13 dev eth07

sudo ip netns exec pe2 ip route add 192.168.3.0/24 via 10.200.0.18 dev eth08

sudo ip netns exec pe3 ip route add 192.168.1.0/24 via 10.200.0.10 dev eth12

sudo ip netns exec pe3 ip route add 192.168.3.0/24 via 10.200.0.1 dev eth11

sudo ip netns exec pe4 ip route add 192.168.1.0/24 via 10.200.0.17 dev eth16

sudo ip netns exec pe4 ip route add 192.168.2.0/24 via 10.200.0.5 dev eth15

sudo ip netns exec ce2 ip route add 192.168.2.0/24 via 192.168.1.1 dev eth05

 sudo ip netns exec ce2 ip route add 192.168.3.0/24 via 192.168.1.1 dev eth05

 sudo ip netns exec ce3 ip route add 192.168.1.0/24 via 192.168.2.1 dev eth09

 sudo ip netns exec ce3 ip route add 192.168.3.0/24 via 192.168.2.1 dev eth09

 sudo ip netns exec ce4 ip route add 192.168.2.0/24 via 192.168.3.1 dev eth13

 sudo ip netns exec ce4 ip route add 192.168.1.0/24 via 192.168.3.1 dev eth13
 
# Flush namespaces policies and states

sudo ip netns exec pe1 ip xfrm policy flush
sudo ip netns exec pe1 ip xfrm state flush
sudo ip netns exec pe2 ip xfrm policy flush
sudo ip netns exec pe2 ip xfrm state flush
sudo ip netns exec pe3 ip xfrm policy flush
sudo ip netns exec pe3 ip xfrm state flush
sudo ip netns exec pe4 ip xfrm policy flush
sudo ip netns exec pe4 ip xfrm state flush
sudo ip netns exec pe5 ip xfrm policy flush
sudo ip netns exec pe5 ip xfrm state flush
sudo ip netns exec ce1 ip xfrm policy flush
sudo ip netns exec ce1 ip xfrm state flush
sudo ip netns exec ce2 ip xfrm policy flush
sudo ip netns exec ce2 ip xfrm state flush
sudo ip netns exec ce3 ip xfrm policy flush
sudo ip netns exec ce3 ip xfrm state flush
sudo ip netns exec ce4 ip xfrm policy flush
sudo ip netns exec ce4 ip xfrm state flush
sudo ip netns exec ce5 ip xfrm policy flush
sudo ip netns exec ce5 ip xfrm state flush