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

# ------------------------------- s2s ---------------------------------------------

# Set up IPsec ESP tunnel mode states and policies for namespace PE2

# PE2 - PE3
sudo ip netns exec pe2 ip xfrm state add src 10.200.0.14 dst 10.200.0.9 proto esp spi 0x1000 mode tunnel \
    enc 'aes' 0x72d3b1535a04bb0a0a0d9c7ce4f40b39 \
    auth hmac\(sha256\)  0x9bdacd6c4223355ed46684ee345439ce3c98b499c4fcd716c2b737b6b62f3ecf

sudo ip netns exec pe2 ip xfrm state add src 10.200.0.9 dst 10.200.0.14 proto esp spi 0x2000 mode tunnel \
    enc 'aes' 0x4255637618d950ff217825366ae4d43d \
    auth hmac\(sha256\) 0x7c1b3bef2d0ff2c232760f320abbda941067c87de4ecbb4377ed47ba844efb5a

sudo ip netns exec pe2 ip xfrm policy add src 192.168.1.0/24 dst 192.168.2.0/24 dir out \
    tmpl src 10.200.0.14 dst 10.200.0.9 proto esp mode tunnel

sudo ip netns exec pe2 ip xfrm policy add src 192.168.2.0/24 dst 192.168.1.0/24 dir fwd \
    tmpl src 10.200.0.9 dst 10.200.0.14 proto esp mode tunnel

# PE2 - PE4
sudo ip netns exec pe2 ip xfrm state add src 10.200.0.17 dst 10.200.0.18 proto esp spi 0x5000 mode tunnel \
   enc 'aes' 0xeaeafd578e4308c057c79768c43e4a29 \
         auth hmac\(sha256\) 0xdbe07dced4d7e7808f88bc3975be46c25f8b2ad857bd6920c785bf722c5efdee

sudo ip netns exec pe2 ip xfrm state add src 10.200.0.18 dst 10.200.0.17 proto esp spi 0x6000 mode tunnel \
   enc 'aes' 0xe0a108253dee8e457df8969e61cb43ad \
         auth hmac\(sha256\) 0x04b35aa360f450fed7f9402de8661941624886f0ead49afa0000f5566f4b3295

sudo ip netns exec pe2 ip xfrm policy add src 192.168.1.0/24 dst 192.168.3.0/24 dir out \
    tmpl src 10.200.0.17 dst 10.200.0.18 proto esp mode tunnel

sudo ip netns exec pe2 ip xfrm policy add src 192.168.3.0/24 dst 192.168.1.0/24 dir fwd \
    tmpl src 10.200.0.18 dst 10.200.0.17 proto esp mode tunnel

# Set up IPsec ESP tunnel mode states and policies for namespace PE3

# PE3 - PE2
sudo ip netns exec pe3 ip xfrm state add src 10.200.0.14 dst 10.200.0.9 proto esp spi 0x1000 mode tunnel \
    enc 'aes' 0x72d3b1535a04bb0a0a0d9c7ce4f40b39 \
    auth hmac\(sha256\)  0x9bdacd6c4223355ed46684ee345439ce3c98b499c4fcd716c2b737b6b62f3ecf

sudo ip netns exec pe3 ip xfrm state add src 10.200.0.9 dst 10.200.0.14 proto esp spi 0x2000 mode tunnel \
  enc 'aes' 0x4255637618d950ff217825366ae4d43d \
  auth hmac\(sha256\) 0x7c1b3bef2d0ff2c232760f320abbda941067c87de4ecbb4377ed47ba844efb5a
  
sudo ip netns exec pe3 ip xfrm policy add src 192.168.2.0/24 dst 192.168.1.0/24 dir out \
    tmpl src 10.200.0.9 dst 10.200.0.14 proto esp mode tunnel

sudo ip netns exec pe3 ip xfrm policy add src 192.168.1.0/24 dst 192.168.2.0/24 dir fwd \
    tmpl src 10.200.0.14 dst 10.200.0.9 proto esp mode tunnel

# PE3 - PE4
sudo ip netns exec pe3 ip xfrm state add src 10.200.0.2 dst 10.200.0.6 proto esp spi 0x3000 mode tunnel \
        enc 'aes' 0x0462f50849ad5b94e1c793c60fac5e62 \
  auth hmac\(sha256\) 0xcf33038c657c25befa554419b35b98b33c6dee4844759c9745e9c13690c4ff2b

