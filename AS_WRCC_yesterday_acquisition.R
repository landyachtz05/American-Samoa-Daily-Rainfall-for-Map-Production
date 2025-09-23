###### American Samoa Rainfall Data Acquisition - WRCC/NPS
# Load required packages
library(httr)      # For HTTP requests
library(dplyr)     # For data manipulation
library(stringr)   # For string processing

# ---- Function to fetch precipitation for one station ----
fetch_station <- function(stn) {
  message("Fetching station: ", stn)
  
  # 1. Make GET request to WRCC API
  res <- GET(
    "https://wrcc.dri.edu/cgi-bin/wea_dysimts2.pl",
    query = list(
      stn = stn,           # station code
      smon = "09", sday = "01", syea = "23",   # start date: Jan 1, 2025
      emon = "09", eday = "31", eyea = "23",   # end date: Jan 31, 2025
      qBasic = "ON", qPR = "ON",               # include precipitation
      unit = "E", Ofor = "A",                  # English units, ASCII output
      Datareq = "A", qc = "N", miss = "08",    # additional options
      obs = "N", WsMon = "01", WsDay = "01",   # sub-intervals (not used here)
      WeMon = "12", WeDay = "31"
    )
  )
  
  # 2. Extract the <PRE> block from HTML response
  txt <- content(res, "text")  # full HTML text
  pre_block <- str_match(txt, "(?s)<PRE>(.*)</PRE>")[,2]  # everything inside <PRE>
  lines <- str_split(pre_block, "\n")[[1]]                # split by newline
  lines <- lines[lines != ""]                             # remove completely empty lines
  
  # 3. Find header line (contains "Date") and skip the units row
  header_idx <- which(str_detect(lines, "Date"))[1]       # index of header
  data_lines <- lines[(header_idx + 2):length(lines)]    # skip units row
  
  # 4. Parse each line manually
  df <- lapply(data_lines, function(line) {
    parts <- str_split(str_trim(line), "\\s+")[[1]]  # split by whitespace
    if(length(parts) < 2) return(NULL)              # skip empty/malformed lines
    data.frame(
      Date = as.Date(parts[1], format="%m/%d/%Y"),       # first element = Date
      Precip_in = as.numeric(parts[length(parts)]),     # last element = precipitation
      station = stn
    )
  })
  
  # 5. Combine list into one dataframe and remove any rows with NA Date
  df <- bind_rows(df) %>% 
    filter(!is.na(Date))
  
  return(df)
}

# ---- Example usage for multiple stations ----
stations <- c("sam1", "sam2")
all_data <- bind_rows(lapply(stations, fetch_station))

# ---- View the first few rows ----
head(all_data)
all_data

write.csv(all_data, "F:/PDKE/american_samoa/rain_data/WRCC_datatest.csv")


##############################################
###### Dynamically Pull Yesterday's Data #####

# ---- Load required libraries ----
library(httr)       # for HTTP requests
library(stringr)    # for string manipulation
library(dplyr)      # for data manipulation
library(lubridate)  # for working with dates

# ---- Define output folder ----
output_folder <- "F:/PDKE/american_samoa/rain_data/NRT"
if (!dir.exists(output_folder)) dir.create(output_folder)  # create folder if it doesn't exist

# ---- Function to fetch precipitation for one station for a given date range ----
fetch_station <- function(stn, start_date, end_date) {
  message("Fetching station: ", stn, " (", start_date, " to ", end_date, ")")  # log progress
  
  # ---- Prepare date components for WRCC API (2-digit month/day, 2-digit year) ----
  smon <- sprintf("%02d", month(start_date))    # start month
  sday <- sprintf("%02d", day(start_date))      # start day
  syea <- substr(year(start_date), 3, 4)        # start year (last 2 digits)
  
  emon <- sprintf("%02d", month(end_date))      # end month
  eday <- sprintf("%02d", day(end_date))        # end day
  eyea <- substr(year(end_date), 3, 4)          # end year (last 2 digits)
  
  # ---- Call WRCC API for precipitation (unit = Metric mm, ASCII output) ----
  res <- GET(
    "https://wrcc.dri.edu/cgi-bin/wea_dysimts2.pl",
    query = list(
      stn = stn,
      smon = smon, sday = sday, syea = syea,
      emon = emon, eday = eday, eyea = eyea,
      qBasic = "ON", qPR = "ON",     # request precipitation
      unit = "M",                     # metric units (mm)
      Ofor = "A",                      # ASCII output
      Datareq = "A", qc = "N", miss = "08",
      obs = "N", WsMon = "01", WsDay = "01",
      WeMon = "12", WeDay = "31"
    )
  )
  
  # ---- Extract <PRE> block containing the data ----
  txt <- content(res, "text")                     # raw HTML response
  pre_block <- str_match(txt, "(?s)<PRE>(.*)</PRE>")[,2]  # extract text between <PRE> tags
  lines <- str_split(pre_block, "\n")[[1]]        # split into lines
  lines <- lines[lines != ""]                     # remove empty lines
  
  # ---- Locate header and skip units row ----
  header_idx <- which(str_detect(lines, "Date"))[1]  # find first line containing "Date"
  data_lines <- lines[(header_idx + 2):length(lines)] # skip units row (2 lines after header)
  
  # ---- Parse each line manually ----
  df <- lapply(data_lines, function(line) {
    parts <- str_split(str_trim(line), "\\s+")[[1]]  # split line into columns by whitespace
    if(length(parts) < 2) return(NULL)              # skip malformed lines
    data.frame(
      Date = as.Date(parts[1], format="%m/%d/%Y"),  # first column is date
      Precip_mm = as.numeric(parts[length(parts)]), # last column is precipitation in mm
      station = stn
    )
  })
  
  # ---- Combine list of rows into a dataframe and remove any NA rows ----
  df <- bind_rows(df) %>% filter(!is.na(Date))
  
  return(df)
}

# ---- Automatically get yesterday's date ----
yesterday <- Sys.Date() - 1

# ---- Fetch data for multiple stations ----
stations <- c("sam1", "sam2")  # station codes
all_data <- bind_rows(
  lapply(stations, function(stn) {
    fetch_station(stn, start_date = yesterday, end_date = yesterday)
  })
)

# ---- View the result ----
all_data

# ---- Transform to desired format ----
all_data_formatted <- all_data %>%
  transmute(
    station_id   = station,          # rename station
    date         = Date,             # rename date
    value        = Precip_mm,        # precipitation value
    variable     = "precip_mm",      # add variable column
    completeness = 1                 # full day (since single day, assume complete)
  )

# ---- Station metadata for WRCC stations ----
station_meta <- tibble(
  station_id   = c("sam1", "sam2"),
  SKN          = c(1024, 1023),
  Station.Name = c("toa_ridge_WRCC", "siufaga_WRCC"),
  Observer     = c("WRCC"),
  Elev.m       = c(391.7, 146.3),
  LAT          = c(-14.2611, -14.2761),
  LON          = c(-170.687, -170.722)
)

# ---- Merge metadata with precipitation ----
all_data_formatted <- all_data_formatted %>%
  left_join(station_meta, by = c("station_id")) %>%
  select(station_id, SKN, Station.Name, Observer, Elev.m, LAT, LON, date, value, variable, completeness)

all_data_formatted

# ---- Write to CSV ----
output_file <- file.path(
  output_folder, 
  paste0("as_wrcc_", gsub("-", "_", yesterday), ".csv")
)
write.csv(all_data_formatted, output_file, row.names = FALSE)

message("Daily summary with metadata saved to: ", output_file)




