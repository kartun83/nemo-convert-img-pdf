#!/bin/bash

# Enhanced Configuration
CONFIG_FILE="$HOME/.config/nemo_img2pdf.conf"
LOG_FILE="$HOME/nemo_img2pdf.log"
LOGGING_ENABLED="${LOGGING_ENABLED:-false}"

set +H  # Disable ! history expansion

TEMP_DIR=$(mktemp -d)
# Only set up logging if enabled
if [ "$LOGGING_ENABLED" = "true" ]; then
    exec 3>>"$LOG_FILE"  # Dedicated file descriptor for logging
else
    exec 3>/dev/null     # Redirect to /dev/null when logging is disabled
fi

#===============================================
# Translation function
#===============================================
# Translation function
translate() {
    local lang="${LANG%%.*}"
    # Convert underscore to hyphen in language code
    lang="${lang/_/-}"
    
    log "DEBUG: Translation requested for: '$1'"
    log "DEBUG: Current LANG: $LANG"
    log "DEBUG: Extracted language code: $lang"
    
    # Map standard locale codes to our file naming convention
    case "$lang" in
        "es-ES") po_file="$(dirname "$0")/po/img2pdf_gui-es-ES.po" ;;
        "es-AR") po_file="$(dirname "$0")/po/img2pdf_gui-es-AR.po" ;;
        "de-DE") po_file="$(dirname "$0")/po/img2pdf_gui-de.po" ;;
        "ru-RU") po_file="$(dirname "$0")/po/img2pdf_gui-ru.po" ;;
        "zh-CN") po_file="$(dirname "$0")/po/img2pdf_gui-zh-CN.po" ;;
        "uk-UA") po_file="$(dirname "$0")/po/img2pdf_gui-uk.po" ;;
        "pt-BR") po_file="$(dirname "$0")/po/img2pdf_gui-pt-BR.po" ;;
        "pl-PL") po_file="$(dirname "$0")/po/img2pdf_gui-pl.po" ;;
        "it-IT") po_file="$(dirname "$0")/po/img2pdf_gui-it.po" ;;
        *) po_file="$(dirname "$0")/po/img2pdf_gui-${lang}.po" ;;
    esac
    
    log "DEBUG: Looking for translation file: $po_file"
    
    if [ -f "$po_file" ]; then
        msgid="$1"
        log "DEBUG: Found po file, searching for msgid: '$msgid'"
        # Use sed instead of grep for more reliable extraction
        msgstr=$(sed -n "/^msgid \"$msgid\"/,/^msgstr/p" "$po_file" | grep "^msgstr" | cut -d'"' -f2)
        if [ -n "$msgstr" ]; then
            log "DEBUG: Found translation: '$msgstr'"
            echo "$msgstr"
        else
            log "DEBUG: No translation found, using original: '$msgid'"
            echo "$msgid"
        fi
    else
        log "DEBUG: No po file found, using original: '$1'"
        echo "$1"
    fi
}

# Load defaults if available
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Set default values if not already loaded
DEFAULT_OUTPUT="${DEFAULT_OUTPUT:-output.pdf}"
DEFAULT_PAGE_SIZE="${DEFAULT_PAGE_SIZE:-A4}"
DEFAULT_ORIENTATION="${DEFAULT_ORIENTATION:-Portrait}"
DEFAULT_RESIZE_METHOD="${DEFAULT_RESIZE_METHOD:-None}"
DEFAULT_DPI="${DEFAULT_DPI:-300}"
DEFAULT_QUALITY="${DEFAULT_QUALITY:-90}"

# Enhanced Logging Functions
log() {
    if [ "$LOGGING_ENABLED" = "true" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >&3
    fi
}

log_section() {
    if [ "$LOGGING_ENABLED" = "true" ]; then
        echo -e "\n===== $1 =====" >&3
    fi
}

log_command() {
    if [ "$LOGGING_ENABLED" = "true" ]; then
        log "Executing: $(printf "%q " "$@")"
        "$@" > >(tee -a "$LOG_FILE" >&3) 2> >(tee -a "$LOG_FILE" >&2)
    else
        "$@"
    fi
    return $?
}

# Debug Information
log_system_info() {
    log_section "$(translate "System Information")"
    log "$(translate "OS"): $(lsb_release -d | cut -f2-)"
    log "img2pdf: $(img2pdf --version 2>&1 || echo "$(translate 'Not installed')")"
    log "ImageMagick: $(convert --version | head -n1)"
    # Set LC_ALL=C for yad to prevent locale warnings
    LC_ALL=C log "yad: $(yad --version 2>&1 || echo "$(translate 'Not installed')")"
    log "$(translate "Temp Directory"): $TEMP_DIR"
}

# Cleanup with logging
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        log "$(translate "Cleaning up temporary files...")"
        rm -rf "$TEMP_DIR" && log "$(translate "Temporary files removed")" || log "$(translate "Failed to remove temp files")"
    fi
}
trap cleanup EXIT

