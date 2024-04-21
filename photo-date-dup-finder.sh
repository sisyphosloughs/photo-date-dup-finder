#!/bin/bash

# Initializes empty variables for source directory, excluded directories, and file extensions
SOURCE_DIR=""
EXCLUDE_DIRS=""
FILE_EXTENSIONS=""
export NUMBER_FOUND_PAIRS=0 

# Specifies option string for getopts for option parsing
OPTSTRING=":s:e:f:"

# Processes command line options
while getopts ${OPTSTRING} opt; do
  case ${opt} in
    s) # Sets the source directory from the -s option
      export SOURCE_DIR="${OPTARG}"
      ;;
    e) # Sets directories to exclude from search from the -e option
      EXCLUDE_DIRS="${OPTARG}"
      ;;
    f) # Sets file extensions to include in search from the -f option
      FILE_EXTENSIONS="${OPTARG}"
      ;;
    :) # Handles missing option arguments
      echo "Option -${OPTARG} requires an argument."
      exit 1
      ;;
    ?) # Handles invalid options
      echo "Invalid option: -${OPTARG}."
      exit 1
      ;;
  esac
done

# Verifies required parameters (source directory) and displays usage if missing
if [ -z "${SOURCE_DIR}" ] || [ $# -eq 0 ]; then
    echo "Usage: $0 -s <SourceDirectoryPath> [-e <ExcludeDirectories>] [-f <FileExtensions>]"
    exit 1
fi

# Checks for exiftool availability and exits if not found
if ! command -v exiftool &> /dev/null; then
    echo "Error: exiftool is not installed." >&2
    exit 1
fi

# Defines a function to process a single image file
process_file() {
    # Checks if a file path is provided
    if [ $# -eq 0 ]; then
        echo "Error: No file path provided."
        return 1
    fi

    local image=$1

    # Processes image if it is an actual image or bitmap file
    if file "$image" | grep -qE 'image|bitmap'; then
        # Extracts timestamp using exiftool
        timestamp=$(exiftool -CreateDate -d %s%f -p '$CreateDate' "$image")

        # Appends the image and its timestamp to log file
        echo "# $timestamp \"$image\"" >> "$IMAGE_DATES"

    else
        # Logs files that are not images
        echo "# File is not an image: \"$image\"" >> "$NOT_AN_IMAGE"
    fi
}

# Exports the process_file function to make it available in subprocesses
export -f process_file

# Initializes log files for image processing results
export IMAGE_DATES="found.txt"
echo -n "" > "$IMAGE_DATES"
export NOT_AN_IMAGE="rest.txt"
echo -n "" > "$NOT_AN_IMAGE"
export FOUND_PAIRS="remove_pairs.sh"
echo -n "" > "$FOUND_PAIRS"

# Constructs find command strings to handle directory exclusions
EXCLUDE_STRING=""
if [ ! -z "$EXCLUDE_DIRS" ]; then
    IFS=',' read -ra ADDR <<< "$EXCLUDE_DIRS" # Splits EXCLUDE_DIRS into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        # Begins constructing the exclusion string
        EXCLUDE_STRING="-name '${ADDR[0]}'"
        for i in "${ADDR[@]:1}"; do
            EXCLUDE_STRING="$EXCLUDE_STRING -o -name '$i'"
        done
        EXCLUDE_STRING="-type d \( $EXCLUDE_STRING \) -prune -o"
    fi
fi

# Constructs find command strings to handle file extensions
INCLUDE_STRING=""
if [ ! -z "$FILE_EXTENSIONS" ]; then
    IFS=',' read -ra ADDR <<< "$FILE_EXTENSIONS" # Splits FILE_EXTENSIONS into an array
    if [ ${#ADDR[@]} -gt 0 ]; then
        INCLUDE_STRING="-iname '*.${ADDR[0]}'"
        for i in "${ADDR[@]:1}"; do
            INCLUDE_STRING="$INCLUDE_STRING -o -iname '*.$i'"
        done
        INCLUDE_STRING="-type f \( $INCLUDE_STRING \)"
    fi
fi

# Verifies the existence of the source directory
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: The directory \"$SOURCE_DIR\" does not exist."
    exit 1
fi

# Determines the number of CPU cores available for parallel processing
N_CORES=$(nproc)

# Executes find with constructed include and exclude strings and processes files in parallel
eval find \"$SOURCE_DIR\" $EXCLUDE_STRING $INCLUDE_STRING -type f -print0 | xargs -0 -P "$N_CORES" -I {} bash -c 'process_file "$@"' _ {}

# Sorts image data and removes duplicate timestamps
sort "$IMAGE_DATES" | while read line; do
    TIMESTAMP=$(echo "$line" | awk '{print $2}')
    IMAGE_PATH=$(echo "$line" | awk '{print $3}')

    if [ "$LAST_TIMESTAMP" != "$TIMESTAMP" ]; then
        if [ ${#IMAGE_PATHS[@]} -gt 1 ]; then
            echo "# $LAST_TIMESTAMP" >> "$FOUND_PAIRS"
            for P in "${IMAGE_PATHS[@]}"; do
                echo "# rm $P" >> "$FOUND_PAIRS"
            done
            echo "# Files: ${#IMAGE_PATHS[@]}" >> "$FOUND_PAIRS"
            echo >> "$FOUND_PAIRS"
            NUMBER_FOUND_PAIRS=$((NUMBER_FOUND_PAIRS + 1))
        fi
        LAST_TIMESTAMP="$TIMESTAMP"
        IMAGE_PATHS=()
    fi
    IMAGE_PATHS+=("$IMAGE_PATH")
done

# Handles the last block of images after the end of the loop
if [ ${#IMAGE_PATHS[@]} -gt 1 ]; then
    echo "# $LAST_TIMESTAMP" >> "$FOUND_PAIRS"
    for P in "${IMAGE_PATHS[@]}"; do
        echo "# rm $P" >> "$FOUND_PAIRS"
    done
    echo "# Files: ${#IMAGE_PATHS[@]}" >> "$FOUND_PAIRS"
    NUMBER_FOUND_PAIRS=$((NUMBER_FOUND_PAIRS + 1))
fi

# Summarizes and reports the outcome
NUMBER_IMAGE_DATES=$(wc -l < "$IMAGE_DATES")
NUMBER_NOT_AN_IMAGE=$(wc -l < "$NOT_AN_IMAGE")
NUMBER_FOUND_PAIRS=$(grep '^# rm' "$FOUND_PAIRS" | wc -l)

echo "$NUMBER_IMAGE_DATES images with dates (see found.text)."
echo "$NUMBER_NOT_AN_IMAGE files are not an image (see rest.txt)."
echo "$NUMBER_FOUND_PAIRS images with same timestamp (see remove_pairs.sh)."
