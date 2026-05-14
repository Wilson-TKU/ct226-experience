<#
.SYNOPSIS
  批次將 photos/raw/ 內的照片縮圖、壓縮為 web 版，輸出到 photos/web/。

.DESCRIPTION
  - 長邊縮到 MaxDimension (預設 1600px)，等比縮放
  - JPEG 品質 80 (預設)
  - 自動處理 EXIF 旋轉
  - 只重新處理「來源比輸出新」或輸出不存在的檔案

.EXAMPLE
  pwsh ./scripts/process-photos.ps1
  pwsh ./scripts/process-photos.ps1 -MaxDimension 1920 -Quality 85
  pwsh ./scripts/process-photos.ps1 -Force      # 強制全部重做
#>

[CmdletBinding()]
param(
  [int]$MaxDimension = 1600,
  [int]$Quality = 80,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'

# 路徑：以本腳本所在位置為基準
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
$srcDir = Join-Path $projectRoot 'photos\raw'
$dstDir = Join-Path $projectRoot 'photos\web'

if (-not (Test-Path $srcDir)) {
  Write-Host "找不到來源資料夾：$srcDir" -ForegroundColor Red
  Write-Host "請建立 photos\raw\ 並把要處理的照片放進去。" -ForegroundColor Yellow
  exit 1
}
if (-not (Test-Path $dstDir)) {
  New-Item -ItemType Directory -Path $dstDir | Out-Null
}

Add-Type -AssemblyName System.Drawing

# 取得 JPEG encoder
$jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
  Where-Object { $_.MimeType -eq 'image/jpeg' } |
  Select-Object -First 1

$encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
$qualityEncoder = [System.Drawing.Imaging.Encoder]::Quality
$encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($qualityEncoder, [long]$Quality)

$files = Get-ChildItem -Path $srcDir -File -Include *.jpg, *.jpeg, *.JPG, *.JPEG -Recurse:$false
if (-not $files -or $files.Count -eq 0) {
  # PowerShell -Include 在沒有 -Recurse 時有時不生效，補一個過濾
  $files = Get-ChildItem -Path $srcDir -File | Where-Object { $_.Extension -match '^\.(jpg|jpeg)$' }
}

if (-not $files -or $files.Count -eq 0) {
  Write-Host "photos\raw\ 內沒有 jpg / jpeg 檔案。" -ForegroundColor Yellow
  exit 0
}

Write-Host ""
Write-Host "===== CT226 照片批次處理 =====" -ForegroundColor Cyan
Write-Host "來源    : $srcDir"
Write-Host "輸出    : $dstDir"
Write-Host "長邊上限: ${MaxDimension}px"
Write-Host "JPEG 品質: $Quality"
Write-Host "檔案數  : $($files.Count)"
Write-Host ""

$processed = 0
$skipped = 0
$totalInBytes = 0L
$totalOutBytes = 0L

foreach ($f in $files) {
  $outPath = Join-Path $dstDir $f.Name

  if ((-not $Force) -and (Test-Path $outPath)) {
    $outFile = Get-Item $outPath
    if ($outFile.LastWriteTime -ge $f.LastWriteTime) {
      Write-Host "  跳過  $($f.Name) (已是最新)" -ForegroundColor DarkGray
      $skipped++
      continue
    }
  }

  $img = $null
  $resized = $null
  $graphics = $null
  try {
    $img = [System.Drawing.Image]::FromFile($f.FullName)

    # 處理 EXIF 方向 (Orientation tag = 0x0112)
    $orientation = $null
    try {
      if ($img.PropertyIdList -contains 0x0112) {
        $orientation = $img.GetPropertyItem(0x0112).Value[0]
      }
    } catch { $orientation = $null }

    $w = $img.Width
    $h = $img.Height
    $ratio = [Math]::Min($MaxDimension / $w, $MaxDimension / $h)
    if ($ratio -ge 1) { $ratio = 1.0 }
    $newW = [int]([Math]::Round($w * $ratio))
    $newH = [int]([Math]::Round($h * $ratio))

    $resized = New-Object System.Drawing.Bitmap($newW, $newH)
    $graphics = [System.Drawing.Graphics]::FromImage($resized)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.DrawImage($img, 0, 0, $newW, $newH)

    # EXIF 旋轉
    if ($orientation) {
      switch ($orientation) {
        3 { $resized.RotateFlip([System.Drawing.RotateFlipType]::Rotate180FlipNone) }
        6 { $resized.RotateFlip([System.Drawing.RotateFlipType]::Rotate90FlipNone) }
        8 { $resized.RotateFlip([System.Drawing.RotateFlipType]::Rotate270FlipNone) }
      }
    }

    # 儲存
    if (Test-Path $outPath) { Remove-Item -Path $outPath -Force }
    $resized.Save($outPath, $jpegEncoder, $encoderParams)

    $inSize = $f.Length
    $outSize = (Get-Item $outPath).Length
    $totalInBytes += $inSize
    $totalOutBytes += $outSize

    $inKB = [Math]::Round($inSize / 1KB, 0)
    $outKB = [Math]::Round($outSize / 1KB, 0)
    $pct = [Math]::Round(($outSize / $inSize) * 100, 0)
    Write-Host ("  處理  {0,-32} {1,5} KB -> {2,5} KB  ({3}%)" -f $f.Name, $inKB, $outKB, $pct) -ForegroundColor Green
    $processed++
  }
  catch {
    Write-Host "  失敗  $($f.Name) :: $_" -ForegroundColor Red
  }
  finally {
    if ($graphics) { $graphics.Dispose() }
    if ($resized)  { $resized.Dispose() }
    if ($img)      { $img.Dispose() }
  }
}

Write-Host ""
Write-Host "===== 完成 =====" -ForegroundColor Cyan
Write-Host ("  處理 : {0} 張" -f $processed)
Write-Host ("  跳過 : {0} 張" -f $skipped)
if ($processed -gt 0) {
  $inMB = [Math]::Round($totalInBytes / 1MB, 1)
  $outMB = [Math]::Round($totalOutBytes / 1MB, 1)
  $saved = if ($totalInBytes -gt 0) { [Math]::Round((1 - $totalOutBytes / $totalInBytes) * 100, 0) } else { 0 }
  Write-Host ("  總大小: {0} MB -> {1} MB  (節省 {2}%)" -f $inMB, $outMB, $saved)
}
Write-Host ""
Write-Host "下一步: 開啟 index.html 確認照片載入正常，然後 git add . && git commit." -ForegroundColor Yellow
