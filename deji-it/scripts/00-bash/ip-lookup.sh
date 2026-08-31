#!/bin/bash
# ip-lookup.sh — look up one or more public IPs and save clean results to markdown

strip_ansi() {
    sed \
        -e 's/\x1b\[[0-9;]*[mGKHF]//g' \
        -e 's/\x1b\[[?][0-9;]*[hlJ]//g' \
        -e 's/\x1b([AB]//g' \
        -e 's/\x0f//g' \
        -e 's/\r//g' \
        -e '/^[[:space:]]*$/d'
}

format_section() {
    local input="$1"
    local output=""
    local in_trace=0
    local in_aspath=0

    while IFS= read -r line; do

        # --- Section: Traceroute ---
        if echo "$line" | grep -q "Trace to"; then
            in_trace=1
            in_aspath=0
            output+=$'\n'"### Traceroute"$'\n'
            continue
        fi

        # --- Section: AS Path ---
        if echo "$line" | grep -q "AS path to"; then
            in_trace=0
            in_aspath=1
            output+=$'\n'"### AS Path"$'\n'
            output+='```'$'\n'
            continue
        fi

        # --- Section: ASN Info box header ---
        if echo "$line" | grep -q "ASN lookup for"; then
            output+="### ASN Info"$'\n'
            continue
        fi

        # --- Traceroute: render as markdown table ---
        if [ "$in_trace" -eq 1 ]; then
            if echo "$line" | grep -q "Hop IP Address"; then
                output+="| Hop | IP Address | Loss% | Ping avg | AS Info |"$'\n'
                output+="|-----|------------|-------|----------|---------|"$'\n'
                continue
            fi
            if echo "$line" | grep -qP "^\s+\d+\."; then
                local hop ip_part loss ping as_info
                hop=$(echo "$line"     | grep -oP '^\s+\K\d+(?=\.)')
                ip_part=$(echo "$line" | grep -oP '\d+\.\s+\K\S[^(]*(\([^)]+\))?' | head -1 | sed 's/[[:space:]]*$//')
                loss=$(echo "$line"    | grep -oP '\d+%')
                ping=$(echo "$line"    | grep -oP '\d+\.\d+ ms')
                as_info=$(echo "$line" | grep -oP '(?<=ms)\s+\K\S.*$')
                output+="| $hop | $ip_part | $loss | $ping | $as_info |"$'\n'
                continue
            fi
            if echo "$line" | grep -q "Trace completed"; then
                local timestamp
                timestamp=$(echo "$line" | grep -oP '\d{4}-\d{2}-\d{2}.*')
                output+=$'\n'"_Trace completed: $timestamp_"$'\n'
                in_trace=0
                continue
            fi
            continue
        fi

        # --- AS Path: wrap in code block ---
        if [ "$in_aspath" -eq 1 ]; then
            if echo "$line" | grep -qP '^-{3,}$'; then
                output+='```'$'\n'
                in_aspath=0
            else
                output+="$line"$'\n'
            fi
            continue
        fi

        # --- ASN info: convert tree lines to bullet list ---
        if echo "$line" | grep -qP '[┌├└]'; then
            local clean key val
            clean=$(echo "$line" | sed 's/.*[┌├└]//' | sed 's/^\s*//')
            key=$(echo "$clean" | awk '{print $1}')
            val=$(echo "$clean" | cut -d' ' -f2-)
            output+="- **$key** $val"$'\n'
            continue
        fi

        # --- Box drawing borders: skip ---
        if echo "$line" | grep -qP '[╭╰│]'; then
            continue
        fi

        output+="$line"$'\n'

    done <<< "$input"

    # Close unclosed AS path block if file ends mid-section
    if [ "$in_aspath" -eq 1 ]; then
        output+='```'$'\n'
    fi

    echo "$output"
}

# --- Entry point ---

if [ $# -eq 0 ]; then
    echo "Usage: ip-lookup.sh <IP1> <IP2> ..."
    echo "Example: ip-lookup.sh 8.8.8.8 1.1.1.1"
    exit 1
fi

# Build filename from IPs joined by underscores
IP_JOINED=$(IFS='_'; echo "$*")
OUTPUT="ip_report_${IP_JOINED}.md"
TOTAL=$#
COUNT=0

{
    echo "# IP Lookup Report"
    echo "_Generated: $(date)_"
    echo ""
    echo "---"
    echo ""

    for IP in "$@"; do
        COUNT=$((COUNT + 1))
        echo "[${COUNT}/${TOTAL}] Looking up ${IP}..." >&2

        echo "## $IP"
        echo ""

        RAW=$(asn "$IP" 2>/dev/null | strip_ansi)
        format_section "$RAW"

        echo ""
        echo "---"
        echo ""

        echo "[${COUNT}/${TOTAL}] Done: ${IP}" >&2
    done

} > "$OUTPUT"

echo ""
echo "Report saved to: $OUTPUT"
