#myraspsetup.sh
echo ""
echo ""
echo "░█▀▄░█▀█░█▀▀░█▀█░█▀▄░█▀▀░█▀▄░█▀▄░█░█░░░░░░░░░█▀█░█▀█░█▀▄░█▀▀░░░█▀▀░█▀▄░▀█▀░▀█▀░▀█▀░█▀█░█▀█"
echo "░█▀▄░█▀█░▀▀█░█▀▀░█▀▄░█▀▀░█▀▄░█▀▄░░█░░░░▄▄▄░░░█░█░█▀█░█▀▄░█░░░░░█▀▀░█░█░░█░░░█░░░█░░█░█░█░█"
echo "░▀░▀░▀░▀░▀▀▀░▀░░░▀▀░░▀▀▀░▀░▀░▀░▀░░▀░░░░░░░░░░▀░▀░▀░▀░▀░▀░▀▀▀░░░▀▀▀░▀▀░░▀▀▀░░▀░░▀▀▀░▀▀▀░▀░▀"
echo ""
echo "##########################################################################################"
echo ""
echo "# Updating system"
echo ""

sudo apt-get update
sudo apt-get upgrade -y

echo ""
echo "# System Updated"
echo "# Installing Docker"
echo ""

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo rm get-docker.sh
sudo usermod -aG docker $(whoami)

echo ""
echo "# Docker installed"
echo ""
echo "# Create Docker network"
docker network create -d macvlan \
    --subnet 192.168.1.0/24 \
    --gateway 192.168.1.1 \
    -o parent=eth0 \
    local
echo "# Docker network created"
echo "# Installing Portainer"
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ~/docker/portainer:/data \
    portainer/portainer-ce
echo "# Portainer installed"
echo "# Installing Nginx-Proxy-Manager"
docker run --name nginx \
    --network local \
    --ip 192.168.1.200 \
    -p 443:443/tcp -p 80:80/tcp -p 81:81/tcp \
    -v ~/docker/nginx/data:/data \
    -v ~/docker/letsencrypt:/etc/letsencrypt \
    --restart unless-stopped \
    -d jc21/nginx-proxy-manager:latest
echo "# Nginx-Proxy-Manager installed"
echo "# Installing Unbound"
sudo mkdir -p ~/docker/unbound/config/
sudo touch ~/docker/unbound/config/unbound.conf
sudo echo "server:
    # If no logfile is specified, syslog is used
    # logfile: "/var/log/unbound/unbound.log"
    verbosity: 0

    interface: 127.0.0.1
    port: 5335
    do-ip4: yes
    do-udp: yes
    do-tcp: yes

    # May be set to yes if you have IPv6 connectivity
    do-ip6: no

    # You want to leave this to no unless you have *native* IPv6. With 6to4 and
    # Terredo tunnels your web browser should favor IPv4 for the same reasons
    prefer-ip6: no

    # Use this only when you downloaded the list of primary root servers!
    # If you use the default dns-root-data package, unbound will find it automatically
    #root-hints: "/var/lib/unbound/root.hints"

    # Trust glue only if it is within the server's authority
    harden-glue: yes

    # Require DNSSEC data for trust-anchored zones, if such data is absent, the zone becomes BOGUS
    harden-dnssec-stripped: yes

    # Don't use Capitalization randomization as it known to cause DNSSEC issues sometimes
    # see https://discourse.pi-hole.net/t/unbound-stubby-or-dnscrypt-proxy/9378 for further details
    use-caps-for-id: no

    # Reduce EDNS reassembly buffer size.
    # IP fragmentation is unreliable on the Internet today, and can cause
    # transmission failures when large DNS messages are sent via UDP. Even
    # when fragmentation does work, it may not be secure; it is theoretically
    # possible to spoof parts of a fragmented DNS message, without easy
    # detection at the receiving end. Recently, there was an excellent study
    # >>> Defragmenting DNS - Determining the optimal maximum UDP response size for DNS <<<
    # by Axel Koolhaas, and Tjeerd Slokker (https://indico.dns-oarc.net/event/36/contributions/776/)
    # in collaboration with NLnet Labs explored DNS using real world data from the
    # the RIPE Atlas probes and the researchers suggested different values for
    # IPv4 and IPv6 and in different scenarios. They advise that servers should
    # be configured to limit DNS messages sent over UDP to a size that will not
    # trigger fragmentation on typical network links. DNS servers can switch
    # from UDP to TCP when a DNS response is too big to fit in this limited
    # buffer size. This value has also been suggested in DNS Flag Day 2020.
    edns-buffer-size: 1232

    # Perform prefetching of close to expired message cache entries
    # This only applies to domains that have been frequently queried
    prefetch: yes

    # One thread should be sufficient, can be increased on beefy machines. In reality for most users running on small networks or on a single machine, it should be unnecessary to seek performance enhancement by increasing num-threads above 1.
    num-threads: 1

    # Ensure kernel buffer is large enough to not lose messages in traffic spikes
    so-rcvbuf: 1m

    # Ensure privacy of local IP ranges
    private-address: 192.168.0.0/16
    private-address: 169.254.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8
    private-address: fd00::/8
    private-address: fe80::/10" > ~/docker/unbound/config/unbound.conf


docker run --name unbound \
    --network local \
    --ip 192.168.1.254 \
    -p 5335:5335/tcp -p 5335:5335/udp \
    -v ~/docker/unbound/config:/etc/unbound/custom.conf.d \
    --restart unless-stopped \
    -d klutchell/unbound
echo "# Unbound installed"
echo "# Installing AdguardHome"
docker run --name adguardhome \
    --network local \
    --ip 192.168.1.250 \
    --restart unless-stopped \
    -v ~/docker/adguardhome/work:/opt/adguardhome/work \
    -v ~/docker/adguardhome/conf:/opt/adguardhome/conf \
    -v ~/docker/letsencrypt:/etc/letsencrypt \
    -p 53:53/tcp -p 53:53/udp \
    -p 67:67/udp -p 68:68/udp \
    -p 80:80/tcp -p 443:443/tcp -p 443:443/udp -p 3000:3000/tcp \
    -p 853:853/tcp \
    -p 784:784/udp -p 853:853/udp -p 8853:8853/udp \
    -p 5443:5443/tcp -p 5443:5443/udp \
    -d adguard/adguardhome
echo "# AdguardHome installed"