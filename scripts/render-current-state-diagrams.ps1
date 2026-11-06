Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

function New-TextFormat {
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    return $format
}

function Draw-Box {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.RectangleF]$Rectangle,
        [string]$Text,
        [System.Drawing.Color]$FillColor,
        [System.Drawing.Font]$Font
    )

    $fill = [System.Drawing.SolidBrush]::new($FillColor)
    $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(52, 73, 94), 3)
    $textBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 39, 46))
    $format = New-TextFormat
    $Graphics.FillRectangle($fill, $Rectangle)
    $Graphics.DrawRectangle($border, $Rectangle.X, $Rectangle.Y, $Rectangle.Width, $Rectangle.Height)
    $Graphics.DrawString($Text, $Font, $textBrush, $Rectangle, $format)
    $fill.Dispose()
    $border.Dispose()
    $textBrush.Dispose()
    $format.Dispose()
}

function Draw-Arrow {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.PointF[]]$Points,
        [System.Drawing.Color]$Color,
        [bool]$Dashed = $false,
        [float]$Width = 4
    )

    $pen = [System.Drawing.Pen]::new($Color, $Width)
    if ($Dashed) {
        $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash
    }
    $Graphics.DrawLines($pen, $Points)

    $end = $Points[$Points.Count - 1]
    $previous = $Points[$Points.Count - 2]
    $angle = [Math]::Atan2($end.Y - $previous.Y, $end.X - $previous.X)
    $arrowLength = 16
    $arrowAngle = [Math]::PI / 7
    $left = [System.Drawing.PointF]::new(
        [float]($end.X - $arrowLength * [Math]::Cos($angle - $arrowAngle)),
        [float]($end.Y - $arrowLength * [Math]::Sin($angle - $arrowAngle))
    )
    $right = [System.Drawing.PointF]::new(
        [float]($end.X - $arrowLength * [Math]::Cos($angle + $arrowAngle)),
        [float]($end.Y - $arrowLength * [Math]::Sin($angle + $arrowAngle))
    )
    $brush = [System.Drawing.SolidBrush]::new($Color)
    $Graphics.FillPolygon($brush, [System.Drawing.PointF[]]@($end, $left, $right))
    $pen.Dispose()
    $brush.Dispose()
}

function Draw-Label {
    param(
        [System.Drawing.Graphics]$Graphics,
        [string]$Text,
        [float]$X,
        [float]$Y,
        [System.Drawing.Font]$Font,
        [System.Drawing.Color]$Color
    )

    $brush = [System.Drawing.SolidBrush]::new($Color)
    $Graphics.DrawString($Text, $Font, $brush, $X, $Y)
    $brush.Dispose()
}