# List filtering to avoid duplicates and escape '!' for yad compatibility
uniq_list() {
    local default="$1"; shift
    local out=()
    local translated

    # Add translated default value with escaped '!'
    translated="$(translate "$default")"
    translated="${translated//\!/\\!}"
    out+=("$translated")

    # Add other translated values, skip duplicates
    for item in "$@"; do
        if [ "$item" != "$default" ]; then
            translated="$(translate "$item")"
            translated="${translated//\!/\\!}"
            out+=("$translated")
        fi
    done

    # Use printf to safely join with ! (already escaped)
    printf '%s' "${out[0]}"
    for ((i=1; i<${#out[@]}; i++)); do
        printf '!%s' "${out[$i]}"
    done
}


# Get conversion settings with validation
get_settings() {
    log_section "$(translate "User Settings")"
    local settings
    
    
    # Build yad command for logging
    local yad_cmd='yad --form \
        --title="'"$(translate "PDF Merger (img2pdf)")"'" \
        --width=400 \
        --field="'"$(translate "Output Filename")"'" "'"$DEFAULT_OUTPUT"'" \
        --field="'"$(translate "Page Size"):CB"'" "'"$(uniq_list "$DEFAULT_PAGE_SIZE" A0 A1 A2 A3 A4 A5 A6 Letter Legal Tabloid JB0 JB1 JB2)"'" \
        --field="'"$(translate "Orientation"):CB"'" "'"$(uniq_list "$DEFAULT_ORIENTATION" "$(translate "Portrait")" "$(translate "Landscape")")"'" \
        --field="'"$(translate "Resize Method"):CB"'" "'"$(uniq_list "$DEFAULT_RESIZE_METHOD" "$(translate "None")" "$(translate "Fit to Page")" "$(translate "Stretch to Page")")"'" \
        --field="DPI:NUM" "'"$DEFAULT_DPI!72..600!1!"'" \
        --field="'"$(translate "Quality (1-100)"):NUM"'" "'"$DEFAULT_QUALITY!1..100!1!"'" \
        --field="'"$(translate "Save as default"):CHK"'" "FALSE"'
    
    log "DEBUG: Executing yad command:"
    log "DEBUG: $yad_cmd"
    
    # Set LC_ALL=C for yad to prevent locale warnings
    LC_ALL=C settings=$(eval "$yad_cmd" 2>&1)

    local yad_exit=$?
    log "yad dialog exit code: $yad_exit"
    [ $yad_exit -ne 0 ] && return 1

    # Convert translated values back to English for internal use
    local translated_settings="$settings"
    IFS='|' read -r outfile pagesize orientation resize_method dpi quality save_default <<< "$settings"
    
    # Convert translated values back to English
    case "$pagesize" in
        "$(translate "A0")") pagesize="A0" ;;
        "$(translate "A1")") pagesize="A1" ;;
        "$(translate "A2")") pagesize="A2" ;;
        "$(translate "A3")") pagesize="A3" ;;
        "$(translate "A4")") pagesize="A4" ;;
        "$(translate "A5")") pagesize="A5" ;;
        "$(translate "A6")") pagesize="A6" ;;
        "$(translate "Letter")") pagesize="Letter" ;;
        "$(translate "Legal")") pagesize="Legal" ;;
        "$(translate "Tabloid")") pagesize="Tabloid" ;;
        "$(translate "JB0")") pagesize="JB0" ;;
        "$(translate "JB1")") pagesize="JB1" ;;
        "$(translate "JB2")") pagesize="JB2" ;;
    esac
    
    case "$orientation" in
        "$(translate "Portrait")") orientation="Portrait" ;;
        "$(translate "Landscape")") orientation="Landscape" ;;
    esac
    
    case "$resize_method" in
        "$(translate "None")") resize_method="None" ;;
        "$(translate "Fit to Page")") resize_method="Fit to Page" ;;
        "$(translate "Stretch to Page")") resize_method="Stretch to Page" ;;
    esac

    log "$(translate "Output"): $outfile"
    log "$(translate "Page Size"): $pagesize"
    log "$(translate "Orientation"): $orientation"
    log "$(translate "Resize Method"): $resize_method"
    log "DPI: $dpi"
    log "$(translate "Quality"): $quality"
    log "$(translate "Save settings as default"): $save_default"

    if [ "$save_default" = "TRUE" ]; then
        log "$(translate "Saving user defaults to") $CONFIG_FILE"
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" <<EOF
DEFAULT_OUTPUT="$outfile"
DEFAULT_PAGE_SIZE="$pagesize"
DEFAULT_ORIENTATION="$orientation"
DEFAULT_RESIZE_METHOD="$resize_method"
DEFAULT_DPI=$dpi
DEFAULT_QUALITY=$quality
EOF
    else
        log "$(translate "User did not request to save settings")"
    fi

    echo "$outfile|$pagesize|$orientation|$resize_method|$dpi|$quality"
}

