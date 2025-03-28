#!/usr/bin/env bash

# Rosé Pine color palette
BASE=#191724
SURFACE=#1f1d2e
OVERLAY=#26233a

MUTED=#6e6a86
SUBTLE=#908caa
TEXT=#e0def4

LOVE=#eb6f92
GOLD=#f6c177
ROSE=#ebbcba
PINE=#31748f
FOAM=#9ccfd8
IRIS=#c4a7e7

HIGHLIGHT_LOW=#21202e
HIGHLIGHT_MED=#403d52
HIGHLIGHT_HIGH=#524f67

# Function to get CPU usage
get_cpu_usage() {
    cpu_usage=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print int(($2+$4-u1) * 100 / (t-t1)); }' \
    <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))
    
    echo "^c$FOAM^CPU: $cpu_usage%"
}

# Function to get memory usage
get_memory_usage() {
    # Extract used and total memory in kilobytes
    mem_info=$(free -k | awk '/^Mem:/ {print $3, $2}')
    used_mem=$(echo $mem_info | awk '{print $1}')
    total_mem=$(echo $mem_info | awk '{print $2}')

    # Calculate memory usage percentage
    mem_percent=$(awk "BEGIN {printf \"%.0f%%\", ($used_mem / $total_mem) * 100}")

    # Output the result with color
    echo "^c$IRIS^MEM: $mem_percent"
}

# Function to get volume level
get_volume() {
    # Get the default sink (output device) and its volume/mute status
    default_sink=$(pactl get-default-sink)
    volume=$(pactl get-sink-volume $default_sink | grep -o '[0-9]*%' | head -1)
    is_muted=$(pactl get-sink-mute $default_sink | grep -o 'yes\|no')

    # Replace "yes" with "MUT" and "no" with the volume level
    if [ "$is_muted" = "yes" ]; then
        volume="MUT"
    fi

    # Get the default source (input device) and its volume/mute status
    default_source=$(pactl get-default-source)
    mic_level=$(pactl get-source-volume $default_source | grep -o '[0-9]*%' | head -1)
    is_mic_muted=$(pactl get-source-mute $default_source | grep -o 'yes\|no')

    # Replace "yes" with "MUT" and "no" with the microphone level
    if [ "$is_mic_muted" = "yes" ]; then
        mic_level="MUT"
    fi

    # Output the results with colors
    echo "^c$PINE^VOL: $volume MIC: $mic_level"
}

# Function to get brightness percentage
get_brightness() {
    # Get the current brightness level (adjust path if needed)
    brightness=$(cat /sys/class/backlight/intel_backlight/brightness)
    max_brightness=$(cat /sys/class/backlight/intel_backlight/max_brightness)
    
    # Calculate brightness percentage
    brightness_percent=$(awk "BEGIN {printf \"%.0f%%\", ($brightness / $max_brightness) * 100}")
    
    # Output the result with color
    echo "^c$ROSE^BRT: $brightness_percent"
}

# Function to get weighted average battery level
get_battery_level() {
    # Get battery levels (adjust paths if needed)
    battery0_level=$(cat /sys/class/power_supply/BAT0/capacity)
    battery1_level=$(cat /sys/class/power_supply/BAT1/capacity)

    battery0_energy_full=$(cat /sys/class/power_supply/BAT0/energy_full)
    battery1_energy_full=$(cat /sys/class/power_supply/BAT1/energy_full)
    
    # Calculate weights based on energy capacity 
    weight0=$(awk "BEGIN {printf \"%.2f\", $battery0_energy_full / ($battery0_energy_full + $battery1_energy_full)}")
    weight1=$(awk "BEGIN {printf \"%.2f\", $battery1_energy_full / ($battery0_energy_full + $battery1_energy_full)}")
    
    # Calculate weighted average
    weighted_avg=$(awk "BEGIN {printf \"%.0f%%\", ($battery0_level * $weight0 + $battery1_level * $weight1)}")
    
    # Output the result with color
    echo "^c$LOVE^BAT: $weighted_avg"
}

# Function to get date and time in American 12-hour format
get_datetime() {
    datetime=$(date +"%a %d %b %I:%M %p")
    echo "^c$GOLD^$datetime"
}

# Function to detect if the system is a laptop
is_laptop() {
    # Check if battery and brightness files exist
    if [ -d /sys/class/power_supply/BAT0 ] && [ -d /sys/class/backlight/intel_backlight ]; then
        return 0  # Laptop
    else
        return 1  # PC
    fi
}

# Main loop to update xsetroot
while true; do
    # Combine all status components
    if is_laptop; then
        # Include battery and brightness for laptops
        status="$(get_volume) ^c$TEXT^| $(get_cpu_usage) ^c$TEXT^| $(get_memory_usage) ^c$TEXT^| $(get_brightness) ^c$TEXT^| $(get_battery_level) ^c$TEXT^| $(get_datetime)"
    else
        # Exclude battery and brightness for PCs
        status="$(get_volume) ^c$TEXT^| $(get_cpu_usage) ^c$TEXT^| $(get_memory_usage) ^c$TEXT^| $(get_datetime)"
    fi

    # Update the root window name with a darker background
    xsetroot -name "$status"

    # Sleep for 250 milis before updating
    sleep 0.25
done
