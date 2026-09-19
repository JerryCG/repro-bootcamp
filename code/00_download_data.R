# ------------------------------------------------------------------
# 00_download_data.R
# Purpose: Download the three raw data sources into data/raw/, untouched
#          (V-Dem: a documented column subset), and record where each
#          file came from. Idempotent: a file that already exists is
#          never downloaded again, and then the network is not used.
# Inputs:  none (the internet, see SOURCES below)
# Outputs: data/raw/vdem.csv      V-Dem v16 column subset, 1990-2025
#          data/raw/ucdp_acd.csv  UCDP/PRIO Armed Conflict Dataset 26.1
#          data/raw/wdi.csv       World Bank WDI 2000-2024, aggregates
#                                 still included (01-04 clean them)
#          data/raw/SOURCES.txt   URL used, timestamp, MD5 per file
# Author:  Hennes Barnehl
# Date:    2026-09-18
#
# SOURCES (each has a fallback: a snapshot on our GitHub release)
#   V-Dem   v-dem.net only offers the data behind a web form, so there is
#           no script-friendly original. We take the small extract from
#           the release first (0.4 MB); if that fails we rebuild it from
#           the full V-Dem file (34 MB) that the V-Dem team publishes in
#           the vdemdata GitHub repo (pinned commit). Same result either
#           way (checked by MD5). Recipe: code/extra/make_vdem_extract.R.
#   UCDP    original: ucdp.uu.se zip; fallback: release snapshot.
#   WDI     original: World Bank API via the WDI package; fallback:
#           release snapshot. (The API can return revised numbers later,
#           the snapshot is what the class numbers were computed on.)
#
# Testing hooks (not needed in normal use):
#   REPRO_RELEASE_BASE=<url or file:// dir>  where snapshots are fetched
#   REPRO_BREAK_ORIGINAL=1                   pretend all originals fail
# ------------------------------------------------------------------

# 1. Setup ------------------------------------------------------------
library(here)
options(timeout = 600)  # seconds; the V-Dem fallback file is 34 MB

raw_dir <- here("data", "raw")
dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

release_base <- Sys.getenv(
  "REPRO_RELEASE_BASE",
  "https://github.com/hbarnehl/repro-bootcamp/releases/download/data-v1"
)
break_original <- nzchar(Sys.getenv("REPRO_BREAK_ORIGINAL"))

sources_file <- file.path(raw_dir, "SOURCES.txt")
sources_header <- c(
  "# Provenance of data/raw/ (written by code/00_download_data.R)",
  "# Columns: file | source used | timestamp | MD5",
  "#",
  "# V-Dem v16: extract of the V-Dem Country-Year (Full+Others) dataset,",
  "#   columns country_name, country_text_id, country_id, COWcode, year,",
  "#   v2smgovfilprc, v2smgovshut, v2smgovsmcenprc, v2mecenefi, v2x_regime,",
  "#   v2x_polyarchy; years >= 1990. Licence CC BY-SA 4.0 (this extract too).",
  "#   Coppedge et al. 2026, V-Dem Country-Year Dataset v16, Varieties of",
  "#   Democracy (V-Dem) Project, https://doi.org/10.23696/vdemds26",
  "# UCDP/PRIO Armed Conflict Dataset 26.1. Licence CC BY 4.0.",
  "#   Davies, Pettersson & Oberg 2026, Journal of Peace Research 63(4),",
  "#   https://doi.org/10.1093/jopres/xjag046; Gleditsch et al. 2002, JPR 39(5).",
  "#   UCDP is part of and funded by DEMSCORE, national research infrastructure",
  "#   grant 2021-00162 from the Swedish Research Council.",
  "# World Bank, World Development Indicators (NY.GDP.PCAP.KD, IT.NET.USER.ZS,",
  "#   SP.POP.TOTL). Licence: CC BY 4.0 (World Bank open data default).",
  "#"
)

# 2. Helpers ----------------------------------------------------------
record_source <- function(file, source_label) {
  # One line per file; a re-download replaces the old line.
  lines <- if (file.exists(sources_file)) readLines(sources_file) else sources_header
  lines <- lines[!startsWith(lines, paste0(file, " | "))]
  md5 <- unname(tools::md5sum(file.path(raw_dir, file)))
  new_line <- paste(file, source_label, format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
                    md5, sep = " | ")
  writeLines(c(lines, new_line), sources_file)
}

