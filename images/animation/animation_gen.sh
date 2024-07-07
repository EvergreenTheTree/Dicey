#!/usr/bin/env bash

# Extremely sketchy animation script.
# usage: animation_gen.sh input.svg output.gif [width] [height]

svg_frame() {
	sed -E "s/stroke-dashoffset:.*?;/stroke-dashoffset:$(printf "%f" "$2");/" "$1"
}

input_fn="$1"
output_fn="$2"
width="${3:-1024}"
height="${4:-1024}"
dash_offset=0
max_offset="11.1"
nframes=60
for ((n = 0; n < nframes; n++)); do
	dash_offset=$(echo "scale=7; ($n / $nframes) * $max_offset" | bc)
	echo "$n: $dash_offset"
	svg_frame "$input_fn" "$dash_offset" | inkscape --pipe --export-area-page --export-width="$width" --export-height="$height" -o "$(printf "frame_%05d.png" "$n")"
done

magick convert -layers OptimizePlus -delay 2 frame_*.png -loop 0 "$output_fn"

rm -f frame_*.png
