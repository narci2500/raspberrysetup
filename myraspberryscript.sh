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
sudo cp unbound.conf ~/docker/unbound/config/unbound.conf
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
