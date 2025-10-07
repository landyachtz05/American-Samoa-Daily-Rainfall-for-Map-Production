###### Combine NRT AS daily data from Mesonet and WRCC for use in IDW ######

#load packages
library(dplyr)
library(readr)
library(stringr)

#set dirs
mainDir <- Sys.getenv("PROJECT_ROOT")
setwd(mainDir)
inDir<-paste0(mainDir,"/as_individual_data")
outDir<-paste0(mainDir,"/as_combined_data")

#ensure empty output dir
unlink(file.path(outDir, "*"), recursive = TRUE)

#list csvs in input folder
files <- list.files(
  inDir, 
  pattern = "\\.csv$", 
  full.names = TRUE
)

#get date from first filename
#file_date <- str_extract(basename(files[1]), "\\d{4}_\\d{2}_\\d{2}")

# USE DATE FUNCTION

#convert date to YYYYMMDD format
file_date_fmt <- gsub("_", "", file_date)

#read csvs as characters to avoid type issues
meso_list <- lapply(files, function(f) {
  read_csv(f, col_types = cols(.default = col_character()))
})

#combine csvs
meso_combined <- bind_rows(meso_list)

#convert columns to numeric
meso_combined <- meso_combined %>%
  mutate(
    SKN = as.numeric(SKN),
    Elev.m = as.numeric(Elev.m),
    LAT = as.numeric(LAT),
    LON = as.numeric(LON),
    value = as.numeric(value),
    completeness = as.numeric(completeness)
  )

#reformat
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

#write csv
output_file <- paste0(outDir,"/",file_date_fmt, "_as_rf_idw_input.csv")
write_csv(meso_goal, output_file)
cat("Combined file saved to:", output_file, "\n")


#end
