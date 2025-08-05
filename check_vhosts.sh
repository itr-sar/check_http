#!/bin/bash

# Initialize score variable
total_score=0

# Function to check a single virtual host
check_virtualhost() {
    local domain=$1
    local domain_checked=false # Flag to ensure score is added only once per domain

    echo "Checking $domain..."

    # Try HTTPS first
    http_code_https=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://$domain" -L)
    if [ "$http_code_https" -eq 200 ]; then
        echo "  ✅ $domain is running (HTTPS - Status: $http_code_https)"
        total_score=$((total_score + 10))
        domain_checked=true
        return 0 # Success
    elif [ "$http_code_https" -eq 000 ]; then
        echo "  ❌ Could not connect to $domain via HTTPS (Connection Error)"
    else
        echo "  ⚠️ $domain (HTTPS - Status: $http_code_https)"
    fi

    # If HTTPS did not succeed, try HTTP
    if ! $domain_checked; then
        http_code_http=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://$domain" -L)
        if [ "$http_code_http" -eq 200 ]; then
            echo "  ✅ $domain is running (HTTP - Status: $http_code_http)"
            total_score=$((total_score + 25))
            domain_checked=true
            return 0 # Success
        elif [ "$http_code_http" -eq 000 ]; then
            echo "  ❌ Could not connect to $domain via HTTP (Connection Error)"
        else
            echo "  ⚠️ $domain (HTTP - Status: $http_code_http)"
        fi
    fi

    # If neither HTTPS nor HTTP returned 200, or connection error
    if ! $domain_checked; then
        return 1 # Failure
    fi
    return 0 # If either HTTPS or HTTP succeeded
}

# Main script execution
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <domain1> <domain2> <domain3> <domain4>"
    echo "Example: $0 example1.com example2.com example3.com example4.com"
    exit 1
fi

domains=("$1" "$2" "$3" "$4")
overall_success=true

echo -e "\n--- Virtual Host Validation Report ---"
for domain in "${domains[@]}"; do
    if ! check_virtualhost "$domain"; then
        overall_success=false
    fi
done
echo "--------------------------------------\n"

if $overall_success; then
    echo "All 4 virtual hosts appear to be running successfully!"
else
    echo "Some virtual hosts may not be running or are inaccessible. Please check the report above."
    exit_code=1 # Set exit code to 1 if not all are successful
fi

echo "Total Score: $total_score"

# Exit with appropriate code
exit $exit_code
