#!/bin/bash

# YouTube Transcript Fetcher
# Usage: ./fetch_transcript.sh VIDEO_ID [OPTIONS]
# Example: ./fetch_transcript.sh Fg7yTKX5xxo
# Example: ./fetch_transcript.sh Fg7yTKX5xxo --lang en --format json

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
LANGUAGE="en"
FORMAT="txt"
OUTPUT_DIR="./transcripts"

# Function to display usage
usage() {
    echo "Usage: $0 VIDEO_ID [OPTIONS]"
    echo ""
    echo "Arguments:"
    echo "  VIDEO_ID    YouTube video ID (e.g., Fg7yTKX5xxo)"
    echo ""
    echo "Options:"
    echo "  --lang LANG     Language code (default: en)"
    echo "  --format FORMAT Output format: txt, json, vtt, srt (default: txt)"
    echo "  --output DIR    Output directory (default: ./transcripts)"
    echo "  --help         Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 Fg7yTKX5xxo"
    echo "  $0 Fg7yTKX5xxo --lang en --format json"
    echo "  $0 Fg7yTKX5xxo --format srt --output ~/Downloads"
    exit 1
}

# Function to check if yt-dlp is installed
check_dependencies() {
    if ! command -v yt-dlp &> /dev/null; then
        echo -e "${RED}Error: yt-dlp is not installed${NC}"
        echo ""
        echo "Please install yt-dlp:"
        echo "  pip install yt-dlp"
        echo "  # or"
        echo "  brew install yt-dlp"
        echo "  # or"
        echo "  sudo apt install yt-dlp"
        exit 1
    fi
}

# Function to validate video ID
validate_video_id() {
    local video_id="$1"
    if [[ ! "$video_id" =~ ^[a-zA-Z0-9_-]{11}$ ]]; then
        echo -e "${RED}Error: Invalid YouTube video ID format${NC}"
        echo "Video ID should be 11 characters long (e.g., Fg7yTKX5xxo)"
        exit 1
    fi
}

# Function to convert VTT to clean text
convert_vtt_to_text() {
    local vtt_file="$1"
    local output_file="$2"
    
    # Use awk to process VTT file with advanced deduplication
    awk '
    BEGIN {
        in_subtitle_block = 0
        text_after_timestamp = 0
        current_text = ""
    }
    
    # Skip WEBVTT header lines
    /^WEBVTT/ { next }
    /^Kind:/ { next }
    /^Language:/ { next }
    /^NOTE/ { next }
    
    # Detect timestamp lines
    /^[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}/ {
        text_after_timestamp = 1
        next
    }
    
    # Skip positioning/alignment lines
    /^align:/ { next }
    /^position:/ { next }
    /^size:/ { next }
    /^line:/ { next }
    
    # Empty line - end of subtitle block
    /^$/ {
        if (current_text != "") {
            # Store all texts to process later with better deduplication
            all_texts[++text_count] = current_text
        }
        current_text = ""
        text_after_timestamp = 0
        next
    }
    
    # Process subtitle text lines
    text_after_timestamp == 1 && NF > 0 {
        line = $0
        
        # Remove inline timing tags like <00:00:02.720><c>
        gsub(/<[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}><c>/, "", line)
        
        # Remove closing tags </c>
        gsub(/<\/c>/, "", line)
        
        # Remove any other HTML/XML tags
        gsub(/<[^>]*>/, "", line)
        
        # Remove extra whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", line)
        gsub(/[ \t]+/, " ", line)
        
        if (line != "") {
            if (current_text == "") {
                current_text = line
            } else {
                current_text = current_text " " line
            }
        }
    }
    
    # Handle last subtitle block if file does not end with empty line
    END {
        if (current_text != "") {
            all_texts[++text_count] = current_text
        }
        
        # Advanced deduplication: remove texts that are substrings of later texts
        for (i = 1; i <= text_count; i++) {
            if (all_texts[i] == "") continue
            
            keep_text = 1
            for (j = i + 1; j <= text_count; j++) {
                if (all_texts[j] == "") continue
                
                # If current text is a substring of a later text, skip it
                if (index(all_texts[j], all_texts[i]) == 1) {
                    keep_text = 0
                    break
                }
                # If a later text is a substring of current text, remove the later one
                else if (index(all_texts[i], all_texts[j]) == 1) {
                    all_texts[j] = ""
                }
            }
            
            if (keep_text && !seen[all_texts[i]]) {
                print all_texts[i]
                seen[all_texts[i]] = 1
            }
        }
    }
    ' "$vtt_file" > "$output_file"
    
    local line_count=$(wc -l < "$output_file" 2>/dev/null || echo "0")
    echo "Converted $line_count text segments"
}

