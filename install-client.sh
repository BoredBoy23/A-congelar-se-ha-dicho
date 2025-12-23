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
    wget https://raw.githubusercontent.com/BoredBoy23/A-congelar-se-ha-dicho/refs/heads/main/setup.sh && \
    chmod +x setup.sh && \
    ./setup.sh
    read -p "ENTER para volver"
}

clean_slipstream() {
    pkill -f slipstream-client 2>/dev/null
    sleep 1
}

wait_for_menu() {
    while true; do
        read -r input
        if [[ "$input" == "menu" ]]; then
            clean_slipstream
            ACTIVE_DNS="No conectado"
            return
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

        ./slipstream-client \
            --tcp-listen-port=5201 \
            --resolver="$SERVER" \
            --domain="$DOMAIN" \
            --keep-alive-interval=600 \
            --congestion-control=cubic \
            > >(tee -a "$LOG_FILE") 2>&1 &

        PID=$!

        for i in {1..15}; do
            if grep -q "Connection confirmed" "$LOG_FILE"; then
 			   ACTIVE_DNS="$SERVER"
 			   clear
			    echo "[✓] CONEXIÓN CONFIRMADA"
			    echo "[✓] DNS Activo: $ACTIVE_DNS"
			    echo
			    echo "Ctrl + C para desconectar"
			    echo 'Escriba "menu" para desconectar y volver al menú'
			    echo
				
			    wait_for_menu &
			    MENU_PID=$!
				
 			   wait $PID
 			   
 			   kill $MENU_PID 2>/dev/null
  			  ACTIVE_DNS="No conectado"
 			   return
			fi

            if grep -q "Connection closed" "$LOG_FILE"; then
                break
            fi
            sleep 1
        done

        clean_slipstream
    done

    echo "[X] No se pudo conectar con ningún servidor"
    read -p "ENTER para volver"
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
