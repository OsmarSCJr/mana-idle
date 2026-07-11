[CmdletBinding()]
param(
    [string]$SourceUrl = "https://ebible.org/Scriptures/porbr2018_usfm.zip",
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\assets\bible")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
$workingDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("mana-idle-bible-" + [System.Guid]::NewGuid().ToString("N"))
$archivePath = Join-Path $workingDirectory "porbr2018_usfm.zip"
$sourceDirectory = Join-Path $workingDirectory "source"
$packageDirectory = Join-Path $workingDirectory "package"
$booksDirectory = Join-Path $packageDirectory "books"
$licenseUrl = "https://creativecommons.org/licenses/by/4.0/legalcode.txt"

function Invoke-Download {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    $curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($null -ne $curl) {
        & $curl.Source -L --fail --silent --show-error --output $Destination $Uri
        if ($LASTEXITCODE -ne 0) {
            throw "curl falhou ao baixar $Uri (código $LASTEXITCODE)."
        }
        return
    }

    Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing
}

function Write-Utf8File {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Content
    )

    [System.IO.File]::WriteAllText($Path, $Content, $utf8WithoutBom)
}

function ConvertFrom-InlineUsfm {
    param([AllowEmptyString()][string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return ""
    }

    # Notas de tradução (\f ... \f*) e referências cruzadas (\rq ... \rq*)
    # são material editorial, não parte do texto principal do versículo.
    $clean = [System.Text.RegularExpressions.Regex]::Replace(
        $Text,
        '\\f\s+.*?\\f\*',
        '',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $clean = [System.Text.RegularExpressions.Regex]::Replace(
        $clean,
        '\\rq\s+.*?\\rq\*',
        '',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )

    # \add marca palavras adicionadas para clareza. Mantemos as palavras e
    # removemos somente os marcadores.
    $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, '\\add\*?', '')
    $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, '\\[A-Za-z0-9]+\*?', '')
    $clean = [System.Text.RegularExpressions.Regex]::Replace($clean, '\s+', ' ')
    return $clean.Trim()
}

function Get-UsfmMarkerValue {
    param(
        [Parameter(Mandatory = $true)][string[]]$Lines,
        [Parameter(Mandatory = $true)][string]$Marker
    )

    $pattern = '^\\' + [System.Text.RegularExpressions.Regex]::Escape($Marker) + '\s+(.+?)\s*$'
    foreach ($line in $Lines) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }
    return ""
}

function Convert-UsfmBook {
    param(
        [Parameter(Mandatory = $true)][System.IO.FileInfo]$File,
        [Parameter(Mandatory = $true)][int]$Order
    )

    $lines = [System.IO.File]::ReadAllLines($File.FullName, [System.Text.Encoding]::UTF8)
    $idValue = Get-UsfmMarkerValue -Lines $lines -Marker "id"
    if ($idValue -notmatch '^([A-Z0-9]{3})\b') {
        throw "Não foi possível obter o código do livro em $($File.Name)."
    }

    $code = $Matches[1]
    $name = Get-UsfmMarkerValue -Lines $lines -Marker "h"
    $longName = Get-UsfmMarkerValue -Lines $lines -Marker "toc1"
    $shortName = Get-UsfmMarkerValue -Lines $lines -Marker "toc3"
    if ([string]::IsNullOrWhiteSpace($name)) {
        throw "Livro $code sem nome em \\h."
    }
    if ([string]::IsNullOrWhiteSpace($longName)) {
        $longName = $name
    }

    $chapters = [System.Collections.Generic.List[object]]::new()
    $currentChapter = $null
    $lastVerse = 0

    foreach ($line in $lines) {
        if ($line -match '^\\c\s+(\d+)\s*$') {
            $chapterNumber = [int]$Matches[1]
            $currentChapter = [ordered]@{
                number = $chapterNumber
                headings = [System.Collections.Generic.List[object]]::new()
                verses = [System.Collections.Generic.List[object]]::new()
            }
            $chapters.Add($currentChapter)
            $lastVerse = 0
            continue
        }

        if ($null -eq $currentChapter) {
            continue
        }

        if ($line -match '^\\d\s+(.+?)\s*$') {
            $heading = ConvertFrom-InlineUsfm $Matches[1]
            if (-not [string]::IsNullOrWhiteSpace($heading)) {
                $currentChapter.headings.Add([ordered]@{
                    before_verse = $lastVerse + 1
                    text = $heading
                })
            }
            continue
        }

        if ($line -match '^\\v\s+(\d+)\s+(.+?)\s*$') {
            $verseNumber = [int]$Matches[1]
            $verseText = ConvertFrom-InlineUsfm $Matches[2]
            if ([string]::IsNullOrWhiteSpace($verseText)) {
                throw "Versículo vazio em $code $($currentChapter.number):$verseNumber."
            }
            if ($verseNumber -le $lastVerse) {
                throw "Ordem de versículos inválida em $code $($currentChapter.number):$verseNumber."
            }

            $currentChapter.verses.Add([ordered]@{
                number = $verseNumber
                text = $verseText
            })
            $lastVerse = $verseNumber
        }
    }

    if ($chapters.Count -eq 0) {
        throw "Livro $code não contém capítulos."
    }

    $testament = if ($Order -le 39) { "old" } else { "new" }
    return [ordered]@{
        schema_version = 1
        order = $Order
        code = $code
        name = $name
        long_name = $longName
        short_name = $shortName
        testament = $testament
        chapters = $chapters
    }
}

