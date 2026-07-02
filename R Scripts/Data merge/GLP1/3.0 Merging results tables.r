# =============================================================================
# postpartum-glp1: Merge tables (MD + HTML + DOCX)
# -----------------------------------------------------------------------------
# Combines all per-table outputs into a single MD, a single HTML, and a single
# DOCX (Times New Roman 11pt black throughout). Cross-platform: auto-detects
# the right project root for the active machine.
# =============================================================================

library(stringr)

# --- OS-aware paths -----------------------------------------------------------
sys_name  <- Sys.info()[["sysname"]]
proj_root <- if (sys_name == "Darwin") {
  "/Users/alfredoverastegui/Desktop/Research/VS Code Workbook/MDH Lab/postpartum-glp1"
} else {
  "C:/Users/m320532/Desktop/Research/VS Code Projects/postpartum-glp1"
}

md_folder   <- file.path(proj_root, "Results", "Analysis", "Tables", "MD Files")
html_folder <- file.path(proj_root, "Results", "Analysis", "Tables", "HTML Files")
output_dir  <- file.path(proj_root, "Results", "Analysis", "Tables", "Merged tables")
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# =============================================================================
# Ordering function — sorts files into manuscript order regardless of OS
# alphabetical default. Files not matched fall to the end alphabetically.
# =============================================================================
manuscript_order <- function(files) {
  base <- tools::file_path_sans_ext(basename(files))

  key <- vapply(base, function(b) {
    bl <- tolower(b)
    if      (grepl("^consort",                    bl)) "00_consort"
    else if (grepl("^table1_overall",             bl)) "10_table1_a"
    else if (grepl("^table1",                     bl)) "10_table1_b"
    else if (grepl("^table2_overall",                    bl)) "20_table2_a"
    else if (grepl("^table2_by_timing",                  bl)) "20_table2_b"
    else if (grepl("^table2_by_bp_140",                  bl)) "20_table2_c"
    else if (grepl("^table2_combined_timing_bp_140_90",  bl)) "20_table2_d"
    else if (grepl("^table2",                            bl)) "20_table2_e"
    else if (grepl("^table3",                     bl)) "30_table3"
    else if (grepl("^table4",                     bl)) "40_table4"
    else if (grepl("^figure_km",                  bl)) "45_figure_km"       # ← new
    else if (grepl("^main_multivariable_cox",     bl)) "50_main_cox"        # ← new
    else if (grepl("^suppl_univariate_cox",       bl)) "60_suppl_cox"       # ← new
    else if (grepl("^supp_table3",                bl)) "70_supp3"
    else if (grepl("^supp_table4",                bl)) "80_supp4"
    else if (grepl("^supp",                       bl)) paste0("90_supp_", bl)
    else paste0("99_", bl)
  }, character(1))

  files[order(key)]
}

# --- Inventory diagnostics ---------------------------------------------------
md_files_raw   <- list.files(md_folder,   pattern = "\\.md$",   recursive = TRUE, full.names = TRUE)
html_files_raw <- list.files(html_folder, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)

md_base   <- tools::file_path_sans_ext(basename(md_files_raw))
html_base <- tools::file_path_sans_ext(basename(html_files_raw))

only_md   <- setdiff(md_base,   html_base)
only_html <- setdiff(html_base, md_base)

if (length(only_md))   cat("Note: MD-only (no HTML twin):   ", paste(only_md,   collapse = ", "), "\n")
if (length(only_html)) cat("Note: HTML-only (no MD twin):   ", paste(only_html, collapse = ", "), "\n")
cat("\n")

md_files   <- manuscript_order(md_files_raw)
html_files <- manuscript_order(html_files_raw)

# Pretty label from filename: "table1_by_timing_2cat" -> "Table 1 - By Timing 2cat"
pretty_label <- function(filename) {
  base <- tools::file_path_sans_ext(basename(filename))
  base <- sub("^table2_by_timing", "Table 2 - By Early Vs Late GLP-1 Timing", base)
  base <- sub("^table2_combined_timing_bp_140_90", "Table 2 - Combined Timing And 140 90 BP", base)
  base <- sub("^table([0-9]+)_",             "Table \\1 - ",        base)
  base <- sub("^supp_table([0-9]+)_",        "Supp Table \\1 - ",   base)
  base <- sub("^consort_",                   "CONSORT - ",           base)
  base <- sub("^figure_km_",                 "Figure KM - ",         base)   # ← new
  base <- sub("^main_multivariable_cox_",    "Main Cox (MV) - ",     base)   # ← new
  base <- sub("^suppl_univariate_cox_",      "Suppl Cox (UV) - ",    base)   # ← new
  tools::toTitleCase(gsub("_", " ", base))
}

