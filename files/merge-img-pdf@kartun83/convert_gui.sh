#!/bin/bash

get_settings() {
    yad --form \
        --title="PDF Merger (ImageMagick)" \
        --field="Output Filename" "output.pdf" \
        --field="Page Size:CB" "A4!Letter!Legal!A5" \
        --field="Quality (1-100):NUM" "90!1..100!1!" \
        --field="Density (DPI):NUM" "300!72..600!1!"
}

main() {
    IFS='|' read -r outfile pagesize quality density <<< "$(get_settings)"
    [ -z "$outfile" ] && exit 0
    
    # Get the directory of the first input file
    input_dir=$(dirname "$1")
    outfile="${outfile%.pdf}.pdf"
    outfile="$input_dir/$outfile"
    
    convert "$@" \
        -density "$density" \
        -quality "$quality" \
        -page "$pagesize" \
        "$outfile"
    
    xdg-open "$outfile"
}

main "$@"