function Save-DevelopmentDiagram {
    param(
        [string]$Path,
        [string]$Title,
        [string[]]$Steps,
        [string]$FixesLabel,
        [string]$FeedbackLabel
    )

    $bitmap = [System.Drawing.Bitmap]::new(1900, 520)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear([System.Drawing.Color]::White)

    $titleFont = [System.Drawing.Font]::new('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
    $boxFont = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
    $labelFont = [System.Drawing.Font]::new('Segoe UI', 13, [System.Drawing.FontStyle]::Regular)
    $titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 39, 46))
    $titleFormat = New-TextFormat
    $graphics.DrawString($Title, $titleFont, $titleBrush, [System.Drawing.RectangleF]::new(0, 20, 1900, 55), $titleFormat)

    $colors = @(
        [System.Drawing.Color]::FromArgb(227, 242, 253),
        [System.Drawing.Color]::FromArgb(232, 245, 233),
        [System.Drawing.Color]::FromArgb(255, 243, 224),
        [System.Drawing.Color]::FromArgb(243, 229, 245),
        [System.Drawing.Color]::FromArgb(255, 249, 196),
        [System.Drawing.Color]::FromArgb(224, 242, 241)
    )
    $rectangles = @()
    for ($i = 0; $i -lt 6; $i++) {
        $rect = [System.Drawing.RectangleF]::new([float](45 + $i * 310), 145, 240, 105)
        $rectangles += $rect
        Draw-Box -Graphics $graphics -Rectangle $rect -Text $Steps[$i] -FillColor $colors[$i] -Font $boxFont
        if ($i -gt 0) {
            $previous = $rectangles[$i - 1]
            Draw-Arrow -Graphics $graphics -Points ([System.Drawing.PointF[]]@(
                [System.Drawing.PointF]::new($previous.Right, $previous.Top + $previous.Height / 2),
                [System.Drawing.PointF]::new($rect.Left, $rect.Top + $rect.Height / 2)
            )) -Color ([System.Drawing.Color]::FromArgb(41, 128, 185))
        }
    }

    $dev = $rectangles[2]
    $test = $rectangles[3]
    Draw-Arrow -Graphics $graphics -Points ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($test.Left + $test.Width / 2, $test.Bottom),
        [System.Drawing.PointF]::new($test.Left + $test.Width / 2, 335),
        [System.Drawing.PointF]::new($dev.Left + $dev.Width / 2, 335),
        [System.Drawing.PointF]::new($dev.Left + $dev.Width / 2, $dev.Bottom)
    )) -Color ([System.Drawing.Color]::FromArgb(192, 57, 43)) -Dashed $true -Width 3
    Draw-Label -Graphics $graphics -Text $FixesLabel -X 850 -Y 342 -Font $labelFont -Color ([System.Drawing.Color]::FromArgb(192, 57, 43))

    $requirements = $rectangles[0]
    $production = $rectangles[5]
    Draw-Arrow -Graphics $graphics -Points ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($production.Left + $production.Width / 2, $production.Bottom),
        [System.Drawing.PointF]::new($production.Left + $production.Width / 2, 445),
        [System.Drawing.PointF]::new($requirements.Left + $requirements.Width / 2, 445),
        [System.Drawing.PointF]::new($requirements.Left + $requirements.Width / 2, $requirements.Bottom)
    )) -Color ([System.Drawing.Color]::FromArgb(39, 174, 96)) -Dashed $true -Width 3
    Draw-Label -Graphics $graphics -Text $FeedbackLabel -X 820 -Y 452 -Font $labelFont -Color ([System.Drawing.Color]::FromArgb(39, 174, 96))

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $titleBrush.Dispose()
    $titleFormat.Dispose()
    $titleFont.Dispose()
    $boxFont.Dispose()
    $labelFont.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-ReadinessDiagram {
    param(
        [string]$Path,
        [string]$Title,
        [string[]]$Labels,
        [int[]]$Values,
        [string]$TotalLabel,
        [int]$TotalValue
    )

    $bitmap = [System.Drawing.Bitmap]::new(1500, 720)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear([System.Drawing.Color]::White)

    $titleFont = [System.Drawing.Font]::new('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
    $labelFont = [System.Drawing.Font]::new('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
    $valueFont = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
    $totalFont = [System.Drawing.Font]::new('Segoe UI', 21, [System.Drawing.FontStyle]::Bold)
    $titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 39, 46))
    $titleFormat = New-TextFormat
    $graphics.DrawString($Title, $titleFont, $titleBrush, [System.Drawing.RectangleF]::new(0, 20, 1500, 55), $titleFormat)

    $labelFormat = [System.Drawing.StringFormat]::new()
    $labelFormat.Alignment = [System.Drawing.StringAlignment]::Far
    $labelFormat.LineAlignment = [System.Drawing.StringAlignment]::Center
    $labelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(44, 62, 80))
    $barBackground = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(236, 240, 241))
    $barBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(149, 165, 166), 2)
    $valueBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

    for ($i = 0; $i -lt $Labels.Count; $i++) {
        $y = [float](110 + $i * 92)
        $labelRect = [System.Drawing.RectangleF]::new(35, $y, 430, 62)
        $barRect = [System.Drawing.RectangleF]::new(500, $y + 6, 850, 50)
        $graphics.DrawString($Labels[$i], $labelFont, $labelBrush, $labelRect, $labelFormat)
        $graphics.FillRectangle($barBackground, $barRect)
        $graphics.DrawRectangle($barBorder, $barRect.X, $barRect.Y, $barRect.Width, $barRect.Height)

        $value = $Values[$i]
        if ($value -lt 20) {
            $color = [System.Drawing.Color]::FromArgb(192, 57, 43)
        } elseif ($value -lt 50) {
            $color = [System.Drawing.Color]::FromArgb(230, 126, 34)
        } elseif ($value -lt 75) {
            $color = [System.Drawing.Color]::FromArgb(41, 128, 185)
        } else {
            $color = [System.Drawing.Color]::FromArgb(39, 174, 96)
        }
        $fill = [System.Drawing.SolidBrush]::new($color)
        $fillWidth = [float]($barRect.Width * $value / 100)
        $graphics.FillRectangle($fill, $barRect.X, $barRect.Y, $fillWidth, $barRect.Height)

        $valueText = "$value %"
        $valueRect = if ($fillWidth -ge 85) {
            [System.Drawing.RectangleF]::new($barRect.X, $barRect.Y, $fillWidth - 12, $barRect.Height)
        } else {
            [System.Drawing.RectangleF]::new($barRect.X + $fillWidth + 12, $barRect.Y, 90, $barRect.Height)
        }
        $valueFormat = New-TextFormat
        if ($fillWidth -ge 85) {
            $valueFormat.Alignment = [System.Drawing.StringAlignment]::Far
            $currentValueBrush = $valueBrush
        } else {
            $valueFormat.Alignment = [System.Drawing.StringAlignment]::Near
            $currentValueBrush = $labelBrush
        }
        $graphics.DrawString($valueText, $valueFont, $currentValueBrush, $valueRect, $valueFormat)
        $valueFormat.Dispose()
        $fill.Dispose()
    }

    $totalRect = [System.Drawing.RectangleF]::new(500, 600, 850, 78)
    $totalFill = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(245, 247, 250))
    $totalBorder = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(52, 73, 94), 3)
    $graphics.FillRectangle($totalFill, $totalRect)
    $graphics.DrawRectangle($totalBorder, $totalRect.X, $totalRect.Y, $totalRect.Width, $totalRect.Height)
    $graphics.DrawString("${TotalLabel}: $TotalValue %", $totalFont, $titleBrush, $totalRect, $titleFormat)

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $titleFont.Dispose()
    $labelFont.Dispose()
    $valueFont.Dispose()
    $totalFont.Dispose()
    $titleBrush.Dispose()
    $titleFormat.Dispose()
    $labelFormat.Dispose()
    $labelBrush.Dispose()
    $barBackground.Dispose()
    $barBorder.Dispose()
    $valueBrush.Dispose()
    $totalFill.Dispose()
    $totalBorder.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

