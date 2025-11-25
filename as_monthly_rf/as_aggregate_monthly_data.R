###### Incremental Monthly Station Table Update (American Samoa, WIDE daily file) ######

library(dplyr)
library(lubridate)
library(stringr)
library(tidyr)

# ----------------------------------------------------------
# 1. Directories (PROJECT_ROOT)
# ----------------------------------------------------------
main_dir <- Sys.getenv("PROJECT_ROOT")
day_dir  <- file.path(main_dir, "as_idw_rf_table_NRT/")
out_dir  <- file.path(main_dir, "as_monthly_rf/")
# dir.create(out_dir, showWarnings = FALSE)

# ----------------------------------------------------------
# 2. Load date function (as_dataDateFunc.R)
# ----------------------------------------------------------
source(file.path(main_dir, "as_dataDateFunc.R"))
proc_date <- dataDateMkr()
cat("Processing date set to:", as.character(proc_date), "\n\n")

# # For running a custom date
# proc_date <- as.Date("2025-09-01")
# cat("TEST MODE — Processing date forced to:", as.character(proc_date), "\n\n")

# ----------------------------------------------------------
# 3. Determine last full month
# ----------------------------------------------------------
target_month <- floor_date(proc_date, "month") %m-% months(1)
target_year  <- year(target_month)
target_mon   <- month(target_month)

month_ym_str <- sprintf("%04d%02d", target_year, target_mon)
ym_colname   <- paste0("X", target_year, ".", sprintf("%02d", target_mon))

cat("Target month:", ym_colname, "\n\n")

# ----------------------------------------------------------
# 4. Identify the wide daily file
#     Example file naming:
#     daily_station_202501_wide.csv  OR  rainfall_daily_202501.csv
#     Adjust pattern as needed!
# ----------------------------------------------------------
wide_file <- list.files(
  day_dir,
  pattern = paste0("^daily_rainfall_station_AS_", target_year, "_", sprintf("%02d", target_mon), "\\.csv$"),
  full.names = TRUE
)

if (length(wide_file) == 0) stop("No wide daily file found for: daily_rainfall_station_AS_", target_year, "_", sprintf("%02d", target_mon))
if (length(wide_file) > 1) stop("Multiple matching wide daily files found. Narrow your pattern!")

cat("Using file:", basename(wide_file), "\n\n")

daily <- read.csv(wide_file, check.names = FALSE)
head(daily)
# ----------------------------------------------------------
# 5. Identify daily rainfall columns
#     They should start with XYYYY.MM.DD (same format as Matty)
# ----------------------------------------------------------
day_pattern <- paste0("^X", target_year, "\\.", sprintf("%02d", target_mon), "\\.\\d{2}$")
day_cols <- grep(day_pattern, names(daily), value = TRUE)

if (length(day_cols) == 0) stop("No daily columns found matching pattern: ", day_pattern)

cat("Found", length(day_cols), "daily rainfall columns.\n")

# ----------------------------------------------------------
# 6. Compute monthly rainfall
# ----------------------------------------------------------
daily$monthly_sum <- apply(
  daily[, day_cols],
  1,
  function(x) if (any(is.na(x))) NA else sum(x, na.rm = TRUE)
)

monthly_df <- daily %>%
  dplyr::select(SKN, Station.Name, monthly_sum)

# ----------------------------------------------------------
# 7. Load or create the annual table (preserve canonical metadata)
# ----------------------------------------------------------
metadata_cols <- c("SKN","Station.Name","Observer","Network","Island","ELEV.m.","LAT","LON","NCEI.id","NWS.id","NESDIS.id","SCAN.id","SMART_NODE_RF.id")

annual_file <- file.path(
  out_dir,
  paste0("monthly_rainfall_station_AS_", target_year, ".csv")
)

if (file.exists(annual_file)) {
  annual_df <- read.csv(annual_file, check.names = FALSE)
  
  # Drop any old/duplicated metadata cols and reattach fresh metadata to enforce
  # column presence + order (prevents dropped or moved metadata like ELEV.m.)
  annual_df <- annual_df |>
    dplyr::select(-any_of(setdiff(metadata_cols, c("SKN","Station.Name")))) |>
    left_join(
      daily |> dplyr::select(all_of(metadata_cols)) |> distinct(),
      by = c("SKN","Station.Name")
    )
  
  cat("Loaded existing annual file:", basename(annual_file), "\n")
} else {
  # Start a fresh annual table with canonical metadata (in correct order)
  annual_df <- daily |> dplyr::select(all_of(metadata_cols)) |> distinct()
  cat("Creating NEW annual table:", basename(annual_file), "\n")
}

# ----------------------------------------------------------
# 8. Insert/Update the new monthly column (XYYYY.MM)
# ----------------------------------------------------------
cat("Adding/updating monthly column:", ym_colname, "\n")

new_month_col <- monthly_df |>
  dplyr::select(SKN, monthly_sum) |>
  rename(!!ym_colname := monthly_sum)

annual_updated <- annual_df |>
  left_join(new_month_col, by = "SKN")

# ----------------------------------------------------------
# 9. Enforce final column order: metadata first, then month columns chronologically
# ----------------------------------------------------------
month_cols <- grep("^X\\d{4}\\.\\d{2}$", names(annual_updated), value = TRUE)
month_cols <- sort(month_cols)  # lexical = chronological (XYYYY.MM)

final_df <- annual_updated |>
  dplyr::select(all_of(metadata_cols), all_of(month_cols))

# ----------------------------------------------------------
# 10. Save updated annual table (keep names exactly as-is)
# ----------------------------------------------------------
write.csv(final_df, annual_file, row.names = FALSE)

cat("\n✅ Updated:", basename(annual_file))
cat("\n✅ Added column:", ym_colname)
cat("\n✅ Metadata preserved and ordered.\n")