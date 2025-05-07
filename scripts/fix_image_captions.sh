#!/bin/bash

# fix_image_captions.sh
# A script to fix image captions in markdown files

if [ $# -lt 1 ]; then
  echo "Usage: $0 <input.md>"
  exit 1
fi

INPUT_FILE="$1"

# Create a temporary file
TMP_FILE=$(mktemp)

# Process the file line by line
in_image=false
image_line=""

while IFS= read -r line; do
  # Check if this line contains an image
  if [[ "$line" =~ !\[.*\]\(.*\) ]]; then
    in_image=true
    image_line="$line"
    # Don't write the image line yet
  elif [ "$in_image" = true ]; then
    # This is the line after the image, which might be a caption
    if [[ -n "$line" ]]; then
      # This line has content, it's likely a caption
      # Write the image line
      echo "$image_line" >> "$TMP_FILE"
      
      # Write the caption line with proper formatting
      # Remove any asterisks (for italics) and add our own formatting
      caption_text="$line"
      caption_text="${caption_text#\*}"  # Remove leading asterisk if present
      caption_text="${caption_text%\*}"  # Remove trailing asterisk if present
      
      # Write the caption with HTML formatting to ensure it's on a new line
      echo "<p><em>$caption_text</em></p>" >> "$TMP_FILE"
    else
      # This is an empty line, just write both lines
      echo "$image_line" >> "$TMP_FILE"
      echo "$line" >> "$TMP_FILE"
    fi
    in_image=false
  else
    # Not an image or caption, just write the line
    echo "$line" >> "$TMP_FILE"
  fi
done < "$INPUT_FILE"

# Move the temporary file back to the original
mv "$TMP_FILE" "$INPUT_FILE"

echo "Image captions fixed in $INPUT_FILE"