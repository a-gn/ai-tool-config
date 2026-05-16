#!/bin/sh
# Claude Code status line script
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

five_hour=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_day=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

# Model name
printf "%s" "$model"

# Context window: used% (used_k/total_k)
if [ -n "$used_pct" ] && [ -n "$ctx_size" ]; then
    used_k=$(echo "$used_pct $ctx_size" | awk '{printf "%.0f", ($1/100 * $2) / 1000}')
    ctx_k=$(echo "$ctx_size" | awk '{printf "%.0f", $1/1000}')
    printf " | context: %.0f%% (%sk/%sk)" "$used_pct" "$used_k" "$ctx_k"
elif [ -n "$ctx_size" ]; then
    ctx_k=$(echo "$ctx_size" | awk '{printf "%.0f", $1/1000}')
    printf " | context: %sk" "$ctx_k"
fi

# 5-hour rate limit
if [ -n "$five_hour" ]; then
    printf " | 5h: %.0f%%" "$five_hour"
fi

# 7-day rate limit
if [ -n "$seven_day" ]; then
    printf " | 7d: %.0f%%" "$seven_day"
fi

printf "\n"
