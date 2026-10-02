# Draws the app's launcher icon (the letters "CB" in the app's serif face on
# the ink-black brand colour) at every Android size.
#
# Run again only if the icon design should change:
#   powershell -ExecutionPolicy Bypass -File tools\make-icon.ps1

Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$fonts = New-Object System.Drawing.Text.PrivateFontCollection
$fonts.AddFontFile((Join-Path $root 'assets\fonts\InstrumentSerif-Regular.ttf'))
$family = $fonts.Families[0]

$sizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }

foreach ($entry in $sizes.GetEnumerator()) {
    $size = $entry.Value
    $bitmap = New-Object System.Drawing.Bitmap $size, $size
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = 'AntiAlias'
    $graphics.TextRenderingHint = 'AntiAliasGridFit'
    $graphics.Clear([System.Drawing.Color]::FromArgb(0x16, 0x16, 0x16))

    $font = New-Object System.Drawing.Font $family, ($size * 0.44), ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
    $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(0xF4, 0xF2, 0xEE))
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = 'Center'
    $format.LineAlignment = 'Center'
    $area = New-Object System.Drawing.RectangleF 0, ($size * 0.02), $size, $size
    $graphics.DrawString('CB', $font, $brush, $area, $format)

    $target = Join-Path $root "android\app\src\main\res\mipmap-$($entry.Key)\ic_launcher.png"
    $bitmap.Save($target, [System.Drawing.Imaging.ImageFormat]::Png)
    $graphics.Dispose(); $bitmap.Dispose(); $font.Dispose(); $brush.Dispose()
    "wrote $target"
}