sudo ip netns exec pe3 ip xfrm state add src 10.200.0.6 dst 10.200.0.2 proto esp spi 0x4000 mode tunnel \
  enc 'aes' 0x63325bc69038456b07c688eb3844866a \
  auth hmac\(sha256\) 0x322ff07641e210fb2d9051534954e740834021fa62ca68c3641100cf87e506bf

sudo ip netns exec pe3 ip xfrm policy add src 192.168.2.0/24 dst 192.168.3.0/24 dir out \
    tmpl src 10.200.0.2 dst 10.200.0.6 proto esp mode tunnel

sudo ip netns exec pe3 ip xfrm policy add src 192.168.3.0/24 dst 192.168.2.0/24 dir fwd \
    tmpl src 10.200.0.6 dst 10.200.0.2 proto esp mode tunnel
    
# Set up IPsec ESP tunnel mode states and policies for namespace PE4

# PE4 - PE2
sudo ip netns exec pe4 ip xfrm state add src 10.200.0.17 dst 10.200.0.18 proto esp spi 0x5000 mode tunnel \
         enc 'aes' 0xeaeafd578e4308c057c79768c43e4a29 \
         auth hmac\(sha256\) 0xdbe07dced4d7e7808f88bc3975be46c25f8b2ad857bd6920c785bf722c5efdee

sudo ip netns exec pe4 ip xfrm state add src 10.200.0.18 dst 10.200.0.17 proto esp spi 0x6000 mode tunnel \
         enc 'aes' 0xe0a108253dee8e457df8969e61cb43ad \
         auth hmac\(sha256\) 0x04b35aa360f450fed7f9402de8661941624886f0ead49afa0000f5566f4b3295

sudo ip netns exec pe4 ip xfrm policy add src 192.168.3.0/24 dst 192.168.1.0/24 dir out \
    tmpl src 10.200.0.18 dst 10.200.0.17 proto esp mode tunnel

sudo ip netns exec pe4 ip xfrm policy add src 192.168.1.0/24 dst 192.168.3.0/24 dir fwd \
    tmpl src 10.200.0.17 dst 10.200.0.18 proto esp mode tunnel

# PE4 - PE3
sudo ip netns exec pe4 ip xfrm state add src 10.200.0.2 dst 10.200.0.6 proto esp spi 0x3000 mode tunnel \
         enc 'aes' 0x0462f50849ad5b94e1c793c60fac5e62 \
   auth hmac\(sha256\) 0xcf33038c657c25befa554419b35b98b33c6dee4844759c9745e9c13690c4ff2b

sudo ip netns exec pe4 ip xfrm state add src 10.200.0.6 dst 10.200.0.2 proto esp spi 0x4000 mode tunnel \
         enc 'aes' 0x63325bc69038456b07c688eb3844866a \
   auth hmac\(sha256\) 0x322ff07641e210fb2d9051534954e740834021fa62ca68c3641100cf87e506bf

sudo ip netns exec pe4 ip xfrm policy add src 192.168.3.0/24 dst 192.168.2.0/24 dir out \
    tmpl src 10.200.0.6 dst 10.200.0.2 proto esp mode tunnel

sudo ip netns exec pe4 ip xfrm policy add src 192.168.2.0/24 dst 192.168.3.0/24 dir fwd \
    tmpl src 10.200.0.2 dst 10.200.0.6 proto esp mode tunnel
    
# ------------------------------- e2e with host CE4 ----------------------------------------------------

# Set up IPsec AH transport mode states and policies between namespaces CE2 and CE4
sudo ip netns exec ce2 ip xfrm state add src 192.168.1.2 dst 192.168.3.2 proto ah spi 0x1000 auth hmac\(sha256\) 0x0d6aac1735278fe8a709716271d0a5117c89cef8e5302d1cb7b39bbf6ac35e22
sudo ip netns exec ce2 ip xfrm state add src 192.168.3.2 dst 192.168.1.2 proto ah spi 0x2000 auth hmac\(sha256\) 0x280730d699e985ab62f98d508a001a70cd2ff28db4dd871e890612bd03ad1917

