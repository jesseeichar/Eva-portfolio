#!/bin/bash

# Script to create web-optimized versions of images
# Creates smaller, compressed versions for fast web loading

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

WEB_DIR="web"
MAX_SIZE=1600  # Max dimension for web images

# Images used in the website
IMAGES=(
    "eva809.jpg"
    "eva922.jpg"
    "eva935.jpg"
    "eva850.jpg"
    "eva951.jpg"
    "IMG_2298.JPG"
    "eva812.jpg"
    "eva861.jpg"
    "Eva691.jpg"
    "eva961.jpg"
)

mkdir -p "$WEB_DIR"

echo "Creating web-optimized images..."
echo ""

for img in *.jpg *.JPG *.jpeg *.JPEG *.png *.PNG *.gif *.GIF; do
    if [ -f "$img" ]; then
        # Get base name (convert to lowercase for consistency)
        base=$(basename "$img")
        output="$WEB_DIR/$base"

        echo "Processing: $img"

        # Resize to max dimension while maintaining aspect ratio
        # Use sips with lower quality for better compression
        sips -Z "$MAX_SIZE" "$img" --out "$output" >/dev/null 2>&1

        # Get original and new file sizes
        orig_size=$(ls -lh "$img" | awk '{print $5}')
        new_size=$(ls -lh "$output" | awk '{print $5}')

        echo "  $orig_size -> $new_size"
    else
        echo "Warning: $img not found"
    fi
done

echo ""
echo "Done! Web-optimized images saved to '$WEB_DIR/'"
echo ""

# Show total size comparison
orig_total=$(du -sh . --exclude="$WEB_DIR" --exclude="thumbnails" 2>/dev/null | cut -f1)
web_total=$(du -sh "$WEB_DIR" 2>/dev/null | cut -f1)
echo "Web folder size: $web_total"
