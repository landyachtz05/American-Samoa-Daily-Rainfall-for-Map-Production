###### Combine NRT AS daily data from Mesonet and WRCC for use in IDW ######
library(dplyr)
library(readr)
library(stringr)

# ---- 0. Define input and output folders ----
input_folder  <- "F:/PDKE/american_samoa/rain_data/NRT"
output_folder <- file.path(input_folder, "all")  # subfolder 'all' for combined CSV
if (!dir.exists(output_folder)) dir.create(output_folder)

# ---- 1. List CSV files in input folder ----
files <- list.files(
  input_folder, 
  pattern = "\\.csv$", 
  full.names = TRUE
)

# ---- 2. Extract date from first filename ----
# assumes filenames like "as_mesonet_2025_09_11.csv"
file_date <- str_extract(basename(files[1]), "\\d{4}_\\d{2}_\\d{2}")

# ---- 3. Convert date to YYYYMMDD format ----
file_date_fmt <- gsub("_", "", file_date)

# ---- 4. Read all CSVs as character to avoid type conflicts ----
meso_list <- lapply(files, function(f) {
  read_csv(f, col_types = cols(.default = col_character()))
})

# ---- 5. Combine all CSVs into one table ----
meso_combined <- bind_rows(meso_list)

# ---- 6. Convert numeric columns back to numeric ----
meso_combined <- meso_combined %>%
  mutate(
    SKN = as.numeric(SKN),
    Elev.m = as.numeric(Elev.m),
    LAT = as.numeric(LAT),
    LON = as.numeric(LON),
    value = as.numeric(value),
    completeness = as.numeric(completeness)
  )

# ---- 7. Transform combined table to match 'goal' format ----
meso_goal <- meso_combined %>%
  transmute(
    SKN = SKN,
    Station.Name = Station.Name,
    Observer = Observer,
    Network = NA_character_,
    Island = NA_character_,
    ELEV.m. = Elev.m,
    LAT = LAT,
    LON = LON,
    NCEI.id = NA_character_,
    NWS.id = NA_character_,
    NESDIS.id = NA_character_,
    SCAN.id = NA_character_,
    SMART_NODE_RF.id = NA_character_,
    total_rf_mm = value,
    x = NA_real_,
    y = NA_real_,
    RF_Mean_Extract = NA_real_,
    total_rf_mm_logC = NA_real_
  )

# ---- 8. Define output file path with new format ----
output_file <- file.path(output_folder, paste0(file_date_fmt, "_as_rf_idw_input.csv"))

# ---- 9. Write the CSV ----
write_csv(meso_goal, output_file)

# ---- 10. Confirm ----
cat("Combined file saved to:", output_file, "\n")
