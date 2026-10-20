#!/bin/bash
# ============================================
#   💥 VPS TOTAL RESET & REPAIR
#   Hapus semua web, DB, & Install ulang bersih
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

clear
echo -e "${RED}╔════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  💥 VPS TOTAL RESET & REPAIR               ║${NC}"
echo -e "${RED}║  SEMUA WEB & DATABASE AKAN DIHAPUS!        ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Script ini akan:${NC}"
echo "  1. Menghapus semua folder web (/var/www/*)"
echo "  2. Uninstall PHP, Nginx, MySQL, Node.js"
echo "  3. Membersihkan sisa config (/etc/nginx, /etc/php, dll)"
echo "  4. Membersihkan cache & log sistem"
echo "  5. Install ulang semua dari 0 (Fresh)"
echo ""

read -p "Ketik 'HAPUS' untuk melanjutkan: " CONFIRM
if [[ "$CONFIRM" != "HAPUS" ]]; then
    echo -e "${YELLOW}Dibatalkan.${NC}"
    exit 0
fi

echo -e "\n${CYAN}[1/6] Stop semua service...${NC}"
systemctl stop nginx 2>/dev/null
systemctl stop php8.3-fpm 2>/dev/null
systemctl stop mysql 2>/dev/null
systemctl stop redis-server 2>/dev/null
systemctl stop pterodactyl* 2>/dev/null
echo -e "${GREEN}  ✓ Service dihentikan${NC}"

echo -e "${CYAN}[2/6] Hapus semua folder web & sisa config...${NC}"
# Hapus file web
rm -rf /var/www/*
rm -rf /var/www/.[!.]* 2>/dev/null

# Hapus config Nginx
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/conf.d/*
rm -f /etc/nginx/nginx.conf

# Hapus config PHP
rm -rf /etc/php/8.3

# Hapus sisa file Pterodactyl / Node.js
rm -rf /var/lib/pterodactyl
rm -rf /etc/pterodactyl
rm -rf /usr/local/bin/wings
rm -rf /root/.pm2
rm -rf /root/.npm

# Hapus database MySQL
rm -rf /var/lib/mysql/*
rm -rf /etc/mysql

# Hapus log
rm -rf /var/log/nginx/*
rm -rf /var/log/php*
rm -rf /var/log/mysql/*
echo -e "${GREEN}  ✓ File & config dihapus${NC}"

echo -e "${CYAN}[3/6] Uninstall total (PHP, Nginx, MySQL, Node.js)...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt purge nginx nginx-common nginx-full php* mysql-server mysql-client mysql-common nodejs npm redis-server certbot python3-certbot-nginx -y -qq >/dev/null 2>&1
apt autoremove -y -qq >/dev/null 2>&1
apt autoclean -y -qq >/dev/null 2>&1
echo -e "${GREEN}  ✓ Uninstall selesai${NC}"

echo -e "${CYAN}[4/6] Bersihkan sisa file & dependency rusak...${NC}"
# Hapus file repo nodejs lama (kadang bikin error pas install ulang)
rm -f /etc/apt/sources.list.d/nodesource.list
rm -f /etc/apt/sources.list.d/ondrej-php.list

# Bersihkan cache apt
apt clean
apt update -qq 2>/dev/null

# Fix broken packages
apt --fix-broken install -y -qq >/dev/null 2>&1
echo -e "${GREEN}  ✓ Sistem dibersihkan${NC}"

echo -e "${CYAN}[5/6] Install ulang FRESH (PHP 8.3, Nginx, MySQL)...${NC}"

# Tambah repo PHP & Node.js
apt install software-properties-common curl wget git unzip -y -qq >/dev/null 2>&1
add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1
apt update -qq 2>/dev/null

# Install semua package yang dibutuhkan
apt install nginx php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-curl php8.3-xml php8.3-zip php8.3-gd php8.3-intl php8.3-bcmath php8.3-redis mysql-server nodejs redis-server certbot python3-certbot-nginx -y -qq >/dev/null 2>&1

echo -e "${GREEN}  ✓ Fresh install selesai${NC}"

echo -e "${CYAN}[6/6] Setup ulang & Start Service...${NC}"
systemctl enable nginx php8.3-fpm mysql redis-server >/dev/null 2>&1
systemctl start nginx php8.3-fpm mysql redis-server >/dev/null 2>&1

# Bikin folder default web
mkdir -p /var/www/html
cat > /var/www/html/index.html << 'HTML'
<!DOCTYPE html>
<html>
<head><title>VPS Fresh Install</title></head>
<body style="font-family:sans-serif;text-align:center;padding:50px">
    <h1>🚀 VPS Kamu Sudah Fresh!</h1>
    <p>Semua service (Nginx, PHP, MySQL, Node.js) berjalan normal.</p>
</body>
</html>
HTML

# Bikin config Nginx default
cat > /etc/nginx/sites-available/default << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.php;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
nginx -t >/dev/null 2>&1 && systemctl reload nginx

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ VPS BERHASIL DI-RESET SEPERTI BARU!    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}📊 Status Service:${NC}"
echo -e "  Nginx   : $(systemctl is-active nginx)"
echo -e "  PHP-FPM : $(systemctl is-active php8.3-fpm)"
echo -e "  MySQL   : $(systemctl is-active mysql)"
echo -e "  Redis   : $(systemctl is-active redis-server)"
echo -e "  Node.js : $(node -v 2>/dev/null || echo 'Not found')"
echo ""
echo -e "${CYAN}📦 Versi Terinstall:${NC}"
echo -e "  PHP     : $(php -v | head -n 1 | cut -d ' ' -f 2)"
echo -e "  Nginx   : $(nginx -v 2>&1 | cut -d '/' -f 2)"
echo -e "  MySQL   : $(mysql --version | cut -d ' ' -f 4 | cut -d ',' -f 1)"
echo ""
echo -e "${YELLOW}💡 Storage VPS:${NC}"
df -h / | tail -1 | awk '{print "  Used: "$3" | Free: "$4" | Use%: "$5}'
echo ""
echo -e "${GREEN}🚀 Selesai! Silakan buka IP VPS di browser.${NC}"