sudo ip netns exec ce2 ip xfrm policy add dir out src 192.168.1.2 dst 192.168.3.2  tmpl src 192.168.1.2 dst 192.168.3.2 proto ah spi 0x1000
sudo ip netns exec ce2 ip xfrm policy add dir in src 192.168.3.2 dst 192.168.1.2  tmpl src 192.168.3.2 dst 192.168.1.2 proto ah spi 0x2000

# Set up IPsec AH transport mode states and policies between namespaces CE3 and CE4
sudo ip netns exec ce3 ip xfrm state add src 192.168.2.2 dst 192.168.3.2 proto ah spi 0x3000 auth hmac\(sha256\) 0x831de8fbad2a8306c1d835f946565d8fd168bdfba2092055afe245034ec06b52
sudo ip netns exec ce3 ip xfrm state add src 192.168.3.2 dst 192.168.2.2 proto ah spi 0x4000 auth hmac\(sha256\) 0x3f797aec8e7684ddd7b6074da347b351fcebe273e3be32b32ba845eb36138a3b

sudo ip netns exec ce3 ip xfrm policy add dir out src 192.168.2.2 dst 192.168.3.2  tmpl src 192.168.2.2 dst 192.168.3.2 proto ah spi 0x3000
sudo ip netns exec ce3 ip xfrm policy add dir in src 192.168.3.2 dst 192.168.2.2  tmpl src 192.168.3.2 dst 192.168.2.2 proto ah spi 0x4000

# Set up IPsec AH transport mode states and policies between namespaces CE4 and CE2/CE3
sudo ip netns exec ce4 ip xfrm state add src 192.168.1.2 dst 192.168.3.2 proto ah spi 0x1000 auth hmac\(sha256\) 0x0d6aac1735278fe8a709716271d0a5117c89cef8e5302d1cb7b39bbf6ac35e22
sudo ip netns exec ce4 ip xfrm state add src 192.168.3.2 dst 192.168.1.2 proto ah spi 0x2000 auth hmac\(sha256\) 0x280730d699e985ab62f98d508a001a70cd2ff28db4dd871e890612bd03ad1917

sudo ip netns exec ce4 ip xfrm state add src 192.168.2.2 dst 192.168.3.2 proto ah spi 0x3000 auth hmac\(sha256\) 0x831de8fbad2a8306c1d835f946565d8fd168bdfba2092055afe245034ec06b52
sudo ip netns exec ce4 ip xfrm state add src 192.168.3.2 dst 192.168.2.2 proto ah spi 0x4000 auth hmac\(sha256\) 0x3f797aec8e7684ddd7b6074da347b351fcebe273e3be32b32ba845eb36138a3b

sudo ip netns exec ce4 ip xfrm policy add dir in src 192.168.1.2 dst 192.168.3.2  tmpl src 192.168.1.2 dst 192.168.3.2 proto ah spi 0x1000
sudo ip netns exec ce4 ip xfrm policy add dir out src 192.168.3.2 dst 192.168.1.2  tmpl src 192.168.3.2 dst 192.168.1.2 proto ah spi 0x2000
sudo ip netns exec ce4 ip xfrm policy add dir in src 192.168.2.2 dst 192.168.3.2  tmpl src 192.168.2.2 dst 192.168.3.2 proto ah spi 0x3000
sudo ip netns exec ce4 ip xfrm policy add dir out src 192.168.3.2 dst 192.168.2.2  tmpl src 192.168.3.2 dst 192.168.2.2 proto ah spi 0x4000

# ----------------------- e2e between namespaces CE1 and CE5 --------------------------------------------

# Add public IP to hosts
# Assign a public IP address to the network interfaces in the ce1 and ce5 namespaces
sudo ip netns exec ce1 ip  addr add 10.200.0.25/32 dev eth01
sudo ip netns exec ce5 ip  addr add 10.200.0.26/32 dev eth17

# Set up default route
# Add default routes to direct traffic between ce1 and ce5, ensuring the public IP is used as the source IP
sudo ip netns exec ce1 ip route add default via 172.16.0.1 dev eth01 src 10.200.0.25
sudo ip netns exec ce5 ip route add default via 172.16.1.1 dev eth17 src 10.200.0.26

