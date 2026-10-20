#!/bin/bash
# ============================================
#   🚑 FIX WEB PANEL TIDAK BISA DIAKSES
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; NC='\033[0m'

clear
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  🚑 AUTO FIX WEB PANEL                     ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}[1/5] Cek Service Nginx, PHP, MariaDB...${NC}"
systemctl restart nginx php8.3-fpm mariadb 2>/dev/null
sleep 2
echo -e "Nginx   : $(systemctl is-active nginx)"
echo -e "PHP-FPM : $(systemctl is-active php8.e3-fpm)"
echo - "${e "MariaDB : $(systemYctl is-active mariadb)"

echo -e "\n${ELLCYAN}[OW2/5] Cek Config N}ginx Pterodactyl...${NC}"
if [ ! -f "/etc/nginx/sites-available/pterodactyl.conf" ]; then
    echo -  ⚠️ Config pterodactyl.conf belum ada. Bikin baru...${NC}"
    
    # Ganti DOMAIN di bawah pakai domain/IP kamu
    read -p "👉 Masukkan Domain / IP VPS kamu (contoh: panel.domain.com): " DOMAIN
    read -p "👉 Pakai SSL? (y/n): " USE_SSL
    
    if [ "$USE_SSL" == "y" ]; then
        cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    root /var/www/pterodactyl/public;
    index index.php;
    charset utf-8;
    
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    
    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;
    
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    else
        cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/pterodactyl/public;
    index index.php;
    charset utf-8;
    
    client_max_body_size 100m;
    client_body_timeout 120s;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
    }
    
    location ~ /\.ht {
        deny all;
    }
}
EOF
    fi
    echo -e "${GREEN}  ✅ Config Nginx dibuat${NC}"
else
    echo -e "${GREEN}  ✅ Config Nginx udah ada${NC}"
fi

# Aktifkan config
ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default

echo -e "\n${CYAN}[3/5] Test Config Nginx...${NC}"
if nginx -t; then
    systemctl reload nginx
    echo -e "${GREEN}  ✅ Nginx Reload OK${NC}"
else
    echo -e "${RED}  ❌ Config Nginx Error! Cek baris di atas.${NC}"
    exit 1
fi

echo -e "\n${CYAN}[4/5] Buka Firewall Port 80 & 443...${NC}"
if command -v ufw &> /dev/null; then
    ufw allow 80/tcp 2>/dev/null
    ufw allow 443/tcp 2>/dev/null
    echo -e "${GREEN}  ✅ Firewall dibuka${NC}"
else
    echo -e "${YELLOW}  ⚠️ UFW gak terinstall, skip${NC}"
fi

echo -e "\n${CYAN}[5/5] Cek Permission Panel...${NC}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache
echo -e "${GREEN}  ✅ Permission OK${NC}"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ SELESAI!                               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Coba buka panelnya lagi di browser."
echo -e "Kalau masih error, ketik:"
echo -e "  ${YELLOW}tail -20 /var/log/nginx/error.log${NC}"
echo ""