# =============================================================================
# 1. MERGE MD FILES -> merged_tables.md
# =============================================================================
md_out <- file.path(output_dir, "merged_tables.md")
sink(md_out)
for (f in md_files) {
  cat("# ", pretty_label(f), "\n\n", sep = "")
  cat(paste(readLines(f, warn = FALSE), collapse = "\n"), "\n\n")
  cat("---\n\n")
}
sink()
cat("MD merged   ->", md_out, "\n")

# =============================================================================
# Helpers: extract <body> / <head> content (R-safe, no var-len lookbehind)
# =============================================================================
extract_body <- function(html_text) {
  after_open <- strsplit(html_text, "<[Bb][Oo][Dd][Yy][^>]*>")[[1]]
  if (length(after_open) < 2) return(html_text)
  trimws(strsplit(after_open[2], "</[Bb][Oo][Dd][Yy]>")[[1]][1])
}
extract_head <- function(html_text) {
  after_open <- strsplit(html_text, "<[Hh][Ee][Aa][Dd][^>]*>")[[1]]
  if (length(after_open) < 2) return("")
  trimws(strsplit(after_open[2], "</[Hh][Ee][Aa][Dd]>")[[1]][1])
}

# =============================================================================
# 2. MERGE HTML FILES -> merged_tables.html
# =============================================================================
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
  "<!DOCTYPE html>", "<html lang='en'>", "<head>",
  "  <meta charset='UTF-8'>",
  shared_head_content, wrapper_css,
  "</head>", "<body>",
  "<h1 class='doc-title'>Results - Merged Tables</h1>"
)

for (i in seq_along(html_files)) {
  f    <- html_files[i]
  raw  <- paste(readLines(f, warn = FALSE), collapse = "\n")
  body <- extract_body(raw)
  html_out_parts <- c(
    html_out_parts,
    "<div class='table-block'>",
    paste0("  <div class='table-block-title'>", pretty_label(f), "</div>"),
    body, "</div>",
    if (i < length(html_files)) "<hr class='table-sep'>" else ""
  )
}
html_out_parts <- c(html_out_parts, "</body></html>")

html_out <- file.path(output_dir, "merged_tables.html")
writeLines(html_out_parts, html_out)
cat("HTML merged ->", html_out, "\n")

# =============================================================================
# 3. HTML -> DOCX via pandoc - Times New Roman, black, 11pt
# =============================================================================
docx_out    <- file.path(output_dir, "merged_tables.docx")
html_styled <- file.path(output_dir, "_temp_styled.html")

pandoc_path <- tryCatch(rmarkdown::find_pandoc()$dir, error = function(e) "")
pandoc_bin  <- if (!is.null(pandoc_path) && nchar(pandoc_path) > 0)
                  file.path(pandoc_path, "pandoc") else "pandoc"

# 3a. inject Times New Roman / 11pt / black into the HTML head
html_raw <- paste(readLines(html_out, warn = FALSE), collapse = "\n")
style_injection <- '
<style>
  body, body * {
    font-family: "Times New Roman", Times, serif !important;
    font-size: 11pt !important;
    color: #000000 !important;
  }
  p, li, div, span, h1, h2, h3, h4, h5, h6,
  table, tr, td, th, thead, tbody, tfoot {
    font-family: "Times New Roman", Times, serif !important;
    font-size: 11pt !important;
    color: #000000 !important;
  }
</style>
'
writeLines(sub("</head>", paste0(style_injection, "\n</head>"),
               html_raw, ignore.case = TRUE), html_styled)