# Inform the gateaway about how to reach the public IP
# Add routes to the gateaway in the pe1 and pe5 namespaces to reach the public IPs
sudo ip netns exec pe1 ip route add 10.200.0.25/32 dev eth02
sudo ip netns exec pe5 ip route add 10.200.0.26/32 dev eth18

# Configure static routing to direct traffic through PE3
# Add static routes on the gateaways (pe1, pe5, pe3) to route packets between the public IPs via PE3
sudo ip netns exec pe1 ip route add 10.200.0.26/32 via 10.200.0.2 dev eth03
sudo ip netns exec pe5 ip route add 10.200.0.25/32 via 10.200.0.9 dev eth19
sudo ip netns exec pe3 ip route add 10.200.0.26/32 via 10.200.0.10 dev eth12
sudo ip netns exec pe3 ip route add 10.200.0.25/32 via 10.200.0.1 dev eth11


# Set up IPsec ESP transport mode states and policies for namespace CE1
sudo ip netns exec ce1 ip xfrm state add src 10.200.0.25 dst 10.200.0.26 proto esp spi 0x1000 \
  enc cbc\(aes\) 0x3c75754276e73d0131551e367bfdcef8 \
  auth hmac\(sha256\)  0xfa74f3627eacf2ba06155c9e0e99073099178ec042e099a1970a98c840f46e2b

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.26 dst 10.200.0.25 proto esp spi 0x2000 \
  enc cbc\(aes\) 0x3a7b9c2f5e8d1a64b7f9e0c2a3d5f8e1 \
  auth hmac\(sha256\)  0xd0f4c86a89d2cf02ccd3ff473204407030c0dc8804fba5d522617b56f00aa24f

sudo ip netns exec ce1 ip xfrm policy add dir out src 10.200.0.25 dst 10.200.0.26 tmpl src 10.200.0.25 dst 10.200.0.26 proto esp spi 0x1000
sudo ip netns exec ce1 ip xfrm policy add dir in src 10.200.0.26 dst 10.200.0.25 tmpl src 10.200.0.26 dst 10.200.0.25 proto esp spi 0x2000

# Set up IPsec ESP transport mode states and policies for namespace CE5
sudo ip netns exec ce5 ip xfrm state add src 10.200.0.25 dst 10.200.0.26 proto esp spi 0x1000 \
  enc cbc\(aes\) 0x3c75754276e73d0131551e367bfdcef8 \
  auth hmac\(sha256\)  0xfa74f3627eacf2ba06155c9e0e99073099178ec042e099a1970a98c840f46e2b

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.26 dst 10.200.0.25 proto esp spi 0x2000 \
  enc cbc\(aes\) 0x3a7b9c2f5e8d1a64b7f9e0c2a3d5f8e1 \
  auth hmac\(sha256\)  0xd0f4c86a89d2cf02ccd3ff473204407030c0dc8804fba5d522617b56f00aa24f

sudo ip netns exec ce5 ip xfrm policy add dir in src 10.200.0.25 dst 10.200.0.26 tmpl src 10.200.0.25 dst 10.200.0.26 proto esp spi 0x1000
sudo ip netns exec ce5 ip xfrm policy add dir out src 10.200.0.26 dst 10.200.0.25 tmpl src 10.200.0.26 dst 10.200.0.25 proto esp spi 0x2000

# ----------------------- remote access for namespace CE1 ---------------------------------

# Assign a IP address from VPN pool (192.168.4.0/24) to the network interface in the CE1 namespace
sudo ip netns exec ce1 ip addr add 192.168.4.1/32 dev eth01

# Add routes to direct traffic between CE1 and CE2/CE3/CE4, ensuring the IP from the VPN pool is used as the source IP
sudo ip netns exec ce1 ip route add 192.168.1.0/24 via 172.16.0.1 dev eth01 src 192.168.4.1
sudo ip netns exec ce1 ip route add 192.168.2.0/24 via 172.16.0.1 dev eth01 src 192.168.4.1
sudo ip netns exec ce1 ip route add 192.168.3.0/24 via 172.16.0.1 dev eth01 src 192.168.4.1

# Configure Static Routes on PE2, PE3, and PE4 for traffic to CE1
# PE2
sudo ip netns exec pe2 ip route add 10.200.0.25/32 via 10.200.0.18 dev eth08
sudo ip netns exec pe2 ip route add 192.168.4.1/32 via 10.200.0.18 dev eth08
sudo ip netns exec ce2 ip route add 192.168.4.0/24 via 192.168.1.1 dev eth05

