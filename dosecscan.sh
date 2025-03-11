#!/bin/bash

# Ensure required tools are installed
command -v nmap >/dev/null 2>&1 || { echo "nmap is required but not installed. Install it first."; exit 1; }
command -v dig >/dev/null 2>&1 || { echo "dig is required but not installed. Install it first."; exit 1; }
command -v host >/dev/null 2>&1 || { echo "host is required but not installed. Install it first."; exit 1; }
command -v curl >/dev/null 2>&1 || { echo "curl is required but not installed. Install it first."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed. Install it first."; exit 1; }

# Create log directory
LOG_DIR="logs"
mkdir -p "$LOG_DIR"

# Function to log results to JSON and print to console
log_result() {
    local filename="$1"
    local content="$2"

    # Save to JSON file
    echo "$content" | jq '.' > "$LOG_DIR/$filename.json"

    # Print JSON output to console for Azure DevOps pipeline visibility
    echo "----------------------------------------"
    echo "LOG OUTPUT (JSON Format)"
    echo "----------------------------------------"
    echo "$content" | jq '.'
    echo "----------------------------------------"

    echo "Results saved in $LOG_DIR/$filename.json"
}

# Function to resolve all possible IP addresses for a domain
resolve_domain() {
    local domain="$1"
    local log_file="domain_${domain}_$(date +%s)"
    
    echo "Resolving domain: $domain"

    local resolved_ips=$(dig +short "$domain")
    local cname=$(dig +short CNAME "$domain")
    local host_ips=$(host "$domain" | awk '/has address/ {print $4}')

    local json_output=$(jq -n --arg domain "$domain" \
        --argjson resolved_ips "$(jq -R . <<< "$resolved_ips" | jq -s .)" \
        --argjson host_ips "$(jq -R . <<< "$host_ips" | jq -s .)" \
        --arg cname "$cname" \
        '{domain: $domain, resolved_ips: $resolved_ips, host_ips: $host_ips, cname: $cname}')
    
    log_result "$log_file" "$json_output"
}

# Function to perform an Nmap port scan
scan_ip() {
    local ip="$1"
    local log_file="ip_scan_${ip}_$(date +%s)"

    echo "Scanning IP: $ip for common ports"

    local ports="22,3389,80,443,1433,3306,5432" # SSH, RDP, HTTP, HTTPS, MSSQL, MySQL, PostgreSQL
    local scan_result=$(nmap -Pn -p $ports "$ip" -oG -)

    local json_output=$(jq -n --arg ip "$ip" --arg scan_result "$scan_result" '{ip: $ip, scan_result: $scan_result}')

    log_result "$log_file" "$json_output"
}

# Function to perform an Nmap HTTP methods test and content check
scan_url() {
    local url="$1"
    local log_file="url_scan_${url}_$(date +%s)"

    echo "Performing HTTP methods scan for URL: $url"

    # Nmap HTTP methods scan
    local scan_result=$(nmap --script=http-methods "$url" -p 80,443 -oG -)

    echo "Fetching HTTP response content from: $url"
    local response_body=$(curl -s -L "$url")

    # Check for "forbidden" in the response body (case-insensitive)
    local forbidden_detected="false"
    if echo "$response_body" | grep -iq "forbidden"; then
        forbidden_detected="true"
        echo "##vso[task.logissue type=warning] Forbidden content detected on $url"
    fi

    # Create JSON output
    local json_output=$(jq -n --arg url "$url" \
        --arg scan_result "$scan_result" \
        --arg forbidden_detected "$forbidden_detected" \
        '{url: $url, scan_result: $scan_result, forbidden_detected: $forbidden_detected}')
    
    log_result "$log_file" "$json_output"
}

# Argument parsing
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 -domain <domain> | -ip <IP> | -url <URL>"
    exit 1
fi

case "$1" in
    -domain) resolve_domain "$2" ;;
    -ip) scan_ip "$2" ;;
    -url) scan_url "$2" ;;
    *) echo "Invalid option. Use -domain, -ip, or -url."; exit 1 ;;
esac