function Save-PrintingDiagram {
    param(
        [string]$Path,
        [string]$Title,
        [hashtable]$Labels
    )

    $bitmap = [System.Drawing.Bitmap]::new(1650, 650)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit
    $graphics.Clear([System.Drawing.Color]::White)

    $titleFont = [System.Drawing.Font]::new('Segoe UI', 24, [System.Drawing.FontStyle]::Bold)
    $boxFont = [System.Drawing.Font]::new('Segoe UI', 16, [System.Drawing.FontStyle]::Bold)
    $labelFont = [System.Drawing.Font]::new('Segoe UI', 13, [System.Drawing.FontStyle]::Regular)
    $titleBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(30, 39, 46))
    $titleFormat = New-TextFormat
    $graphics.DrawString($Title, $titleFont, $titleBrush, [System.Drawing.RectangleF]::new(0, 20, 1650, 55), $titleFormat)

    $bc = [System.Drawing.RectangleF]::new(55, 245, 220, 100)
    $api = [System.Drawing.RectangleF]::new(370, 245, 250, 100)
    $smb = [System.Drawing.RectangleF]::new(760, 125, 290, 110)
    $cups = [System.Drawing.RectangleF]::new(760, 380, 290, 110)
    $printer = [System.Drawing.RectangleF]::new(1250, 380, 330, 110)
    $admin = [System.Drawing.RectangleF]::new(370, 500, 250, 90)

    Draw-Box $graphics $bc $Labels.BC ([System.Drawing.Color]::FromArgb(227, 242, 253)) $boxFont
    Draw-Box $graphics $api $Labels.API ([System.Drawing.Color]::FromArgb(232, 245, 233)) $boxFont
    Draw-Box $graphics $smb $Labels.SMB ([System.Drawing.Color]::FromArgb(255, 235, 238)) $boxFont
    Draw-Box $graphics $cups $Labels.CUPS ([System.Drawing.Color]::FromArgb(232, 245, 233)) $boxFont
    Draw-Box $graphics $printer $Labels.Printers ([System.Drawing.Color]::FromArgb(224, 242, 241)) $boxFont
    Draw-Box $graphics $admin $Labels.Admin ([System.Drawing.Color]::FromArgb(245, 245, 245)) $boxFont

    Draw-Arrow $graphics ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($bc.Right, $bc.Top + $bc.Height / 2),
        [System.Drawing.PointF]::new($api.Left, $api.Top + $api.Height / 2)
    )) ([System.Drawing.Color]::FromArgb(41, 128, 185))

    Draw-Arrow $graphics ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($api.Right, $api.Top + 25),
        [System.Drawing.PointF]::new(690, $api.Top + 25),
        [System.Drawing.PointF]::new(690, $smb.Top + $smb.Height / 2),
        [System.Drawing.PointF]::new($smb.Left, $smb.Top + $smb.Height / 2)
    )) ([System.Drawing.Color]::FromArgb(192, 57, 43))
    Draw-Label $graphics $Labels.Current 645 90 $labelFont ([System.Drawing.Color]::FromArgb(192, 57, 43))

    Draw-Arrow $graphics ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($api.Right, $api.Bottom - 25),
        [System.Drawing.PointF]::new(690, $api.Bottom - 25),
        [System.Drawing.PointF]::new(690, $cups.Top + $cups.Height / 2),
        [System.Drawing.PointF]::new($cups.Left, $cups.Top + $cups.Height / 2)
    )) ([System.Drawing.Color]::FromArgb(39, 174, 96)) $true
    Draw-Label $graphics $Labels.Target 655 350 $labelFont ([System.Drawing.Color]::FromArgb(39, 174, 96))

    Draw-Arrow $graphics ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($admin.Right, $admin.Top + $admin.Height / 2),
        [System.Drawing.PointF]::new($cups.Left, $cups.Top + $cups.Height / 2)
    )) ([System.Drawing.Color]::FromArgb(127, 140, 141)) $true 3
    Draw-Label $graphics $Labels.Restricted 655 535 $labelFont ([System.Drawing.Color]::FromArgb(90, 100, 105))

    Draw-Arrow $graphics ([System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new($cups.Right, $cups.Top + $cups.Height / 2),
        [System.Drawing.PointF]::new($printer.Left, $printer.Top + $printer.Height / 2)
    )) ([System.Drawing.Color]::FromArgb(39, 174, 96))

    $directory = Split-Path -Parent $Path
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
    $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)

    $titleBrush.Dispose()
    $titleFormat.Dispose()
    $titleFont.Dispose()
    $boxFont.Dispose()
    $labelFont.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$scriptDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Join-Path (Get-Location) 'scripts' }
