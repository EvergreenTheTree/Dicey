#!/usr/bin/env bash

svg_frame() {
	sed "s/stroke-dashoffset:0/stroke-dashoffset:$(printf "%f" "$2")/" "$1"
}

filename="$1"
width=1024
height=1024
dash_offset=0
max_offset="11.1"
nframes=60
for ((n = 0; n < nframes; n++)); do
	dash_offset=$(echo "scale=7; ($n / $nframes) * $max_offset" | bc)
	echo "$n: $dash_offset"
	svg_frame "$filename" "$dash_offset" | inkscape --pipe --export-area-page --export-width="$width" --export-height="$height" -o "$(printf "frame_%05d.png" "$n")"
done
