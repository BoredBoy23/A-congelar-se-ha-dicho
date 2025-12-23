#!/data/data/com.termux/files/usr/bin/bash

clear

DOMAIN="dns.etecsafree.work.gd"
ACTIVE_DNS="No conectado"
LOG_DIR="$HOME/.slipstream"
LOG_FILE="$LOG_DIR/slip.log"

mkdir -p "$LOG_DIR"

DATA_SERVERS=(
"200.55.128.130:53"
"200.55.128.140:53"
"200.55.128.230:53"
"200.55.128.250:53"
)

WIFI_SERVERS=(
"181.225.231.120:53"
"181.225.231.110:53"
"181.225.233.40:53"
"181.225.233.30:53"
)

detect_network() {
    iface=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}')
    [[ "$iface" == wlan* ]] && echo "WIFI" || echo "DATA"
}

install_slipstream() {
    clear
    pkg update -y && pkg upgrade -y && pkg install wget -y
    wget https://raw.githubusercontent.com/BoredBoy23/A-congelar-se-ha-dicho/main/setup.sh
    chmod +x setup.sh
    ./setup.sh
    read -p "ENTER para volver al menú"
}

clean_slipstream() {
    pkill -f slipstream-client 2>/dev/null
    sleep 1
}

# Manejo limpio de Ctrl + C
trap_ctrl_c() {
    echo
    echo "[!] Conexión interrumpida"
    clean_slipstream
    ACTIVE_DNS="No conectado"
    read -p "ENTER para volver al menú"
    return
}

wait_for_menu() {
    while true; do
        echo
        echo -n "> "
        read -r input </dev/tty

        # Ignorar vacío
        [[ -z "$input" ]] && continue

        cmd=$(echo "$input" | tr '[:upper:]' '[:lower:]')

        if [[ "$cmd" == "menu" ]]; then
            clean_slipstream
            ACTIVE_DNS="No conectado"
            return
        else
            echo "[X] Comando no reconocido. Use: menu"
        fi
    done
}

connect_auto() {
    local SERVERS=("$@")

    for SERVER in "${SERVERS[@]}"; do
        clean_slipstream
        > "$LOG_FILE"

        clear
        echo "[*] Probando servidor: $SERVER"
        echo

        trap trap_ctrl_c INT

        ./slipstream-client \
            --tcp-listen-port=5201 \
            --resolver="$SERVER" \
            --domain="$DOMAIN" \
            --keep-alive-interval=600 \
            --congestion-control=cubic \
            > >(tee -a "$LOG_FILE") 2>&1 &

        PID=$!

        # Espera máxima: 7 segundos
        for i in {1..7}; do
            if grep -q "Connection confirmed" "$LOG_FILE"; then
                ACTIVE_DNS="$SERVER"
                clear
                echo "[✓] CONEXIÓN CONFIRMADA"
                echo "[✓] DNS Activo: $ACTIVE_DNS"
                echo
                echo "Ctrl + C para desconectar"
                echo 'Escriba "menu" para volver al menú'
                echo

                wait_for_menu
                trap - INT
                return
            fi

            if grep -q "Connection closed" "$LOG_FILE"; then
                break
            fi
            sleep 1
        done

        trap - INT
        clean_slipstream
    done

    echo "[X] No se pudo conectar con ningún servidor"
    read -p "ENTER para volver al menú"
}

while true; do
    clear

    NET=$(detect_network)
    DATA_MARK="○"
    WIFI_MARK="○"
    [[ "$NET" == "DATA" ]] && DATA_MARK="●"
    [[ "$NET" == "WIFI" ]] && WIFI_MARK="●"

    echo "██╗   ██╗██╗██████╗ "
    echo "██║   ██║██║██╔══██╗"
    echo "██║   ██║██║██████╔╝"
    echo "╚██╗ ██╔╝██║██╔═══╝ "
    echo " ╚████╔╝ ██║██║     "
    echo "  ╚═══╝  ╚═╝╚═╝     "
    echo
    echo "DNS Activo: $ACTIVE_DNS"
    echo
    echo "$DATA_MARK 1) Conectar en Datos Móviles"
    echo "$WIFI_MARK 2) Conectar en WiFi"
    echo "  3) Instalar slipstream-client"
    echo "  0) Salir"
    echo
    read -p "Selecciona una opción: " opt

    case $opt in
        1) connect_auto "${DATA_SERVERS[@]}" ;;
        2) connect_auto "${WIFI_SERVERS[@]}" ;;
        3) install_slipstream ;;
        0) clear; exit ;;
    esac
done
