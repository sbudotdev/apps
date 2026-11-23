#!/bin/sh
# Renders the reel in both formats from input/seasons.mp4 (the screen recording, not in git).
#   renders/seasons-reel-9x16.mp4  1080x1920, Instagram Reel
#   renders/seasons-reel-4x5.mp4   1080x1350, LinkedIn: the centre band of the same render
# Needs Node (npx hyperframes) and ffmpeg. Run from anywhere: sh marketing/social/instagram/seasons-reel/render.sh
set -eu
cd "$(dirname "$0")"
[ -f input/seasons.mp4 ] || { echo "Missing input/seasons.mp4: put the screen recording there." >&2; exit 1; }
mkdir -p renders
npx hyperframes render . -o renders/seasons-reel-9x16.mp4
ffmpeg -loglevel error -y -i renders/seasons-reel-9x16.mp4 -vf "crop=1080:1350:0:285" -c:v libx264 -crf 18 -pix_fmt yuv420p -an renders/seasons-reel-4x5.mp4
for f in renders/seasons-reel-9x16.mp4 renders/seasons-reel-4x5.mp4; do
  printf '%s ' "$f"; ffprobe -v error -select_streams v:0 -show_entries stream=width,height:format=duration -of csv=p=0:s=x "$f" | tr '\n' ' '; echo
done
