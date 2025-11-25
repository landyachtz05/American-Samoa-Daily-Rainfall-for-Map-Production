##### Calculate monthly rainfall maps #####

library(raster)
library(lubridate)
library(dplyr)
library(stringr)

# ---- Directories ----
mainDir <- Sys.getenv("PROJECT_ROOT")
inDir <- paste0(mainDir, "as_monthly_rf/")
inDir2  <- paste0(mainDir,"as_idw_rf_ras_NRT/")
outDir <- paste0(inDir,"as_monthly_map")
dir.create(outDir, showWarnings = FALSE)

# ---- Define date ----
source(paste0(mainDir, "as_dataDateFunc.R"))
dataDate <- dataDateMkr()
file_date <- dataDate
message("Processing date set to: ", dataDate)

# # Manual Date Entry
# file_date <- as.Date("2025-09-01")

# ---- List files ----
files <- list.files(inDir2, pattern = "\\.tif$", full.names = TRUE)
if (length(files) == 0) stop("No .tif files found in ", inDir)

dates <- as.Date(sub(".*_(\\d{8})\\.tif$", "\\1", basename(files)), format = "%Y%m%d")
df <- data.frame(file = files, date = dates)
df$year_month <- format(df$date, "%Y-%m")

# ---- Determine target month based on file_date ----
# Example: If file_date = 2025-09-01 → target month = 2025-08
target_month_date <- floor_date(file_date, "month") %m-% months(1)
target_month <- format(target_month_date, "%Y-%m")

message("Target month based on file_date: ", target_month)

# ---- Filter rasters to only that month ----
df <- df[df$year_month == target_month, ]

if (nrow(df) == 0) {
  stop("No rasters found for target month: ", target_month)
}

message("Found ", nrow(df), " rasters for target month: ", target_month)

# ---- Check completeness ----
expected_days <- days_in_month(as.Date(paste0(target_month, "-01")))
available_days <- nrow(df)

if (available_days < expected_days) {
  warning("⚠️ Incomplete month: expected ", expected_days, 
          " days but found ", available_days)
}

# ---- Load mask ----
mask_path <- paste0(inDir, "as_monthly_mask.tif")
if (!file.exists(mask_path)) stop("Mask file not found: ", mask_path)
mask <- raster(mask_path)

# ---- Stack and sum ----
message("Stacking ", available_days, " rasters for ", target_month, " ...")
s <- stack(df$file)
NAvalue(s) <- -9999
s[s == -9999] <- NA
month_sum <- calc(s, sum, na.rm = TRUE)

# ---- Apply mask ----
fix_mask <- values(mask) == -9999
vals <- values(month_sum)
vals[fix_mask] <- -9999
values(month_sum) <- vals

# ---- Save output ----
ym <- gsub("-", "", target_month)
out_path <- file.path(outDir, paste0("rf_sum_", ym, ".tif"))
writeRaster(month_sum, out_path, overwrite = TRUE)
message("✅ Monthly raster saved: ", out_path)

# Pau