try {
    New-Item -ItemType Directory -Path $sourceDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $booksDirectory -Force | Out-Null

    Write-Host "Baixando Bíblia Livre (USFM)..."
    Invoke-Download -Uri $SourceUrl -Destination $archivePath
    Expand-Archive -LiteralPath $archivePath -DestinationPath $sourceDirectory -Force

    $sourceFiles = @(Get-ChildItem -LiteralPath $sourceDirectory -Filter "*.usfm" -File | Sort-Object {
        if ($_.Name -match '^(\d+)-') { [int]$Matches[1] } else { [int]::MaxValue }
    })
    if ($sourceFiles.Count -ne 66) {
        throw "Esperados 66 arquivos USFM; encontrados $($sourceFiles.Count)."
    }

    $copyrightPath = Join-Path $sourceDirectory "copr.htm"
    $copyrightHtml = [System.IO.File]::ReadAllText($copyrightPath, [System.Text.Encoding]::UTF8)
    $sourceVersion = "unknown"
    if ($copyrightHtml -match 'source files dated\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})') {
        $sourceDateText = "$($Matches[1]) $($Matches[2]) $($Matches[3])"
        $sourceDate = [System.DateTime]::ParseExact(
            $sourceDateText,
            "d MMM yyyy",
            [System.Globalization.CultureInfo]::InvariantCulture
        )
        $sourceVersion = $sourceDate.ToString("yyyy-MM-dd")
    }

    $bookSummaries = [System.Collections.Generic.List[object]]::new()
    $totalChapters = 0
    $totalVerses = 0
    $bookCodeSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    for ($index = 0; $index -lt $sourceFiles.Count; $index++) {
        $order = $index + 1
        $book = Convert-UsfmBook -File $sourceFiles[$index] -Order $order
        if (-not $bookCodeSet.Add([string]$book.code)) {
            throw "Código de livro duplicado: $($book.code)."
        }

        for ($chapterIndex = 0; $chapterIndex -lt $book.chapters.Count; $chapterIndex++) {
            $expectedChapter = $chapterIndex + 1
            if ([int]$book.chapters[$chapterIndex].number -ne $expectedChapter) {
                throw "Capítulos fora de sequência em $($book.code): esperado $expectedChapter."
            }
            $totalVerses += $book.chapters[$chapterIndex].verses.Count
        }
        $totalChapters += $book.chapters.Count

        $bookFileName = "$($book.code).json"
        $bookJson = $book | ConvertTo-Json -Depth 10 -Compress
        Write-Utf8File -Path (Join-Path $booksDirectory $bookFileName) -Content $bookJson

        $bookSummaries.Add([ordered]@{
            order = $book.order
            code = $book.code
            name = $book.name
            long_name = $book.long_name
            short_name = $book.short_name
            testament = $book.testament
            chapters = $book.chapters.Count
            file = "books/$bookFileName"
        })
        Write-Host ("[{0:D2}/66] {1} ({2} capítulos)" -f $order, $book.name, $book.chapters.Count)
    }

    $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $credit = "Todas as Escrituras em português citadas são da Bíblia Livre (BLIVRE), Copyright © 2018 Diego Santos, Mario Sérgio e Marco Teles. Licença Creative Commons Atribuição 4.0. Reprodução permitida desde que devidamente mencionados fonte e autores."
    $attribution = [ordered]@{
        translation = "Bíblia Livre"
        abbreviation = "BLIVRE"
        language = "pt-BR"
        copyright = "Copyright © 2018 Diego Santos, Mario Sérgio e Marco Teles"
        version = $sourceVersion
        license = "Creative Commons Atribuição 4.0"
        license_url = "https://creativecommons.org/licenses/by/4.0/"
        source_url = "https://ebible.org/porbr2018/"
        download_url = $SourceUrl
        credit = $credit
        modified = $false
    }
    $manifest = [ordered]@{
        schema_version = 1
        id = "porbr2018"
        name = "Bíblia Livre"
        abbreviation = "BLIVRE"
        language = "pt-BR"
        source_version = $sourceVersion
        imported_at_utc = [System.DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ssZ")
        source = [ordered]@{
            format = "USFM"
            url = $SourceUrl
            archive_sha256 = $archiveHash
        }
        attribution = $attribution
        totals = [ordered]@{
            books = $bookSummaries.Count
            chapters = $totalChapters
            verses = $totalVerses
        }
        books = $bookSummaries
    }
    Write-Utf8File -Path (Join-Path $packageDirectory "manifest.json") -Content ($manifest | ConvertTo-Json -Depth 10)

    $attributionDocument = @"
# Bíblia Livre (BLIVRE) — atribuição

$credit

- Versão dos arquivos-fonte: $sourceVersion
- Fonte oficial: https://ebible.org/porbr2018/
- Projeto da tradução: http://sites.google.com/site/biblialivre/
- Licença: Creative Commons Atribuição 4.0
- Texto da licença: https://creativecommons.org/licenses/by/4.0/legalcode

O texto bíblico não foi adaptado. A conversão remove somente marcações de
formatação USFM, notas de tradução e referências cruzadas editoriais. Palavras
marcadas pelo indicador add no USFM são preservadas sem a marcação de apresentação.

O arquivo `LICENSE.txt` contém o texto legal integral da licença CC BY 4.0.
"@
    Write-Utf8File -Path (Join-Path $packageDirectory "ATTRIBUTION.md") -Content $attributionDocument

    $licensePath = Join-Path $packageDirectory "LICENSE.txt"
    Invoke-Download -Uri $licenseUrl -Destination $licensePath
    if ((Get-Item -LiteralPath $licensePath).Length -lt 5000) {
        throw "O texto da licença baixado parece incompleto."
    }

    # Validações canônicas das amostras solicitadas.
    $gen = Get-Content -LiteralPath (Join-Path $booksDirectory "GEN.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $jhn = Get-Content -LiteralPath (Join-Path $booksDirectory "JHN.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($gen.chapters.Count -ne 50 -or $gen.chapters[0].verses.Count -ne 31) {
        throw "Validação falhou para Gênesis 1."
    }
    if ($gen.chapters[0].verses[0].text -notmatch '^No princípio criou Deus') {
        throw "Texto UTF-8 de Gênesis 1:1 não corresponde ao esperado."
    }
    if ($jhn.chapters.Count -ne 21 -or $jhn.chapters[2].verses.Count -ne 36) {
        throw "Validação falhou para João 3."
    }
    if ($jhn.chapters[2].verses[15].text -notmatch '^Porque Deus amou ao mundo') {
        throw "Texto de João 3:16 não corresponde ao esperado."
    }
    if ($totalChapters -ne 1189) {
        throw "Esperados 1189 capítulos; encontrados $totalChapters."
    }

    if (Test-Path -LiteralPath $outputPath) {
        Remove-Item -LiteralPath $outputPath -Recurse -Force
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $outputPath) -Force | Out-Null
    Move-Item -LiteralPath $packageDirectory -Destination $outputPath

    Write-Host ""
    Write-Host "Importação concluída: $($bookSummaries.Count) livros, $totalChapters capítulos e $totalVerses versículos."
    Write-Host "Saída: $outputPath"
    Write-Host "Amostras validadas: Gênesis 1 e João 3."
}
finally {
    if (Test-Path -LiteralPath $workingDirectory) {
        Remove-Item -LiteralPath $workingDirectory -Recurse -Force
    }
}
