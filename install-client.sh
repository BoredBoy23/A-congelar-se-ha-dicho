#!/data/data/com.termux/files/usr/bin/bash

clear
export APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

### ===============================
### COMPROBAR TERMUX
### ===============================
if [ ! -d "/data/data/com.termux" ]; then
    echo "[!] Este script solo funciona en Termux."
    exit 1
fi

### ===============================
### COMPROBAR / INSTALAR DIALOG
### ===============================
if ! command -v dialog >/dev/null 2>&1; then
    pkg update -y >/dev/null 2>&1
    pkg install dialog -y >/dev/null 2>&1
fi

if command -v dialog >/dev/null 2>&1; then
    MODE="DIALOG"
else
    MODE="TEXT"
fi

### ===============================
### FUNCIONES UI
### ===============================
msg() {
    if [ "$MODE" = "DIALOG" ]; then
        dialog --msgbox "$1" 10 55
    else
        echo -e "\n$1\n"
    fi
}

confirm() {
    if [ "$MODE" = "DIALOG" ]; then
        dialog --yesno "$1" 8 45
        return $?
    else
        read -p "$1 (y/n): " r
        [[ "$r" =~ ^[Yy]$ ]]
    fi
}

### ===============================
### BIENVENIDA
### ===============================
msg "Bienvenido al instalador VIP de Razihel.\n\nSe instalarán todas las herramientas necesarias."

confirm "¿Deseas continuar?"
[ $? -ne 0 ] && clear && exit 1

### ===============================
### CONFIGURAR REPOS (LIMPIO)
### ===============================
if [ "$MODE" = "DIALOG" ]; then
    dialog --infobox "Configurando repositorios...\n\nPor favor espera." 6 50
    sleep 1
    clear
    termux-change-repo
    clear
else
    termux-change-repo
fi

### ===============================
### INSTALACIÓN CON PROGRESO REAL
### ===============================
install_with_progress() {
    echo 10
    pkg update -y >/dev/null 2>&1

    echo 25
    pkg upgrade -y >/dev/null 2>&1

    echo 40
    pkg install wget brotli openssl -y >/dev/null 2>&1

    echo 55
    pkg install termux-tools dos2unix -y >/dev/null 2>&1

    echo 70
    wget -q https://raw.githubusercontent.com/Mahboub-power-is-back/quic_over_dns/main/slipstream-client

    echo 85
    chmod +x slipstream-client

    echo 100
}

if [ "$MODE" = "DIALOG" ]; then
    install_with_progress | dialog --gauge "Instalando herramientas..." 10 60 0
else
    install_with_progress
fi

### ===============================
### FINAL
### ===============================
msg "Instalación completada correctamente."

clear