# Enhanced image processing with detailed logging
process_images() {
    local width=$1 height=$2 resize_method=$3 quality=$4
    shift 4
    
    log_section "$(translate "Image Processing")"
    log "$(translate "Resize Method"): $resize_method"
    log "$(translate "Target Dimensions"): ${width}x${height}"
    log "$(translate "Quality Setting"): $quality"
    log "$(translate "Input Files"): $*"
    
    local processed_files=()
    for img in "$@"; do
        local processed="$TEMP_DIR/$(basename "$img")"
        log "$(translate "Processing"): $img → $processed"
        
        case "$resize_method" in
            "$(translate "Fit to Page")")
                log_command convert "$img" -resize "${width}x${height}>" -quality "$quality" "$processed"
                ;;
            "$(translate "Stretch to Page")")
                log_command convert "$img" -resize "${width}x${height}!" -quality "$quality" "$processed"
                ;;
            "$(translate "None")")
                log_command convert "$img" -density "$dpi" -quality "$quality" "$processed"
                ;;
        esac
        
        if [ ! -f "$processed" ]; then
            log "$(translate "ERROR: Failed to process") $img"
            return 1
        fi
        
        processed_files+=("$processed")
        log "$(translate "Successfully processed"): $processed"
    done
    
    printf "%s\n" "${processed_files[@]}"
}

# Dimension calculation
get_dimensions() {
    local page_size=$1 dpi=$2
    case "$page_size" in
        A0)      echo $((841*dpi/25)) $((1189*dpi/25)) ;;
        A1)      echo $((594*dpi/25)) $((841*dpi/25)) ;;
        A2)      echo $((420*dpi/25)) $((594*dpi/25)) ;;
        A3)      echo $((297*dpi/25)) $((420*dpi/25)) ;;
        A4)      echo $((210*dpi/25)) $((297*dpi/25)) ;;
        A5)      echo $((148*dpi/25)) $((210*dpi/25)) ;;
        A6)      echo $((105*dpi/25)) $((148*dpi/25)) ;;
        JB0)     echo $((1030*dpi/25)) $((1456*dpi/25)) ;;
        JB1)     echo $((728*dpi/25)) $((1030*dpi/25)) ;;
        JB2)     echo $((515*dpi/25)) $((728*dpi/25)) ;;
        Letter)  echo $((216*dpi/25)) $((279*dpi/25)) ;;
        Legal)   echo $((216*dpi/25)) $((356*dpi/25)) ;;
        Tabloid) echo $((279*dpi/25)) $((432*dpi/25)) ;;
        *)       echo 0 0 ;;
    esac
}

main() {
    log_section "$(translate "Conversion Started")"
    log_system_info
    log "$(translate "Input Files") ($#): $*"
    
    # Get settings
    local settings
    settings=$(get_settings) || { log "$(translate "User cancelled operation")"; exit 1; }
    IFS='|' read -r outfile pagesize orientation resize_method dpi quality <<< "$settings"
    
    # Ensure PDF extension
    outfile="${outfile%.pdf}.pdf"
    log "$(translate "Final Output File"): $outfile"
    
    # Calculate target dimensions
    read width height <<< $(get_dimensions "$pagesize" "$dpi")
    if [ "$orientation" = "$(translate "Landscape")" ]; then
        pagesize="${pagesize}^T"
        log "$(translate "Adjusted Page Size for Landscape"): $pagesize"
    fi

    # Process images and safely read array
    IFS=$'\n' read -r -d '' -a processed_files < <(process_images "$width" "$height" "$resize_method" "$quality" "$@" && printf '\0') || {
        log "$(translate "Image processing failed")"
        # Set LC_ALL=C for zenity to prevent locale warnings
        LC_ALL=C zenity --error --text="$(translate "Image processing failed\nSee") $LOG_FILE $(translate "for details")" --width=400
        exit 1
    }

    # Create PDF using processed images
    log_section "$(translate "PDF Generation")"
    output_dir="$(dirname "$1")"
    log "$(translate "Output Directory"): $output_dir"
    log_command img2pdf "${processed_files[@]}" --pagesize "$pagesize" -o "$output_dir/$outfile" --rotation=ifvalid
    local pdf_exit=$?
    
    if [ $pdf_exit -eq 0 ]; then
        log "$(translate "PDF successfully created"): $output_dir/$outfile"
        log "$(translate "File size"): $(du -h "$output_dir/$outfile" | cut -f1)"
        xdg-open "$output_dir/$outfile"
    else
        log "$(translate "PDF creation failed with exit code") $pdf_exit"
        # Set LC_ALL=C for zenity to prevent locale warnings
        LC_ALL=C zenity --error --text="$(translate "PDF creation failed (code") $pdf_exit)\n$(translate "See") $LOG_FILE $(translate "for details")" --width=400
        exit 1
    fi
    
    log_section "$(translate "Conversion Completed")"
}

main "$@"

