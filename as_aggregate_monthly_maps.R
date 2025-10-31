##### Calculate monthly rainfall maps #####

library(raster)
library(lubridate)
library(dplyr)
library(stringr)

# ---- Directories ----
mainDir <- Sys.getenv("PROJECT_ROOT")
inDir  <- paste0(mainDir,"as_idw_rf_ras_NRT_month")
inDir2 <- paste0(mainDir,"as_static_files")
outDir <- paste0(mainDir,"as_monthly_map")
dir.create(outDir, showWarnings = FALSE)

# ---- Define date ----
source(paste0(mainDir, "/as_dataDateFunc.R"))
dataDate <- dataDateMkr()
file_date <- dataDate
message("Processing date set to: ", dataDate)

# ---- List files ----
files <- list.files(inDir, pattern = "\\.tif$", full.names = TRUE)
if (length(files) == 0) stop("No .tif files found in ", inDir)

dates <- as.Date(sub(".*_(\\d{8})\\.tif$", "\\1", basename(files)), format = "%Y%m%d")
df <- data.frame(file = files, date = dates)
df$year_month <- format(df$date, "%Y-%m")

# Expect only one unique month in the folder
unique_months <- unique(df$year_month)
if (length(unique_months) != 1) {
  stop("Expected 1 month of rasters in folder, found ", length(unique_months), 
       ": ", paste(unique_months, collapse = ", "))
}
target_month <- unique_months
message("Target month detected: ", target_month)

# ---- Check completeness ----
expected_days <- days_in_month(as.Date(paste0(target_month, "-01")))
available_days <- nrow(df)

if (available_days < expected_days) {
  warning("⚠️ Incomplete month: expected ", expected_days, 
          " days but found ", available_days)
}

# ---- Load mask ----
mask_path <- paste0(inDir2, "/as_monthly_mask.tif")
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