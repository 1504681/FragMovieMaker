#!/bin/bash
# Local script to test video processing before committing to GitHub

# Check if FFmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
    echo "Error: FFmpeg is not installed. Please install it first."
    exit 1
fi

# Create output directory
mkdir -p output

# Create a list of video files in chronological order by creation time
echo "Creating list of video files in chronological order..."
find ./videos -type f -name "*.mp4" -printf "%T@ %p\n" | sort -n | cut -f2- -d" " | sed 's/^/file /' > video_list.txt

# Display the list of videos to be processed
echo "Videos to be processed:"
cat video_list.txt

# Check if any videos were found
if [ ! -s video_list.txt ]; then
    echo "Error: No MP4 files found in the videos directory."
    exit 1
fi

# Check if background music exists
if [ ! -f ./music/background.mp3 ]; then
    echo "Error: Background music file not found at ./music/background.mp3"
    exit 1
fi

# Concatenate videos
echo "Concatenating videos..."
ffmpeg -f concat -safe 0 -i video_list.txt -c copy output/concatenated.mkv

# Check if concatenation was successful
if [ $? -ne 0 ]; then
    echo "Error: Video concatenation failed."
    exit 1
fi

# Check for background music
if [ ! -f ./music/background.mp3 ]; then
    echo "Warning: background.mp3 not found, looking for alternatives..."
    MUSIC_FILE=$(find ./music -name "*.mp3" | head -n 1)
    if [ -z "$MUSIC_FILE" ]; then
        echo "Error: No music file found."
        exit 1
    fi
    echo "Using $MUSIC_FILE as background music"
else
    MUSIC_FILE="./music/background.mp3"
fi

# Add music
echo "Adding background music..."
ffmpeg -i output/concatenated.mkv -i "$MUSIC_FILE" -map 0:v -map 1:a -c:v copy -shortest output/final_video.mp4

# Check if adding music was successful
if [ $? -ne 0 ]; then
    echo "Error: Adding background music failed."
    exit 1
fi

echo "Success! Final video created at output/final_video.mp4"
echo "Video duration: $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 output/final_video.mp4) seconds"
echo "Video resolution: $(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 output/final_video.mp4)"

# Optional: Play the video if a player is available
if command -v vlc &> /dev/null; then
    echo "Opening video with VLC..."
    vlc output/final_video.mp4 &
elif command -v ffplay &> /dev/null; then
    echo "Opening video with FFplay..."
    ffplay output/final_video.mp4
else
    echo "Video player not found. Please open output/final_video.mp4 manually to view the result."
fi