#!/bin/bash

# System aktualisieren
echo "Updating system..."
sudo apt update && sudo apt upgrade -y

# Installiere Cockpit, Fail2ban, curl, wget und ufw
echo "Installing Cockpit, Fail2ban, curl, wget, and ufw..."
sudo apt install -y cockpit fail2ban curl wget ufw

# Benutzer systeam erstellen und zufälliges Passwort generieren
echo "Creating user 'systeam'..."
USER="systeam"
PASSWORD=$(openssl rand -base64 12)

# Erstelle den Benutzer
sudo useradd -m -s /bin/bash $USER
echo "$USER:$PASSWORD" | sudo chpasswd

# Füge den Benutzer zur sudo-Gruppe hinzu
echo "Adding 'systeam' user to the sudo group..."
sudo usermod -aG sudo $USER

# Netplan-Konfiguration erstellen
echo "Generating /etc/netplan/50-cloud-init.yaml..."
sudo bash -c 'cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
  version: 2
  renderer: NetworkManager
EOF'

# Cockpit starten und sicherstellen, dass es beim Booten startet
echo "Enabling and starting Cockpit service..."
sudo systemctl enable --now cockpit

# Fail2ban starten und sicherstellen, dass es beim Booten startet
echo "Enabling and starting Fail2ban service..."
sudo systemctl enable --now fail2ban

# UFW konfigurieren
echo "Configuring UFW firewall..."

# UFW aktivieren und Port 22 sowie 9090 freigeben
sudo ufw allow 22
sudo ufw allow 9090
sudo ufw enable

# Frage nach weiteren Ports, die freigegeben werden sollen
while true; do
    echo "Which ports would you like to allow (e.g., 1000-1003)?"
    read -p "Enter ports: " ports

    # Wenn ein Bereich angegeben wird, einzelnen Ports freigeben
    if [[ "$ports" =~ ^[0-9]+-[0-9]+$ ]]; then
        start=$(echo $ports | cut -d'-' -f1)
        end=$(echo $ports | cut -d'-' -f2)

        for ((port=$start; port<=$end; port++)); do
            echo "Allowing port $port"
            sudo ufw allow $port
        done
    else
        # Einzelne Ports
        for port in $ports; do
            echo "Allowing port $port"
            sudo ufw allow $port
        done
    fi

    # Frage, ob noch weitere Ports freigegeben werden sollen
    read -p "Are there any more ports you'd like to allow? (y/n): " answer
    if [[ "$answer" =~ ^[Nn]$ ]]; then
        break
    fi
done

# Überprüfung der UFW-Regeln
echo "Current UFW rules:"
sudo ufw status verbose

# Passwort für den Benutzer 'systeam' anzeigen
echo "Password for 'systeam': $PASSWORD"

# Installation abgeschlossen, Benutzer zur Bestätigung auffordern
read -p "Are you satisfied with the installation? (y/n): " satisfied

if [[ "$satisfied" =~ ^[Yy]$ ]]; then
    # Reboot des Systems
    echo "Rebooting system..."
    sudo reboot
else
    echo "Installation not completed as requested. Please review."
fi