# 3b. Lua filter - stamp Times New Roman 11pt on every text run
lua_filter <- file.path(output_dir, "_font_filter.lua")
writeLines('
local font_name = "Times New Roman"
local font_size = 11

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

# 3c. Two-pass reference docx
if (!requireNamespace("officer", quietly = TRUE)) install.packages("officer")
if (!requireNamespace("zip",     quietly = TRUE)) install.packages("zip")
suppressPackageStartupMessages({ library(officer); library(zip) })

ref_docx     <- file.path(output_dir, "_reference.docx")
ref_docx_tmp <- file.path(output_dir, "_reference_tmp.docx")

cmd_pass1 <- paste0('"', pandoc_bin, '" "', html_styled, '" ',
                    '-f html -t docx --standalone -o "', ref_docx_tmp, '"')
system(cmd_pass1)

unzip_dir <- file.path(output_dir, "_ref_unzipped")
unlink(unzip_dir, recursive = TRUE); dir.create(unzip_dir)
zip::unzip(ref_docx_tmp, exdir = unzip_dir)

styles_xml_path <- file.path(unzip_dir, "word", "styles.xml")
styles_xml      <- paste(readLines(styles_xml_path, warn = FALSE), collapse = "\n")

font_rpr <- paste0(
  '<w:rPr>',
  '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" ',
  'w:cs="Times New Roman" w:eastAsia="Times New Roman"/>',
  '<w:sz w:val="22"/><w:szCs w:val="22"/><w:color w:val="000000"/>',
  '</w:rPr>'
)
default_rpr <- paste0(
  '<w:rPrDefault>',
  '<w:rPr>',
  '<w:rFonts w:ascii="Times New Roman" w:hAnsi="Times New Roman" ',
  'w:cs="Times New Roman" w:eastAsia="Times New Roman"/>',
  '<w:sz w:val="22"/><w:szCs w:val="22"/><w:color w:val="000000"/>',
  '</w:rPr>',
  '</w:rPrDefault>'
)

if (grepl("<w:rPrDefault>", styles_xml)) {
  styles_xml <- gsub("<w:rPrDefault>.*?</w:rPrDefault>",
                     default_rpr, styles_xml, perl = TRUE)
} else {
  styles_xml <- sub("</w:pPrDefault>",
                    paste0("</w:pPrDefault>", default_rpr),
                    styles_xml, fixed = TRUE)
}

patch_style <- function(xml, style_id, rpr_block) {
  pattern <- paste0('<w:style[^>]*w:styleId="', style_id, '"[^>]*>.*?</w:style>')
  m <- regmatches(xml, regexpr(pattern, xml, perl = TRUE))
  if (length(m) != 1) { message("Style not found, skipping: ", style_id); return(xml) }
  original <- m[1]
  patched <- if (grepl("<w:rPr>", original)) {
    gsub("<w:rPr>.*?</w:rPr>", rpr_block, original, perl = TRUE)
  } else {
    sub("(</w:name>)", paste0("\\1", rpr_block), original, perl = TRUE)
  }
  sub(original, patched, xml, fixed = TRUE)
}

all_style_ids <- regmatches(styles_xml,
  gregexpr('(?<=w:styleId=")[^"]+', styles_xml, perl = TRUE))[[1]]
cat("Styles found in reference docx:\n"); cat(paste(" -", all_style_ids), sep = "\n"); cat("\n")

for (sid in c("Normal", all_style_ids[grepl("(?i)table", all_style_ids)])) {
  styles_xml <- patch_style(styles_xml, sid, font_rpr)
}

writeLines(styles_xml, styles_xml_path)

files_rel <- list.files(unzip_dir, recursive = TRUE)
old_wd <- getwd(); setwd(unzip_dir)
zip::zip(ref_docx, files_rel)
setwd(old_wd); unlink(unzip_dir, recursive = TRUE); file.remove(ref_docx_tmp)

# 3d. Final pandoc pass with patched reference doc
cmd <- paste0('"', pandoc_bin, '" "', html_styled, '" ',
              '-f html -t docx --standalone ',
              '--lua-filter="', lua_filter, '" ',
              '--reference-doc="', ref_docx, '" ',
              '-o "', docx_out, '"')
exit <- system(cmd)

if (exit == 0 && file.exists(docx_out)) {
  cat("DOCX exported ->", docx_out, "\n")
} else {
  cat("pandoc step failed. Pandoc at:", pandoc_bin, "\n")
  cat("Manual command:\n  ", cmd, "\n")
}

# Cleanup
file.remove(html_styled); file.remove(ref_docx); file.remove(lua_filter)

cat("\nDone. Files in:\n  ", output_dir, "\n")
cat("\nMerged order:\n")
cat(paste0("  ", seq_along(md_files), ". ", basename(md_files)), sep = "\n")