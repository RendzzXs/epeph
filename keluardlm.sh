#!/bin/bash
# ============================================
#   🚑 FIX DPKG & MARIADB ERROR
# ============================================

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}[1/4] Berhenti paksa service database...${NC}"
systemctl stop mariadb 2>/dev/null
systemctl stop mysql 2>/dev/null
pkill -9 mysqld 2>/dev/null

echo -e "${CYAN}[2/4] Hapus lock file dpkg...${NC}"
rm -f /var/lib/dpkg/lock-frontend
rm -f /var/lib/dpkg/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/apt/lists/lock
dpkg --configure -a

echo -e "${CYAN}[3/4] Uninstall sisa MariaDB/MySQL yang corrupt...${NC}"
apt-get purge -y mariadb-server mariadb-client mariadb-common mysql-server mysql-client mysql-common 2>/dev/null
rm -rf /var/lib/mysql/*
rm -rf /etc/mysql

echo -e "${CYAN}[4/4] Bersihkan & Reinstall ulang MariaDB...${NC}"
apt-get autoremove -y
apt-get autoclean -y
apt-get update -y
apt-get install -y mariadb-server mariadb-client

# Start MariaDB
systemctl enable mariadb
systemctl start mariadb

if systemctl is-active --quiet mariadb; then
    echo -e "${GREEN}✅ MARIA DB BERHASIL DI-INSTALL & AKTIF!${NC}"
else
    echo -e "${RED}❌ Masih gagal bro. Cek log: journalctl -xe${NC}"
fi
