library(stringr)

# ── Paths ──────────────────────────────────────────────────────────────────────
md_folder   <- "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1/Results/Analysis/Tables/MD Files"
html_folder <- "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1/Results/Analysis/Tables/HTML Files"
output_dir  <- "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1/Results/Analysis/Tables/Merged tables"

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ══════════════════════════════════════════════════════════════════════════════
# 1. MERGE MD FILES → merged_tables.md
# ══════════════════════════════════════════════════════════════════════════════
md_files <- list.files(md_folder, pattern = "\\.md$",
                       recursive = TRUE, full.names = TRUE)

md_out <- file.path(output_dir, "merged_tables.md")
sink(md_out)
for (f in md_files) {
  label <- tools::toTitleCase(gsub("_", " ", tools::file_path_sans_ext(basename(f))))
  cat("# ", label, "\n\n", sep = "")
  cat(paste(readLines(f, warn = FALSE), collapse = "\n"), "\n\n")
  cat("---\n\n")
}
sink()
cat("✅ MD merged →", md_out, "\n")

# ══════════════════════════════════════════════════════════════════════════════
# Helper: extract <body> content — R-safe, no variable-length lookbehind
# ══════════════════════════════════════════════════════════════════════════════
extract_body <- function(html_text) {
  after_open <- strsplit(html_text, "<[Bb][Oo][Dd][Yy][^>]*>")[[1]]
  if (length(after_open) < 2) return(html_text)
  before_close <- strsplit(after_open[2], "</[Bb][Oo][Dd][Yy]>")[[1]][1]
  trimws(before_close)
}

extract_head <- function(html_text) {
  after_open  <- strsplit(html_text, "<[Hh][Ee][Aa][Dd][^>]*>")[[1]]
  if (length(after_open) < 2) return("")
  before_close <- strsplit(after_open[2], "</[Hh][Ee][Aa][Dd]>")[[1]][1]
  trimws(before_close)
}

# ══════════════════════════════════════════════════════════════════════════════
# 2. MERGE HTML FILES → merged_tables.html
# ══════════════════════════════════════════════════════════════════════════════
html_files <- list.files(html_folder, pattern = "\\.html$",
                         recursive = TRUE, full.names = TRUE)

first_raw           <- paste(readLines(html_files[1], warn = FALSE), collapse = "\n")
shared_head_content <- extract_head(first_raw)

