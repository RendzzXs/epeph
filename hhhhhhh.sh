#!/bin/bash
# ============================================
#   💥 VPS TOTAL RESET (VISUAL PROGRESS)
#   Hapus Total + Install Ulang Bersih
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAGENTA='\033[0;35m'; NC='\033[0m'; BOLD='\033[1m'

[[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Harus root!${NC}"; exit 1; }

# ============ FUNGSI ANIMASI ============
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

progress_bar() {
    local duration=$1
    local message=$2
    local steps=40
    local sleep_time=$(echo "scale=4; $duration / $steps" | bc)
    echo -ne "  ${CYAN}${message}${NC}\n  ["
    for ((i=0; i<=steps; i++)); do
        local percent=$((i * 100 / steps))
        printf "\r  ["
        for ((j=0; j<i; j++)); do printf "${GREEN}█${NC}"; done
        for ((j=i; j<steps; j++)); do printf "░"; done
        printf "] ${BOLD}%3d%%${NC}" $percent
        sleep $sleep_time
    done
    echo ""
}

# ============ BANNER ============
clear
echo -e "${RED}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  💥 VPS TOTAL RESET & REINSTALL (VISUAL MODE)            ║"
echo "║  SEMUA WEB, DATABASE, & CONFIG AKAN DIHAPUS TOTAL!       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

read -p "$(echo -e ${YELLOW}Ketik 'HAPUS' untuk melanjutkan: ${NC})" CONFIRM
if [[ "$CONFIRM" != "HAPUS" ]]; then
    echo -e "${YELLOW}Dibatalkan.${NC}"
    exit 0
fi

echo ""

# ============ TAHAP 1: HAPUS FILE ============
echo -e "${MAGENTA}▶ TAHAP 1: MENGHAPUS FILE & KONFIGURASI${NC}"
progress_bar 3 "Membersihkan /var/www/*"
progress_bar 1 "Menghapus Config Nginx"
progress_bar 1 "Menghapus Config PHP"
progress_bar 1 "Menghapus Sisa Pterodactyl (Wings, dll)"
progress_bar 1 "Menghapus Cache Node.js (npm, pm2)"
echo -e "${GREEN}  ✔ File & Config Terhapus${NC}\n"

# Eksekusi Hapus (Background)
(systemctl stop nginx php8.3-fpm mysql redis-server pterodactyl* wings >/dev/null 2>&1
 rm -rf /var/www/* /var/www/.[!.]* 2>/dev/null
 rm -rf /etc/nginx/sites-enabled/* /etc/nginx/sites-available/* /etc/nginx/conf.d/* /etc/nginx/nginx.conf 2>/dev/null
 rm -rf /etc/php/8.3 /var/lib/pterodactyl /etc/pterodactyl /usr/local/bin/wings 2>/dev/null
 rm -rf /root/.pm2 /root/.npm /var/lib/mysql/* /etc/mysql 2>/dev/null
 rm -rf /var/log/nginx/* /var/log/php* /var/log/mysql/* 2>/dev/null) &
wait

# ============ TAHAP 2: UNINSTALL PACKAGES ============
echo -e "${MAGENTA}▶ TAHAP 2: UNINSTALL PACKAGES LAMA${NC}"
progress_bar 4 "Menghapus Nginx & PHP"
progress_bar 3 "Menghapus MySQL & Redis"
progress_bar 2 "Menghapus Node.js & Certbot"
echo -e "${GREEN}  ✔ Uninstall Selesai${NC}\n"

export DEBIAN_FRONTEND=noninteractive
(apt purge nginx nginx-common nginx-full php* mysql-server mysql-client mysql-common nodejs npm redis-server certbot python3-certbot-nginx -y -qq >/dev/null 2>&1
 apt autoremove -y -qq >/dev/null 2>&1
 apt autoclean -y -qq >/dev/null 2>&1) &
wait

# ============ TAHAP 3: BERSIHKAN SISA DEPENDENCY ============
echo -e "${MAGENTA}▶ TAHAP 3: BERSIHKAN SISA DEPENDENCY${NC}"
progress_bar 2 "Menghapus Repo Node.js & PPA PHP lama"
progress_bar 1 "Update Package List"
progress_bar 2 "Fixing Broken Packages"
echo -e "${GREEN}  ✔ Sistem Bersih${NC}\n"

(rm -f /etc/apt/sources.list.d/nodesource.list /etc/apt/sources.list.d/ondrej-php.list
 apt clean
 apt update -qq 2>/dev/null
 apt --fix-broken install -y -qq >/dev/null 2>&1) &
wait

# ============ TAHAP 4: INSTALL ULANG ============
echo -e "${MAGENTA}▶ TAHAP 4: INSTALL ULANG SEMUA SERVICE${NC}"
progress_bar 3 "Menambahkan Repo (Ondrej PHP & Node.js 20)"
(apt install software-properties-common curl wget git unzip -y -qq >/dev/null 2>&1
 add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
 curl -fsSL https://deb.nodesource.com/setup_20.x | bash - >/dev/null 2>&1) &
wait

progress_bar 2 "Update Package List (Fresh)"
apt update -qq 2>/dev/null

progress_bar 8 "Install Nginx & PHP 8.3 (FPM, MySQL, Curl, XML, dll)"
progress_bar 5 "Install MySQL Server & Redis"
progress_bar 4 "Install Node.js 20 & Certbot"
echo -e "${GREEN}  ✔ Install Selesai${NC}\n"

apt install nginx php8.3-fpm php8.3-mysql php8.3-mbstring php8.3-curl php8.3-xml php8.3-zip php8.3-gd php8.3-intl php8.3-bcmath php8.3-redis mysql-server nodejs redis-server certbot python3-certbot-nginx -y -qq >/dev/null 2>&1

# ============ TAHAP 5: SETUP ULANG DEFAULT ============
echo -e "${MAGENTA}▶ TAHAP 5: SETUP ULANG & START SERVICE${NC}"
progress_bar 2 "Start Nginx, PHP, MySQL, Redis"
(systemctl enable nginx php8.3-fpm mysql redis-server >/dev/null 2>&1
 systemctl start nginx php8.3-fpm mysql redis-server >/dev/null 2>&1) &
wait

progress_bar 1 "Bikin Web Default (/var/www/html)"
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

cat > /etc/nginx/sites-available/default << 'NGINXEOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    root /var/www/html;
    index index.html index.php;
    location / { try_files $uri $uri/ =404; }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
progress_bar 1 "Reload Nginx"
nginx -t >/dev/null 2>&1 && systemctl reload nginx
echo -e "${GREEN}  ✔ Setup Selesai${NC}\n"

# ============ TAHAP 6: HASIL AKHIR ============
echo -e "${CYAN}${BOLD}Mengumpulkan data status...${NC}"
sleep 1

clear
echo -e "${GREEN}${BOLD}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  ✅ VPS BERHASIL DI-RESET & INSTALL ULANG!               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo -e "${CYAN}📊 Status Service:${NC}"
printf "  %-15s : %s\n" "Nginx" "$(systemctl is-active nginx | sed 's/active/✅ Active/;s/inactive/❌ Inactive/')"
printf "  %-15s : %s\n" "PHP-FPM 8.3" "$(systemctl is-active php8.3-fpm | sed 's/active/✅ Active/;s/inactive/❌ Inactive/')"
printf "  %-15s : %s\n" "MySQL" "$(systemctl is-active mysql | sed 's/active/✅ Active/;s/inactive/❌ Inactive/')"
printf "  %-15s : %s\n" "Redis" "$(systemctl is-active redis-server | sed 's/active/✅ Active/;s/inactive/❌ Inactive/')"
printf "  %-15s : %s\n" "Node.js" "$(node -v 2>/dev/null || echo '❌ Not Found')"

echo ""
echo -e "${CYAN}📦 Versi Terinstall:${NC}"
printf "  %-15s : %s\n" "PHP" "$(php -v 2>/dev/null | head -n 1 | cut -d ' ' -f 2)"
printf "  %-15s : %s\n" "Nginx" "$(nginx -v 2>&1 | cut -d '/' -f 2)"
printf "  %-15s : %s\n" "MySQL" "$(mysql --version 2>/dev/null | cut -d ' ' -f 4 | cut -d ',' -f 1)"
printf "  %-15s : %s\n" "Node.js" "$(node -v 2>/dev/null)"

echo ""
echo -e "${CYAN}💾 Storage VPS:${NC}"
df -h / | tail -1 | awk '{printf "  Total: %s | Used: %s | Free: %s | Use%%: %s\n", $2, $3, $4, $5}'

echo ""
echo -e "${GREEN}🚀 Silakan buka IP VPS di browser!${NC}"
echo ""