# Function to extract video ID from URL if needed
extract_video_id() {
    local input="$1"
    
    # If it's already a video ID (11 chars), return as-is
    if [[ "$input" =~ ^[a-zA-Z0-9_-]{11}$ ]]; then
        echo "$input"
        return
    fi
    
    # Extract from various YouTube URL formats
    if [[ "$input" =~ youtu\.be/([a-zA-Z0-9_-]{11}) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$input" =~ youtube\.com/watch\?v=([a-zA-Z0-9_-]{11}) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$input" =~ youtube\.com/.*[?\&]v=([a-zA-Z0-9_-]{11}) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        echo -e "${RED}Error: Could not extract video ID from: $input${NC}"
        exit 1
    fi
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    usage
fi

VIDEO_INPUT="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        --lang)
            LANGUAGE="$2"
            shift 2
            ;;
        --format)
            FORMAT="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            ;;
    esac
done

# Main execution
main() {
    echo -e "${GREEN}YouTube Transcript Fetcher${NC}"
    echo "=========================="
    
    # Check dependencies
    check_dependencies
    
    # Extract video ID
    VIDEO_ID=$(extract_video_id "$VIDEO_INPUT")
    validate_video_id "$VIDEO_ID"
    
    echo -e "Video ID: ${YELLOW}$VIDEO_ID${NC}"
    echo -e "Language: ${YELLOW}$LANGUAGE${NC}"
    echo -e "Format: ${YELLOW}$FORMAT${NC}"
    echo -e "Output Directory: ${YELLOW}$OUTPUT_DIR${NC}"
    echo ""
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Build yt-dlp command based on format
    local url="https://www.youtube.com/watch?v=$VIDEO_ID"
    local output_file="$OUTPUT_DIR/${VIDEO_ID}_transcript"
    
    case $FORMAT in
        txt)
            echo "Fetching transcript as plain text..."
            yt-dlp --write-subs --write-auto-subs --sub-langs "$LANGUAGE" --skip-download \
                   --output "$output_file.%(ext)s" "$url"
            
            # Convert VTT to plain text if needed
            if [ -f "$output_file.$LANGUAGE.vtt" ]; then
                convert_vtt_to_text "$output_file.$LANGUAGE.vtt" "$output_file.txt"
                echo -e "${GREEN}Transcript saved to: $output_file.txt${NC}"
            fi
            ;;
        json)
            echo "Fetching transcript metadata..."
            yt-dlp --write-info-json --skip-download \
                   --output "$output_file.%(ext)s" "$url"
            echo -e "${GREEN}Video info saved to: $output_file.info.json${NC}"
            ;;
        vtt|srt)
            echo "Fetching transcript as $FORMAT..."
            yt-dlp --write-subs --write-auto-subs --sub-langs "$LANGUAGE" --skip-download \
                   --output "$output_file.%(ext)s" "$url"
            
            if [ -f "$output_file.$LANGUAGE.vtt" ] && [ "$FORMAT" = "srt" ]; then
                # Convert VTT to SRT if requested
                if command -v ffmpeg &> /dev/null; then
                    ffmpeg -i "$output_file.$LANGUAGE.vtt" "$output_file.srt" -y 2>/dev/null
                    echo -e "${GREEN}Transcript saved to: $output_file.srt${NC}"
                else
                    echo -e "${YELLOW}Warning: ffmpeg not found. VTT file saved instead.${NC}"
                    echo -e "${GREEN}Transcript saved to: $output_file.$LANGUAGE.vtt${NC}"
                fi
            else
                echo -e "${GREEN}Transcript saved to: $output_file.$LANGUAGE.$FORMAT${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Error: Unsupported format: $FORMAT${NC}"
            echo "Supported formats: txt, json, vtt, srt"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}Done!${NC}"
}

# Run main function
main