wrapper_css <- "
<style>
  .table-block       { margin-bottom: 56px; }
  .table-block-title { font-size: 11pt; font-style: italic;
                       font-weight: 600; margin-bottom: 6px; }
  hr.table-sep       { border: none; border-top: 1px solid #ccc; margin: 48px 0; }
  h1.doc-title       { margin-bottom: 40px; }
</style>
"

html_out_parts <- c(
  "<!DOCTYPE html>",
  "<html lang='en'>",
  "<head>",
  "  <meta charset='UTF-8'>",
  shared_head_content,
  wrapper_css,
  "</head>",
  "<body>",
  "<h1 class='doc-title'>Results — Merged Tables</h1>"
)

for (i in seq_along(html_files)) {
  f     <- html_files[i]
  label <- tools::toTitleCase(gsub("_", " ", tools::file_path_sans_ext(basename(f))))
  raw   <- paste(readLines(f, warn = FALSE), collapse = "\n")
  body  <- extract_body(raw)

  html_out_parts <- c(
    html_out_parts,
    "<div class='table-block'>",
    paste0("  <div class='table-block-title'>", label, "</div>"),
    body,
    "</div>",
    if (i < length(html_files)) "<hr class='table-sep'>" else ""
  )
}

html_out_parts <- c(html_out_parts, "</body></html>")

html_out <- file.path(output_dir, "merged_tables.html")
writeLines(html_out_parts, html_out)
cat("✅ HTML merged →", html_out, "\n")

# ══════════════════════════════════════════════════════════════════════════════
# 3. HTML → DOCX via pandoc — Times New Roman, black, 11pt
# ══════════════════════════════════════════════════════════════════════════════
docx_out    <- file.path(output_dir, "merged_tables.docx")
html_styled <- file.path(output_dir, "_temp_styled.html")

pandoc_path <- tryCatch(rmarkdown::find_pandoc()$dir, error = function(e) "")
pandoc_bin  <- if (!is.null(pandoc_path) && nchar(pandoc_path) > 0) {
  file.path(pandoc_path, "pandoc")
} else {
  "pandoc"
}

# ── Step 3a: inject styles — explicit 11pt on all elements including tables ──
html_raw <- paste(readLines(html_out, warn = FALSE), collapse = "\n")

style_injection <- '
<style>
  body, body * {
    font-family: "Times New Roman", Times, serif !important;
    font-size: 11pt !important;
    color: #000000 !important;
  }
  p, li, div, span, h1, h2, h3, h4, h5, h6 {
    font-family: "Times New Roman", Times, serif !important;
    font-size: 11pt !important;
    color: #000000 !important;
  }
  table, tr, td, th, thead, tbody, tfoot {
    font-family: "Times New Roman", Times, serif !important;
    font-size: 11pt !important;
    color: #000000 !important;
  }
</style>
'

html_patched <- sub("</head>", paste0(style_injection, "\n</head>"), html_raw,
                    ignore.case = TRUE)
writeLines(html_patched, html_styled)

# ── Step 3b: Lua filter — stamp Times New Roman 11pt on every text run ───────
lua_filter <- file.path(output_dir, "_font_filter.lua")

writeLines('
local font_name = "Times New Roman"
local font_size = 11

function Meta(meta)
  return meta
end

function Span(el)
  el.attributes["style"] = string.format(
    "font-family: %s; font-size: %dpt; color: #000000;", font_name, font_size)
  return el
end

function Para(el)
  return el
end

function Str(el)
  return pandoc.Span(
    pandoc.Str(el.text),
    pandoc.Attr("", {}, {
      ["style"] = string.format(
        "font-family: %s; font-size: %dpt; color: #000000;",
        font_name, font_size)
    })
  )
end
', lua_filter)

# ── Step 3c: build reference.docx — two-pass approach ────────────────────────
ref_docx     <- file.path(output_dir, "_reference.docx")
ref_docx_tmp <- file.path(output_dir, "_reference_tmp.docx")

if (!requireNamespace("officer",  quietly = TRUE)) install.packages("officer")
if (!requireNamespace("zip",      quietly = TRUE)) install.packages("zip")
library(officer)
library(zip)

# Pass 1: let pandoc generate a docx first — this creates all styles
# (Normal, Table Grid, etc.) that pandoc actually uses
cmd_pass1 <- paste0(
  '"', pandoc_bin, '" ',
  '"', html_styled, '" ',
  '-f html -t docx --standalone ',
  '-o "', ref_docx_tmp, '"'
)
system(cmd_pass1)

# Unzip the pandoc-generated docx to patch its styles.xml
unzip_dir <- file.path(output_dir, "_ref_unzipped")
unlink(unzip_dir, recursive = TRUE)
dir.create(unzip_dir)
zip::unzip(ref_docx_tmp, exdir = unzip_dir)

styles_xml_path <- file.path(unzip_dir, "word", "styles.xml")
styles_xml      <- paste(readLines(styles_xml_path, warn = FALSE), collapse = "\n")

# Shared rPr block — 11pt (half-points: 22), Times New Roman, black
font_rpr <- paste0(
  '<w:rPr>',
  '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" ',
  'w:cs="Times New Roman" w:eastAsia="Times New Roman"/>',
  '<w:sz w:val="22"/><w:szCs w:val="22"/>',
  '<w:color w:val="000000"/>',
  '</w:rPr>'
)

# ── Patch 1: w:docDefaults → document-wide 11pt default ──────────────────────
default_rpr <- paste0(
  '<w:rPrDefault>',
  '<w:rPr>',
  '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" ',
  'w:cs="Times New Roman" w:eastAsia="Times New Roman"/>',
  '<w:sz w:val="22"/><w:szCs w:val="22"/>',
  '<w:color w:val="000000"/>',
  '</w:rPr>',
  '</w:rPrDefault>'
)

if (grepl("<w:rPrDefault>", styles_xml)) {
  styles_xml <- gsub(
    "<w:rPrDefault>.*?</w:rPrDefault>",
    default_rpr,
    styles_xml, perl = TRUE
  )
} else {
  styles_xml <- sub(
    "</w:pPrDefault>",
    paste0("</w:pPrDefault>", default_rpr),
    styles_xml, fixed = TRUE
  )
}

# ── Helper: patch a single named style block ──────────────────────────────────
patch_style <- function(xml, style_id, rpr_block) {
  pattern <- paste0('<w:style[^>]*w:styleId="', style_id, '"[^>]*>.*?</w:style>')
  m       <- regmatches(xml, regexpr(pattern, xml, perl = TRUE))

  if (length(m) != 1) {
    message("Style not found, skipping: ", style_id)
    return(xml)
  }

  original <- m[1]
  patched  <- if (grepl("<w:rPr>", original)) {
    gsub("<w:rPr>.*?</w:rPr>", rpr_block, original, perl = TRUE)
  } else {
    sub("(</w:name>)", paste0("\\1", rpr_block), original, perl = TRUE)
  }

  sub(original, patched, xml, fixed = TRUE)
}

# ── Patch 2: detect and patch all styles present in this docx ─────────────────
# Extract every styleId actually present so we don't guess
all_style_ids <- regmatches(
  styles_xml,
  gregexpr('(?<=w:styleId=")[^"]+', styles_xml, perl = TRUE)
)[[1]]

cat("Styles found in reference docx:\n")
cat(paste(" -", all_style_ids), sep = "\n")
cat("\n")

# Patch Normal + any table-related style that actually exists
target_styles <- c("Normal",
                   all_style_ids[grepl("(?i)table", all_style_ids)])

for (sid in target_styles) {
  styles_xml <- patch_style(styles_xml, sid, font_rpr)
}

writeLines(styles_xml, styles_xml_path)

# Repack as reference.docx using zip::zip (avoids "zip not found" on Windows)
files_rel <- list.files(unzip_dir, recursive = TRUE)
old_wd    <- getwd()
setwd(unzip_dir)
zip::zip(ref_docx, files_rel)
setwd(old_wd)
unlink(unzip_dir, recursive = TRUE)
file.remove(ref_docx_tmp)

# ── Step 3d: pass 2 — run pandoc with the patched reference doc ──────────────
cmd <- paste0(
  '"', pandoc_bin, '" ',
  '"', html_styled, '" ',
  '-f html -t docx --standalone ',
  '--lua-filter="', lua_filter, '" ',
  '--reference-doc="', ref_docx, '" ',
  '-o "', docx_out, '"'
)

exit <- system(cmd)

if (exit == 0 && file.exists(docx_out)) {
  cat("✅ DOCX exported →", docx_out, "\n")
} else {
  cat("⚠️  pandoc step failed. Pandoc at:", pandoc_bin, "\n")
  cat("   Manual command:\n  ", cmd, "\n")
}

# ── Cleanup ───────────────────────────────────────────────────────────────────
file.remove(html_styled)
file.remove(ref_docx)
file.remove(lua_filter)

cat("\n🎉 Done! Files in:\n  ", output_dir, "\n")