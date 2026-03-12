#!/bin/bash

# CTF Enumeration Script
# Usage: ./enum.sh <IP>

# define variable to first script argument
IP=$1

# If no string given (-z -> is sting empty?)
if [ -z "$IP" ]; then
	echo "Usage: ./enum.sh <IP>"
	exit 1
fi

# Output Folder
OUTDIR="$HOME/.local/share/ezenum/enum_$IP"
mkdir -p "$OUTDIR"
echo "Output saved in: $OUTDIR"

phase1() {
    # First nmap scan (phase 1 all ports)
    echo ""
    echo "[*] Phase 1: Scan all ports..."
    nmap -p- -T4 --min-rate 1000 -oN "$OUTDIR/phase1_allports.txt" "$IP" > /dev/null 2>&1
    echo "[*] Phase 1: finished!"

    # Extract open ports from phase1 output
    # grep port lines -> filter open -> cut port number -> join with comma -> remove last comma
    OPEN_PORTS=$(grep "^[0-9]" "$OUTDIR/phase1_allports.txt" | grep "open" | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')
    if [ -z "$OPEN_PORTS" ]; then
        echo "[-] No open ports found!"
        exit 1
    fi
    echo "[+] Open ports: $OPEN_PORTS"
}

phase2() {
    # Second nmap scan (phase 2 service scan on open ports)
    echo ""
    echo "[*] Phase 2: Sevice Scan on Ports $OPEN_PORTS..."
    nmap -p "$OPEN_PORTS" -sC -sV -T4 -oN "$OUTDIR/phase2_services.txt" "$IP" > /dev/null 2>&1
    echo "[*] Phase 2: finished!"
    echo "[+] Services found:"
    grep "^[0-9]" "$OUTDIR/phase2_services.txt"
    echo "[+] Results saved in: $OUTDIR/phase2_services.txt"
}

phase3() {
    # UDP Scan (phase 3 udp)
    echo ""
    echo "[*] Phase 3: UDP Scan (Top 100 Ports)..."
    sudo nmap -sU --top-ports 100 -T4 -oN "$OUTDIR/phase3_udp.txt" "$IP" > /dev/null 2>&1
    echo "[*] Phase 3: finished!"
    UDP_PORTS=$(grep "^[0-9]" "$OUTDIR/phase3_udp.txt" | grep "open")
    if [ -z "$UDP_PORTS" ]; then
	echo "[-] No open UDP ports found!"
    else
	echo "[+] Open ports: $UDP_PORTS"
    fi
}


webfuzz() {
    # gobuster scan
    if echo "$OPEN_PORTS" | grep -qE "80|443|8080|8000|8443|8008"; then
        if echo "$OPEN_PORTS" | grep -qE "443|8443"; then
            PROTO="https"
	else
            PROTO="http"
	fi
        gobuster dir -u "$PROTO://$IP" -w /usr/share/wordlists/dirb/common.txt -o "$OUTDIR/webfuzz.txt" > /dev/null 2>&1
    fi
    echo "[*] Gobuster Scan finished"
    cat "$OUTDIR/webfuzz.txt" # could be filtered later on if needed
}



# Get Mode
echo ""
echo "Which Mode?"
echo "  [1] quick    - only Phase 1 (get all open ports tcp)"
echo "  [2] standard - Phase 1 + 2 (scan open ports and do service scan on them)"
echo "  [3] udp      - only Phase 3 (udp)"
echo "  [4] Full     - Full (Every Phase and webfuzz) "
echo "  [5] webfuzz  - gobuster "
echo ""

read -p "Choose (1-4) [default:2] : " MODE
MODE=${MODE:-2} # if empty choose 2

if [ "$MODE" == "1" ]; then
    echo "[+] Mode: quick"
    phase1
elif [ "$MODE" == "2" ]; then
    echo "[+] Mode: standard"
    phase1
    phase2
    if echo "$OPEN_PORTS" | grep -qE "80|443|8080|8000|8443|8008"; then
        read -p "A Webport is Open, do you want to run gobuster? [y/N] : " webfuzzanswer
        webfuzzanswer=${webfuzzanswer:-n}
	    if [[ "$webfuzzanswer" == "y" || "$webfuzzanswer" == "Y" ]]; then
	    webfuzz
	    else
	    echo "[-] Skipping gobuster!"
        fi
	fi
elif [ "$MODE" == "3" ]; then
    echo "[+] Mode: udp"
    phase3
elif [ "$MODE" == "4" ]; then
    echo "[+] Mode: full"
    phase1
    phase2
    phase3
    webfuzz
elif [ "$MODE" == "5" ]; then
    echo "[+] Mode: webfuzz"
    webfuzz
else
    echo "[-] Error!"
    exit 1
fi


