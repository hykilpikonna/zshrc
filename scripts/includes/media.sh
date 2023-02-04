# Cut videos - cut <file name> <end time> [start time (default 00:00:00)]
cutv() {
    if [ "$#" -lt 2 ]; then
        echo "Usage: cut <file name> <end time (hh:mm:ss)> [start time (00:00:00)]"
        return 2
    fi

    local start="${3:-00:00:00}"
    echo "$1"
    echo "$2"
    echo "$start"
    ffmpeg -i "$1" -codec copy -ss "$start" -t "$2" Cut\ "$1"
}
alias vcomp="$BASEDIR/scripts/bin/video.py"
alias vcompy="ipython -i $BASEDIR/scripts/bin/video.py"

flac2mp3() {
    for file in *.flac; do 
        ffmpeg -i "$file" -ab 320k -map_metadata 0 -id3v2_version 3 "${file%.flac}.mp3"
    done
}