# PE3
sudo ip netns exec pe3 ip route add 192.168.4.1/32 via 10.200.0.1 dev eth11
sudo ip netns exec ce3 ip route add 192.168.4.0/24 via 192.168.2.1 dev eth09

# PE4
sudo ip netns exec pe4 ip route add 10.200.0.25/32 via 10.200.0.5 dev eth15
sudo ip netns exec pe4 ip route add 192.168.4.1/32 via 10.200.0.5 dev eth15
sudo ip netns exec ce4 ip route add 192.168.4.0/24 via 192.168.3.1 dev eth13

# Set up IPsec ESP tunnel mode states and policies between namespaces CE1 and PE2

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.25 dst 10.200.0.17 proto esp spi 0x7000 mode tunnel \
                auth hmac\(sha256\) 0xcef79c9cb8121b6534f2994448294ec9966b799589dd7401006c49d24de8188e \
    enc 'aes' 0xf06eac104ee52865463f324070717269

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.17 dst 10.200.0.25 proto esp spi 0x8000 mode tunnel \
                auth hmac\(sha256\) 0x3a7124edd2fa6023fe83daed0c47779c67b1b84e1dbaa7f43db9286251e4c9d5 \
    enc 'aes' 0xbcbdcd2f684af3dbe0a336ad20d6b1b2

sudo ip netns exec ce1 ip xfrm policy add src 192.168.4.1/32 dst 192.168.1.0/24 dir out \
    tmpl src 10.200.0.25 dst 10.200.0.17 proto esp mode tunnel

sudo ip netns exec ce1 ip xfrm policy add src 192.168.1.0/24 dst 192.168.4.1/32 dir in \
    tmpl src 10.200.0.17 dst 10.200.0.25 proto esp mode tunnel
    
sudo ip netns exec pe2 ip xfrm state add src 10.200.0.25 dst 10.200.0.17 proto esp spi 0x7000 mode tunnel \
    enc 'aes' 0xf06eac104ee52865463f324070717269 \
    auth hmac\(sha256\) 0xcef79c9cb8121b6534f2994448294ec9966b799589dd7401006c49d24de8188e

sudo ip netns exec pe2 ip xfrm state add src 10.200.0.17 dst 10.200.0.25 proto esp spi 0x8000 mode tunnel \
    enc 'aes' 0xbcbdcd2f684af3dbe0a336ad20d6b1b2 \
    auth hmac\(sha256\) 0x3a7124edd2fa6023fe83daed0c47779c67b1b84e1dbaa7f43db9286251e4c9d5

sudo ip netns exec pe2 ip xfrm policy add src 192.168.1.0/24 dst 192.168.4.1/32 dir out \
    tmpl src 10.200.0.17 dst 10.200.0.25 proto esp mode tunnel

sudo ip netns exec pe2 ip xfrm policy add src 192.168.4.1/32 dst 192.168.1.0/24 dir fwd \
    tmpl src 10.200.0.25 dst 10.200.0.17 proto esp mode tunnel

# Set up IPsec ESP tunnel mode states and policies between namespaces CE1 and PE3

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.25 dst 10.200.0.2 proto esp spi 0x9000 mode tunnel \
    enc 'aes' 0x11688ded8496b41c6544437e4bfd2a6d \
    auth hmac\(sha256\) 0x9847ad16e8cb429ce7944fed13035bbe83798f2ff9bf78bb5806eca66ff8e5fd

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.2 dst 10.200.0.25 proto esp spi 0xa000 mode tunnel \
    enc 'aes' 0xd58efbd28e4b5dbbe3d00deb58499a49 \
    auth hmac\(sha256\) 0xc32e4825f2150e51bbf4372fec53c8ee3e03d508ad5fee7277fc5080423a4d4d

sudo ip netns exec ce1 ip xfrm policy add src 192.168.4.1/32 dst 192.168.2.0/24 dir out \
    tmpl src 10.200.0.25 dst 10.200.0.2 proto esp mode tunnel

sudo ip netns exec ce1 ip xfrm policy add src 192.168.2.0/24 dst 192.168.4.1/32 dir in \
    tmpl src 10.200.0.2 dst 10.200.0.25 proto esp mode tunnel
    