# Try each source in order until one produces a non-empty file.
# `sources` is a named list: name = label for SOURCES.txt, value = function
# that takes a destination path and writes the file there.
fetch <- function(file, sources) {
  target <- file.path(raw_dir, file)
  if (file.exists(target)) {
    message("[skip] ", file, " already exists (", format_size(target), ")")
    return(invisible(TRUE))
  }
  for (label in names(sources)) {
    message("[try ] ", file, " <- ", label)
    tmp <- tempfile(fileext = ".tmp")
    ok <- tryCatch({
      sources[[label]](tmp)
      file.exists(tmp) && file.size(tmp) > 0
    }, error = function(e) { message("       failed: ", conditionMessage(e)); FALSE },
       warning = function(w) { message("       failed: ", conditionMessage(w)); FALSE })
    if (ok) {
      file.copy(tmp, target)
      record_source(file, label)
      message("[ ok ] ", file, " (", format_size(target), ")")
      return(invisible(TRUE))
    }
  }
  stop("Could not obtain ", file, " from any source. ",
       "Check your internet connection and try again.", call. = FALSE)
}

format_size <- function(path) format(structure(file.size(path), class = "object_size"),
                                     units = "auto")

download <- function(url, dest) {
  utils::download.file(url, dest, mode = "wb", quiet = TRUE)
}

original_url <- function(url) if (break_original) "https://invalid.invalid/broken" else url

release_source <- function(file) {
  url <- paste0(release_base, "/", file)
  setNames(list(function(dest) download(url, dest)),
           paste0("release snapshot: ", url))
}

# 3. V-Dem ------------------------------------------------------------
vdem_pinned_url <- paste0(
  "https://raw.githubusercontent.com/vdeminstitute/vdemdata/",
  "f4dd26922e658442524dfd954bf14f7ebe622d5d/data/vdem.RData"  # commit "v16 release"
)
vdem_pinned_md5 <- "cbba9b613f5fc0478255932bbf67fcca"

# Same recipe as code/extra/make_vdem_extract.R (keep the two in sync).
vdem_from_original <- function(dest) {
  rdata <- tempfile(fileext = ".RData")
  download(original_url(vdem_pinned_url), rdata)
  if (unname(tools::md5sum(rdata)) != vdem_pinned_md5)
    message("       note: V-Dem RData MD5 differs from the pinned file")
  e <- new.env()
  load(rdata, envir = e)
  keep <- c("country_name", "country_text_id", "country_id", "COWcode", "year",
            "v2smgovfilprc", "v2smgovshut", "v2smgovsmcenprc", "v2mecenefi",
            "v2x_regime", "v2x_polyarchy")
  extract <- e$vdem[e$vdem$year >= 1990, keep]
  utils::write.csv(extract, dest, row.names = FALSE, na = "")
}

fetch("vdem.csv", c(
  release_source("vdem.csv"),
  list("original: vdemdata GitHub v16 (pinned commit), subset to 11 columns" = vdem_from_original)
))

# 4. UCDP/PRIO Armed Conflict Dataset ---------------------------------
ucdp_url <- "https://ucdp.uu.se/downloads/ucdpprio/ucdp-prio-acd-261-csv.zip"

ucdp_from_original <- function(dest) {
  zip <- tempfile(fileext = ".zip")
  download(original_url(ucdp_url), zip)
  csv <- utils::unzip(zip, exdir = tempdir())
  csv <- csv[grepl("\\.csv$", csv)]
  stopifnot(length(csv) == 1)
  file.copy(csv, dest, overwrite = TRUE)
}

fetch("ucdp_acd.csv", c(
  setNames(list(ucdp_from_original), paste0("original: ", ucdp_url)),
  release_source("ucdp_acd.csv")
))

# 5. World Bank WDI ---------------------------------------------------
# Aggregates ("World", "Euro area", ...) are deliberately left in.
wdi_from_original <- function(dest) {
  if (break_original) stop("original source disabled (REPRO_BREAK_ORIGINAL)")
  wdi <- WDI::WDI(country = "all",
                  indicator = c("NY.GDP.PCAP.KD", "IT.NET.USER.ZS", "SP.POP.TOTL"),
                  start = 2000, end = 2024, extra = TRUE)
  # na = "": empty cell = missing. (Namibia's ISO2 code is the string "NA".)
  utils::write.csv(wdi, dest, row.names = FALSE, na = "")
}

fetch("wdi.csv", c(
  "original: World Bank API via WDI::WDI(), 2000-2024, extra = TRUE" = wdi_from_original,
  release_source("wdi.csv")
))

# 6. Report -----------------------------------------------------------
message("\nFiles in data/raw/:")
for (f in c("vdem.csv", "ucdp_acd.csv", "wdi.csv", "SOURCES.txt")) {
  if (file.exists(file.path(raw_dir, f)))
    message(sprintf("  %-14s %s", f, format_size(file.path(raw_dir, f))))
}
message("00_download_data.R: all raw data present. Provenance: data/raw/SOURCES.txt")
