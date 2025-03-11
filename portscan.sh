#!/bin/bash

# Check if IP address is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <IP-Address>"
    exit 1
fi

IP="$1"

# Display start message
echo "========================================"
echo "  Starting Full Nmap Scan (No Ping)   "
echo "========================================"
echo "Target IP: $IP"
echo "----------------------------------------"

# Run nmap full scan without ping
echo "Scanning $IP for open ports and services..."
nmap -Pn -p- -sV -oN nmap_full_scan.txt $IP

echo "----------------------------------------"
echo "✅ Full scan completed successfully!"
echo "📄 Results saved in: nmap_full_scan.txt"
echo "----------------------------------------"