sudo ip netns exec pe3 ip xfrm state add src 10.200.0.25 dst 10.200.0.2 proto esp spi 0x9000 mode tunnel \
    enc 'aes' 0x11688ded8496b41c6544437e4bfd2a6d \
    auth hmac\(sha256\) 0x9847ad16e8cb429ce7944fed13035bbe83798f2ff9bf78bb5806eca66ff8e5fd

sudo ip netns exec pe3 ip xfrm state add src 10.200.0.2 dst 10.200.0.25 proto esp spi 0xa000 mode tunnel \
    enc 'aes' 0xd58efbd28e4b5dbbe3d00deb58499a49 \
    auth hmac\(sha256\) 0xc32e4825f2150e51bbf4372fec53c8ee3e03d508ad5fee7277fc5080423a4d4d

sudo ip netns exec pe3 ip xfrm policy add src 192.168.2.0/24 dst 192.168.4.1/32 dir out \
    tmpl src 10.200.0.2 dst 10.200.0.25 proto esp mode tunnel

sudo ip netns exec pe3 ip xfrm policy add src 192.168.4.1/32 dst 192.168.2.0/24 dir fwd \
    tmpl src 10.200.0.25 dst 10.200.0.2 proto esp mode tunnel

# Set up IPsec ESP tunnel mode states and policies between namespaces CE1 and PE4

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.25 dst 10.200.0.6 proto esp spi 0xb000 mode tunnel \
    enc 'aes' 0xfa92349625d120a73777275230eebe99 \
    auth hmac\(sha256\) 0x227f73861c009352bc0439250fccd83f584065534ae72c1993b26f2500188f07

sudo ip netns exec ce1 ip xfrm state add src 10.200.0.6 dst 10.200.0.25 proto esp spi 0xc000 mode tunnel \
    enc 'aes' 0x6fd522b0d4606b88eea6c9838da11a2f \
    auth hmac\(sha256\) 0x5b813ac9afc82409edefe73da8a0920b585a1ddc3fbef1abe66b369769aea67d

sudo ip netns exec ce1 ip xfrm policy add src 192.168.4.1/32 dst 192.168.3.0/24 dir out \
    tmpl src 10.200.0.25 dst 10.200.0.6 proto esp mode tunnel

sudo ip netns exec ce1 ip xfrm policy add src 192.168.3.0/24 dst 192.168.4.1/32 dir in \
    tmpl src 10.200.0.6 dst 10.200.0.25 proto esp mode tunnel
    
sudo ip netns exec pe4 ip xfrm state add src 10.200.0.25 dst 10.200.0.6 proto esp spi 0xb000 mode tunnel \
    enc 'aes' 0xfa92349625d120a73777275230eebe99 \
    auth hmac\(sha256\) 0x227f73861c009352bc0439250fccd83f584065534ae72c1993b26f2500188f07

sudo ip netns exec pe4 ip xfrm state add src 10.200.0.6 dst 10.200.0.25 proto esp spi 0xc000 mode tunnel \
    enc 'aes' 0x6fd522b0d4606b88eea6c9838da11a2f \
    auth hmac\(sha256\) 0x5b813ac9afc82409edefe73da8a0920b585a1ddc3fbef1abe66b369769aea67d

sudo ip netns exec pe4 ip xfrm policy add src 192.168.3.0/24 dst 192.168.4.1/32 dir out \
    tmpl src 10.200.0.6 dst 10.200.0.25 proto esp mode tunnel

sudo ip netns exec pe4 ip xfrm policy add src 192.168.4.1/32 dst 192.168.3.0/24 dir fwd \
    tmpl src 10.200.0.25 dst 10.200.0.6 proto esp mode tunnel

# ----------------------- remote access for namespace CE5 ---------------------------------

# Assign a IP address from VPN pool (192.168.4.0/24) to the network interface in the CE5 namespace
sudo ip netns exec ce5 ip addr add 192.168.4.2/32 dev eth17

# Add routes to direct traffic between CE5 and CE2/CE3/CE4, ensuring the IP from the VPN pool is used as the source IP
sudo ip netns exec ce5 ip route add 192.168.1.0/24 via 172.16.1.1 dev eth17 src 192.168.4.2
sudo ip netns exec ce5 ip route add 192.168.2.0/24 via 172.16.1.1 dev eth17 src 192.168.4.2
sudo ip netns exec ce5 ip route add 192.168.3.0/24 via 172.16.1.1 dev eth17 src 192.168.4.2

