# PowerShell script to create web-optimized versions of images
# Windows equivalent of optimize_for_web.sh

# Configuration
$WebDir = "web"
$MaxSize = 1600  # Max dimension for web images
$Quality = 85    # JPEG quality (0-100)

# Get the directory where the script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir

# Create web directory if it doesn't exist
if (-not (Test-Path $WebDir)) {
    New-Item -ItemType Directory -Path $WebDir | Out-Null
}

# Load System.Drawing assembly for image processing
Add-Type -AssemblyName System.Drawing

# Counter for processed images
$count = 0
$totalOrigSize = 0
$totalNewSize = 0

Write-Host "Creating web-optimized images..."
Write-Host ""

# Get all image files (using wildcard path for -Include to work correctly)
$imageFiles = Get-ChildItem -Path ".\*" -Include *.jpg, *.jpeg, *.png, *.gif, *.JPG, *.JPEG, *.PNG, *.GIF -File

foreach ($img in $imageFiles) {
    $filename = $img.Name
    $outputPath = Join-Path (Join-Path $ScriptDir $WebDir) $filename

    # Skip if web version already exists and is newer than source
    if ((Test-Path $outputPath) -and ((Get-Item $outputPath).LastWriteTime -gt $img.LastWriteTime)) {
        Write-Host "Skipping $filename (web version up to date)"
        continue
    }

    Write-Host "Processing: $filename"

    try {
        # Load image bytes into memory first to avoid file locking issues
        $bytes = [System.IO.File]::ReadAllBytes($img.FullName)
        $memStream = New-Object System.IO.MemoryStream($bytes, $false)
        $image = [System.Drawing.Image]::FromStream($memStream)

        # Calculate new dimensions maintaining aspect ratio
        $ratioX = $MaxSize / $image.Width
        $ratioY = $MaxSize / $image.Height
        $ratio = [Math]::Min($ratioX, $ratioY)

        # Only resize if image is larger than max size
        if ($ratio -lt 1) {
            $newWidth = [int]($image.Width * $ratio)
            $newHeight = [int]($image.Height * $ratio)
        } else {
            $newWidth = $image.Width
            $newHeight = $image.Height
        }

        # Create resized bitmap
        $resized = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($resized)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
        $graphics.Dispose()

        # Get JPEG encoder
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Quality)

        # Save optimized image
        $resized.Save($outputPath, $jpegCodec, $encoderParams)

        # Clean up
        $resized.Dispose()
        $image.Dispose()
        $memStream.Dispose()

        # Get file sizes for comparison
        $origSize = $img.Length
        $newSize = (Get-Item $outputPath).Length
        $totalOrigSize += $origSize
        $totalNewSize += $newSize

        # Format sizes for display
        $origSizeStr = if ($origSize -gt 1MB) { "{0:N1} MB" -f ($origSize / 1MB) } else { "{0:N0} KB" -f ($origSize / 1KB) }
        $newSizeStr = if ($newSize -gt 1MB) { "{0:N1} MB" -f ($newSize / 1MB) } else { "{0:N0} KB" -f ($newSize / 1KB) }

        Write-Host "  $origSizeStr -> $newSizeStr"

        $count++
    }
    catch {
        Write-Host "  Error processing $filename : $_"
    }
}

Write-Host ""
Write-Host "Done! Processed $count image(s) to '$WebDir/'"
Write-Host ""

# Show total size comparison
if ($totalOrigSize -gt 0) {
    $totalOrigStr = if ($totalOrigSize -gt 1MB) { "{0:N1} MB" -f ($totalOrigSize / 1MB) } else { "{0:N0} KB" -f ($totalOrigSize / 1KB) }
    $totalNewStr = if ($totalNewSize -gt 1MB) { "{0:N1} MB" -f ($totalNewSize / 1MB) } else { "{0:N0} KB" -f ($totalNewSize / 1KB) }
    $savings = [Math]::Round((1 - $totalNewSize / $totalOrigSize) * 100, 1)
    Write-Host "Total: $totalOrigStr -> $totalNewStr ($savings% reduction)"
}
