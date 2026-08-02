Add-Type -AssemblyName System.Drawing

$outputDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$plainText = Get-Content -Raw -Encoding UTF8 (Join-Path $outputDir 'plain.txt')
[System.IO.File]::WriteAllText((Join-Path $outputDir 'plain-utf16le.txt'), $plainText, [System.Text.Encoding]::Unicode)

$bitmap = [System.Drawing.Bitmap]::new(320, 200, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
  $graphics.Clear([System.Drawing.Color]::White)
  $graphics.FillRectangle([System.Drawing.Brushes]::Red, 0, 0, 100, 200)
  $graphics.FillRectangle([System.Drawing.Brushes]::Lime, 100, 0, 120, 200)
  $graphics.FillRectangle([System.Drawing.Brushes]::Blue, 220, 0, 100, 200)
  $graphics.DrawRectangle([System.Drawing.Pens]::Black, 0, 0, 319, 199)
  $font = [System.Drawing.Font]::new('Arial', 18, [System.Drawing.FontStyle]::Bold)
  try {
    $graphics.DrawString('QA 320x200', $font, [System.Drawing.Brushes]::Black, 92, 82)
  } finally {
    $font.Dispose()
  }

  $bitmap.Save((Join-Path $outputDir 'color-grid.png'), [System.Drawing.Imaging.ImageFormat]::Png)
  $bitmap.Save((Join-Path $outputDir 'color-grid.jpg'), [System.Drawing.Imaging.ImageFormat]::Jpeg)
  $bitmap.Save((Join-Path $outputDir 'color-grid.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
} finally {
  $graphics.Dispose()
  $bitmap.Dispose()
}
