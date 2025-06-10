#!/bin/bash

# Configuration - Set IMG2PDF_NEMO_LOGGING to "1" to activate logging
IMG2PDF_NEMO_LOGGING="1"
LOG_FILE="$HOME/nemo_img2pdf.log"

# Get output directory from first selected file
output_dir=$(dirname "$1")
output="$output_dir/converted.pdf"

# Logging function
log() {
    if [ "$IMG2PDF_NEMO_LOGGING" = "1" ]; then
        echo "$1" >> "$LOG_FILE"
    fi
}

# Execute command with full logging
run_command() {
    local cmd=("$@")
    
    # Log the exact command being executed
    if [ "$IMG2PDF_NEMO_LOGGING" = "1" ]; then
        printf "Executing: " >> "$LOG_FILE"
        printf "%q " "${cmd[@]}" >> "$LOG_FILE"
        echo >> "$LOG_FILE"
    fi

    # Execute with appropriate output handling
    if [ "$IMG2PDF_NEMO_LOGGING" = "1" ]; then
        "${cmd[@]}" >> "$LOG_FILE" 2>&1
    else
        "${cmd[@]}" >/dev/null 2>&1
    fi
    return $?
}

# Main execution
main() {
    [ "$IMG2PDF_NEMO_LOGGING" = "1" ] && echo "===== $(date) =====" >> "$LOG_FILE"
    log "Selected files: $*"
    log "Output path: $output"

    log "Starting conversion..."
    run_command img2pdf "$@" -o "$output" --rotation=ifvalid
    exit_code=$?

    if [ $exit_code -eq 0 ]; then
        log "Conversion successful"
        xdg-open "$output"
    else
        log "Error: Conversion failed (exit code $exit_code)"
        log "Last 5 lines of output:"
        tail -n 5 "$LOG_FILE" >> "$LOG_FILE"
    fi
    [ "$IMG2PDF_NEMO_LOGGING" = "1" ] && echo "===== Finished =====" >> "$LOG_FILE"
}

main "$@"
