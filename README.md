# Nmap enumeration script for CTF and pentest labs.

Automates common nmap scans with multiple modes:
- **quick**: all ports (TCP)
        ```
    nmap -p- -T4 --min-rate 1000 <IP>
        ```
- **standard**: all ports + service scan
        ```
    nmap -p <OPEN_PORTS> -sC -sV -T4 <IP>
        ```
- **udp**: UDP top 100
        ```
    sudo nmap -sU --top-ports 100 -T4 <IP>
        ```
- **full**: everything

- **webfuzz**: gobuster if specific webports are open

Usage:
```bash
./ezenum.sh <IP>
```
feedback is welcome!