# Configure Static Routes on PE2, PE3, and PE4 for traffic to CE5
# PE2
sudo ip netns exec pe2 ip route add 10.200.0.26/32 via 10.200.0.14 dev eth07
sudo ip netns exec pe2 ip route add 192.168.4.2/32 via 10.200.0.14 dev eth07
sudo ip netns exec ce2 ip route add 192.168.4.0/24 via 192.168.1.1 dev eth05

# PE3
sudo ip netns exec pe3 ip route add 192.168.4.2/32 via 10.200.0.10 dev eth12
sudo ip netns exec ce3 ip route add 192.168.4.0/24 via 192.168.2.1 dev eth09

# PE4
sudo ip netns exec pe4 ip route add 10.200.0.26/32 via 10.200.0.21 dev eth22
sudo ip netns exec pe4 ip route add 192.168.4.2/32 via 10.200.0.21 dev eth22
sudo ip netns exec ce4 ip route add 192.168.4.0/24 via 192.168.3.1 dev eth13

# Set up IPsec ESP tunnel mode states and policies between namespaces CE5 and PE2

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.26 dst 10.200.0.14 proto esp spi 0xd000 mode tunnel \
    enc 'aes' 0xc97c42943e15955e3d3b5b6f72728a3d \
                auth hmac\(sha256\) 0x6e0185a1f0e2775db47f00260653489b29b616dc0f49462ce6e007e83e602319

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.14 dst 10.200.0.26 proto esp spi 0xe000 mode tunnel \
    enc 'aes' 0x1a50ceb727bdf10d9a5e4be9b8ae9659 \
          auth hmac\(sha256\) 0x0b58e58d43ae0233cc52841747d9d376f58acf07fc5dda73a34f22f8c9c98c09

sudo ip netns exec ce5 ip xfrm policy add src 192.168.4.2/32 dst 192.168.1.0/24 dir out \
    tmpl src 10.200.0.26 dst 10.200.0.14 proto esp mode tunnel

sudo ip netns exec ce5 ip xfrm policy add src 192.168.1.0/24 dst 192.168.4.2/32 dir in \
    tmpl src 10.200.0.14 dst 10.200.0.26 proto esp mode tunnel
    
sudo ip netns exec pe2 ip xfrm state add src 10.200.0.26 dst 10.200.0.14 proto esp spi 0xd000 mode tunnel \
   enc 'aes' 0xc97c42943e15955e3d3b5b6f72728a3d \
         auth hmac\(sha256\) 0x6e0185a1f0e2775db47f00260653489b29b616dc0f49462ce6e007e83e602319

sudo ip netns exec pe2 ip xfrm state add src 10.200.0.14 dst 10.200.0.26 proto esp spi 0xe000 mode tunnel \
    enc 'aes' 0x1a50ceb727bdf10d9a5e4be9b8ae9659 \
          auth hmac\(sha256\) 0x0b58e58d43ae0233cc52841747d9d376f58acf07fc5dda73a34f22f8c9c98c09

sudo ip netns exec pe2 ip xfrm policy add src 192.168.1.0/24 dst 192.168.4.2/32 dir out \
    tmpl src 10.200.0.14 dst 10.200.0.26 proto esp mode tunnel

sudo ip netns exec pe2 ip xfrm policy add src 192.168.4.2/32 dst 192.168.1.0/24 dir fwd \
    tmpl src 10.200.0.26 dst 10.200.0.14 proto esp mode tunnel
    
# Set up IPsec ESP tunnel mode states and policies between namespaces CE5 and PE3

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.26 dst 10.200.0.9 proto esp spi 0xf000 mode tunnel \
    enc 'aes' 0xfa9ad3d8976e6d7ee9a5939762e8a989 \
          auth hmac\(sha256\) 0x6e728e9dd47791d700fa08bec5f7e2f181df5fc5826e2743538ad81fab119741

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.9 dst 10.200.0.26 proto esp spi 0x10000 mode tunnel \
    enc 'aes' 0x4f4dea2ac7657081271eaca0b5ca3790 \
          auth hmac\(sha256\) 0xee28e55e557dd6874bb14f943eaf65efeb8e72bb2807510228b203574e64ea30

