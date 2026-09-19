# ------------------------------------------------------------------
# make_vdem_extract.R   (NOT run by run_all.R)
# Purpose: Document exactly how data/raw/vdem.csv was made from the full
#          V-Dem dataset. The full file has 4,618 columns and 28,092 rows
#          (34 MB as .RData); the project needs 11 columns and years >= 1990
#          (6,383 rows, ~0.4 MB). The web download at v-dem.net sits behind a
#          form, so we use the same v16 data file that the V-Dem team
#          publishes in the vdemdata GitHub repository.
# Inputs:  vdem.RData from vdeminstitute/vdemdata, pinned to the commit
#          "v16 release" (2026-03-17); MD5 cbba9b613f5fc0478255932bbf67fcca
# Outputs: data/raw/vdem.csv  (also uploaded as release asset data-v1)
# Author:  Hennes Barnehl
# Date:    2026-09-18
#
# Licence: V-Dem data are CC BY-SA 4.0. The extract is therefore also
# CC BY-SA 4.0. Cite: Coppedge, Gerring, Knutsen, Lindberg, Teorell et al.
# 2026. "V-Dem Country-Year Dataset v16". Varieties of Democracy (V-Dem)
# Project. https://doi.org/10.23696/vdemds26
#
# Note: `v2smgovshut` (government Internet shut down in practice) is the
# correct v16 name; the plan's earlier `v2smgovshutprc` does not exist.
# Usage: Rscript code/extra/make_vdem_extract.R [output.csv]
# ------------------------------------------------------------------

library(here)

args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args) >= 1) args[1] else here("data", "raw", "vdem.csv")

# 1. Download the full file (pinned commit) ---------------------------
url <- paste0("https://raw.githubusercontent.com/vdeminstitute/vdemdata/",
              "f4dd26922e658442524dfd954bf14f7ebe622d5d/data/vdem.RData")
rdata <- tempfile(fileext = ".RData")
options(timeout = 600)
download.file(url, rdata, mode = "wb")
stopifnot(unname(tools::md5sum(rdata)) == "cbba9b613f5fc0478255932bbf67fcca")

# 2. Subset columns and years -----------------------------------------
e <- new.env()
load(rdata, envir = e)  # creates the data frame `vdem`

keep <- c(
  # identifiers
  "country_name", "country_text_id", "country_id", "COWcode", "year",
  # four censorship measures (all coded higher = LESS censorship in V-Dem;
  # 01_clean_vdem.R reverses them)
  "v2smgovfilprc", "v2smgovshut", "v2smgovsmcenprc", "v2mecenefi",
  # regime type and electoral democracy index
  "v2x_regime", "v2x_polyarchy"
)
extract <- e$vdem[e$vdem$year >= 1990, keep]

# 3. Write (empty cell = missing) -------------------------------------
write.csv(extract, out_file, row.names = FALSE, na = "")
message("Wrote ", out_file, ": ", nrow(extract), " rows x ", ncol(extract),
        " cols, MD5 ", unname(tools::md5sum(out_file)))
