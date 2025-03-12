#!/bin/bash

# Define the input file with IP addresses
IP_FILE="ip_list.txt"

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "Error: nmap is not installed. Please install it and try again."
    exit 1
fi

# Print the table header
printf "%-15s %-10s %-10s %-10s %-10s\n" "IPADDRESS" "SSH" "RDP" "HTTP" "HTTPS"
echo "---------------------------------------------------------------"

# Loop through each IP address in the file
while read -r IP; do
    if [[ -z "$IP" ]]; then
        continue
    fi

    # Run nmap scan for the required ports
    OUTPUT=$(nmap -p 22,3389,80,443 --open --reason "$IP" 2>/dev/null)

    # Check port statuses
    SSH_STATUS=$(echo "$OUTPUT" | grep "22/tcp" | awk '{print ($2=="open"?"Open":($2=="filtered"?"Filtered":"Closed"))}')
    RDP_STATUS=$(echo "$OUTPUT" | grep "3389/tcp" | awk '{print ($2=="open"?"Open":($2=="filtered"?"Filtered":"Closed"))}')
    HTTP_STATUS=$(echo "$OUTPUT" | grep "80/tcp" | awk '{print ($2=="open"?"Open":($2=="filtered"?"Filtered":"Closed"))}')
    HTTPS_STATUS=$(echo "$OUTPUT" | grep "443/tcp" | awk '{print ($2=="open"?"Open":($2=="filtered"?"Filtered":"Closed"))}')

    # Set default values if empty
    SSH_STATUS=${SSH_STATUS:-"Closed"}
    RDP_STATUS=${RDP_STATUS:-"Closed"}
    HTTP_STATUS=${HTTP_STATUS:-"Closed"}
    HTTPS_STATUS=${HTTPS_STATUS:-"Closed"}

    # Print formatted output
    printf "%-15s %-10s %-10s %-10s %-10s\n" "$IP" "$SSH_STATUS" "$RDP_STATUS" "$HTTP_STATUS" "$HTTPS_STATUS"

done < "$IP_FILE"
