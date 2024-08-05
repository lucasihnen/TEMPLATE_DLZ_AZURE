# colors.sh

# Define the echo_color function
echo_color() {
    local message=$1
    local color=$2

    # Define a map of color names to ANSI color codes
    declare -A colors
    colors=(
        ["black"]="30"
        ["red"]="31"
        ["green"]="32"
        ["yellow"]="33"
        ["blue"]="34"
        ["magenta"]="35"
        ["cyan"]="36"
        ["white"]="37"
        ["bold_red"]="1;31"
        ["bold_green"]="1;32"
        ["bold_yellow"]="1;33"
        ["bold_blue"]="1;34"
        ["bold_magenta"]="1;35"
        ["bold_cyan"]="1;36"
        ["bold_white"]="1;37"
        # Add more as needed
    )

    # Get the color code from the map
    local color_code=${colors[$color]}

    # If the color is not found, default to white
    if [ -z "$color_code" ]; then
        color_code="37"
    fi

    # Print the message in the specified color
    echo -e "\e[${color_code}m${message}\e[0m"
}
