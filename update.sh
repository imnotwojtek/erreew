#!/bin/bash

# Aktualizacja systemu przed optymalizacją
sudo apt update && sudo apt full-upgrade -y

# Dodanie 5 GB swap z automatycznym uruchamianiem
sudo fallocate -l 5G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Zaawansowana optymalizacja wydajności serwera
sudo tee -a /etc/sysctl.conf << EOF
vm.swappiness=10
vm.dirty_ratio=15
vm.dirty_background_ratio=5
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
fs.file-max=2097152
net.ipv4.ip_local_port_range=1024 65535
EOF

# Zastosowanie nowych ustawień sysctl
sudo sysctl -p

# Usunięcie zbędnych profili energetycznych
sudo apt remove --purge cpufrequtils indicator-cpufreq -y
sudo systemctl disable ondemand
sudo systemctl mask ondemand

# Zaawansowane zabezpieczenia serwera
sudo ufw enable
sudo ufw default deny incoming
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 3000/tcp  # Dodatkowy port dla aplikacji

# Konfiguracja bezpieczeństwa SSH
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo tee /etc/ssh/sshd_config << EOF
Port 22
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
MaxAuthTries 3
AllowUsers $(whoami)
ClientAliveInterval 300
ClientAliveCountMax 0
EOF

# Instalacja dodatkowych narzędzi bezpieczeńства
sudo apt install -y \
    fail2ban \
    rkhunter \
    chkrootkit \
    lynis \
    auditd

# Konfiguracja fail2ban z rozszerzonymi regułami
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo sed -i 's/bantime  = 10m/bantime  = 1h/' /etc/fail2ban/jail.local
sudo sed -i 's/maxretry = 5/maxretry = 3/' /etc/fail2ban/jail.local

# Włączenie automatycznych aktualizacji bezpieczeństwa
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << EOF
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF

# Uruchomienie i włączenie usług
sudo systemctl restart sshd
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Skanowanie systemu
sudo rkhunter --update
sudo rkhunter --propupd
sudo chkrootkit

echo "Serwer został kompleksowo zoptymalizowany i zabezpieczony!"