$root = Split-Path -Parent $scriptDirectory

Save-ReadinessDiagram `
    -Path (Join-Path $root 'RU/images/api-current-state-readiness.png') `
    -Title 'Сводная статистика — готовность' `
    -Labels @('Бизнес-сценарии REST API', 'Общие требования REST API', 'Компоненты Docker Compose', 'Инфраструктура и эксплуатация', 'Минимальная первая версия') `
    -Values @(8, 65, 40, 75, 60) `
    -TotalLabel 'Итого по четырём основным разделам' `
    -TotalValue 47

Save-PrintingDiagram `
    -Path (Join-Path $root 'RU/images/api-current-state-printing.png') `
    -Title 'Текущая и целевая схема печати' `
    -Labels @{
        BC = 'Business Central'
        API = 'API / print worker'
        SMB = 'SMB-очередь / принтер'
        CUPS = 'CUPS на отдельной VM'
        Printers = 'Принтеры в изолированном сегменте'
        Admin = 'Административные узлы'
        Current = 'Сейчас: SMB, протестировано'
        Target = 'Целевой вариант'
        Restricted = 'Ограниченный доступ'
    }

Save-ReadinessDiagram `
    -Path (Join-Path $root 'CZ/images/api-current-state-readiness.png') `
    -Title 'Souhrnná statistika — stav dokončení' `
    -Labels @('Obchodní scénáře REST API', 'Společné požadavky REST API', 'Komponenty Docker Compose', 'Infrastruktura a provoz', 'Minimální první verze') `
    -Values @(8, 65, 40, 75, 60) `
    -TotalLabel 'Celkem za čtyři hlavní oblasti' `
    -TotalValue 47

Save-PrintingDiagram `
    -Path (Join-Path $root 'CZ/images/api-current-state-printing.png') `
    -Title 'Současné a cílové řešení tisku' `
    -Labels @{
        BC = 'Business Central'
        API = 'API / print worker'
        SMB = 'SMB fronta / tiskárna'
        CUPS = 'CUPS na samostatné VM'
        Printers = 'Tiskárny v izolovaném segmentu'
        Admin = 'Administrátorské uzly'
        Current = 'Nyní: SMB, otestováno'
        Target = 'Cílová varianta'
        Restricted = 'Omezený přístup'
    }