sudo ip netns exec ce5 ip xfrm policy add src 192.168.4.2/32 dst 192.168.2.0/24 dir out \
    tmpl src 10.200.0.26 dst 10.200.0.9 proto esp mode tunnel

sudo ip netns exec ce5 ip xfrm policy add src 192.168.2.0/24 dst 192.168.4.2/32 dir in \
    tmpl src 10.200.0.9 dst 10.200.0.26 proto esp mode tunnel
    
sudo ip netns exec pe3 ip xfrm state add src 10.200.0.26 dst 10.200.0.9 proto esp spi 0xf000 mode tunnel \
    enc 'aes' 0xfa9ad3d8976e6d7ee9a5939762e8a989 \
          auth hmac\(sha256\) 0x6e728e9dd47791d700fa08bec5f7e2f181df5fc5826e2743538ad81fab119741

sudo ip netns exec pe3 ip xfrm state add src 10.200.0.9 dst 10.200.0.26 proto esp spi 0x10000 mode tunnel \
    enc 'aes' 0x4f4dea2ac7657081271eaca0b5ca3790 \
          auth hmac\(sha256\) 0xee28e55e557dd6874bb14f943eaf65efeb8e72bb2807510228b203574e64ea30

sudo ip netns exec pe3 ip xfrm policy add src 192.168.2.0/24 dst 192.168.4.2/32 dir out \
    tmpl src 10.200.0.9 dst 10.200.0.26 proto esp mode tunnel

sudo ip netns exec pe3 ip xfrm policy add src 192.168.4.2/32 dst 192.168.2.0/24 dir fwd \
    tmpl src 10.200.0.26 dst 10.200.0.9 proto esp mode tunnel

# Set up IPsec ESP tunnel mode states and policies between namespaces CE5 and PE4

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.26 dst 10.200.0.22 proto esp spi 0x11000 mode tunnel \
    enc 'aes' 0x41b2c59c4256d721521f2b8385322677 \
          auth hmac\(sha256\) 0xf81f2f7fa4a6d653bb3f86aa01034b642203b51c5c562b4bfe7c1a6da46fb273

sudo ip netns exec ce5 ip xfrm state add src 10.200.0.22 dst 10.200.0.26 proto esp spi 0x12000 mode tunnel \
    enc 'aes' 0x5b5922481a6e0389645e2e0c9e490adb \
                auth hmac\(sha256\) 0x2849dab129abbc9c625f0aeb31abdb61bace168ce91208caaad18cc36eab46c1

sudo ip netns exec ce5 ip xfrm policy add src 192.168.4.2/32 dst 192.168.3.0/24 dir out \
    tmpl src 10.200.0.26 dst 10.200.0.22 proto esp mode tunnel

sudo ip netns exec ce5 ip xfrm policy add src 192.168.3.0/24 dst 192.168.4.2/32 dir in \
    tmpl src 10.200.0.22 dst 10.200.0.26 proto esp mode tunnel
    
sudo ip netns exec pe4 ip xfrm state add src 10.200.0.26 dst 10.200.0.22 proto esp spi 0x11000 mode tunnel \
    enc 'aes' 0x41b2c59c4256d721521f2b8385322677 \
          auth hmac\(sha256\) 0xf81f2f7fa4a6d653bb3f86aa01034b642203b51c5c562b4bfe7c1a6da46fb273

sudo ip netns exec pe4 ip xfrm state add src 10.200.0.22 dst 10.200.0.26 proto esp spi 0x12000 mode tunnel \
    enc 'aes' 0x5b5922481a6e0389645e2e0c9e490adb \
          auth hmac\(sha256\) 0x2849dab129abbc9c625f0aeb31abdb61bace168ce91208caaad18cc36eab46c1

sudo ip netns exec pe4 ip xfrm policy add src 192.168.3.0/24 dst 192.168.4.2/32 dir out \
    tmpl src 10.200.0.22 dst 10.200.0.26 proto esp mode tunnel

sudo ip netns exec pe4 ip xfrm policy add src 192.168.4.2/32 dst 192.168.3.0/24 dir fwd \
    tmpl src 10.200.0.26 dst 10.200.0.22 proto esp mode tunnel