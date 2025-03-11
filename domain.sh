#!/bin/bash

# Check if URL is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <URL>"
    exit 1
fi

# Extract the domain from the URL
URL="$1"
DOMAIN=$(echo $URL | awk -F/ '{print $3}')

# Run nmap with http-methods script
echo "========================================"
echo " Starting HTTP Methods Scan with Nmap  "
echo "========================================"
echo "Target Domain: $DOMAIN"
echo "----------------------------------------"

echo "Scanning $DOMAIN for allowed HTTP methods..."
nmap -p 80,443 --script http-methods $DOMAIN -oN nmap_results.txt

echo "----------------------------------------"
echo "Scan complete. Extracting allowed HTTP methods..."
echo "----------------------------------------"

METHODS=$(grep "|   " nmap_results.txt | awk '{print $2}' | jq -R . | jq -s .)

echo "{\"domain\": \"$DOMAIN\", \"allowed_methods\": $METHODS}" > nmap_results.json

echo "----------------------------------------"
echo "✅ Scan results successfully saved!"
echo "📄 JSON Output: nmap_results.json"
echo "----------------------------------------"
echo "Scan Summary:"
echo "Target: $DOMAIN"
echo "Allowed HTTP Methods: $(echo $METHODS | jq -r '. | join(", ")')"
echo "----------------------------------------"
