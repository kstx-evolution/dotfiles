#!/bin/sh

# Copied and modified from https://gist.github.com/mortie/e725d37a71779b18e8eaaf4f8a02bf5b
# Updated to hardcode screen and stylus details, (let's be honest, they won't change).

# I have this script set to autostart in my i3 config

# Automatically rotate the screen when the device's orientation changes.
# Use 'xrandr' to get the correct display for the first argument (for example, "eDP-1"),
# and 'xinput' to get the correct input element for your touch screen, if applicable
# (for example,  "Wacom HID 486A Finger").
#
# The script depends on the monitor-sensor program from the iio-sensor-proxy package.

# Use xrandr to verify this is your tablet monitor
MONITOR=eDP1

# Configure these to match your hardware (names taken from `xinput` output).
TOUCHPAD='SYNA2B31:00 06CB:7F8B Touchpad'
TOUCHSCREENp='Wacom HID 5110 Pen'
TOUCHSCREENe='Wacom HID 5110 Pen'
TOUCHSCREENf='Wacom HID 5110 Finger'

listen() {
	onboard_pid=

	while read -r line; do
		line="${line#??}"
		show_keyboard=1
		if [ "$line" = "normal" ]; then
			rotate=normal
			matrix="0 0 0 0 0 0 0 0 0"
			show_keyboard=0
 		elif [ "$line" = "left-up" ]; then
			rotate=left
			matrix="0 -1 1 1 0 0 0 0 1"
		elif [ "$line" = "right-up" ]; then
			rotate=right
			matrix="0 1 0 -1 0 1 0 0 1"
		elif [ "$line" = "bottom-up" ]; then
			rotate=inverted
			matrix="-1 0 1 0 -1 1 0 0 1"
		else
			echo "Unknown rotation: $line"
			continue
		fi

		echo $rotate
		xrandr --output "$MONITOR" --rotate "$rotate"
		xinput set-prop "$TOUCHSCREENp" --type=float "Coordinate Transformation Matrix" $matrix
		xinput set-prop "$TOUCHSCREENe" --type=float "Coordinate Transformation Matrix" $matrix
		xinput set-prop "$TOUCHSCREENf" --type=float "Coordinate Transformation Matrix" $matrix

		if [ "$show_keyboard" = 1 ] && [ -z "$onboard_pid" ]; then
			onboard &
			onboard_pid=$!
		elif [ "$show_keyboard" = 0 ] && ! [ -z "$onboard_pid" ]; then
			kill "$onboard_pid"
			onboard_pid=
		fi
	done
}

monitor-sensor \
	| grep --line-buffered "Accelerometer orientation changed" \
	| grep --line-buffered -o ": .*" | listen
