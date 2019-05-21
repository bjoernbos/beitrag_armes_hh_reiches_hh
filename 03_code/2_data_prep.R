# Prepare the data

library(here)
library(tidyverse)
library(magrittr)
library(sf)


# Prepare the location of subway stations --------------------------------------
stations <- readRDS(here("01_data", "1_raw", "subway_stations.RDS"))

stations %<>% rename("station_name" = "stationLabel")

stations$station_name %<>% # drop the word "station" from some labels
  str_remove("\\sstation") %>% 
  str_remove("Station")

stations$station_name[stations$station_name == "Hamburg Central "] <- "Hauptbahnhof"
stations$station_name[stations$station_name == "Berliner Tor metro"] <- "Berliner Tor"
stations$station_name[stations$station_name == "Wandsbek Gartenstadt"] <- "Wandsbek-Gartenstadt"

# There are two records for the station Hauptbahnhof. One refers to the station
# Hauptbahnhof and the order one to Hauptbahnhof Süd. We drop the second one
# (Q3783676) as it is a dublicate

stations %<>% filter(station_name != "Q3783676")

# So far, we have no information on the order of the stations.
# Hence, we add a column with the stop order of the U3
stationss_order <- readRDS(here("01_data", "1_raw", "stations_order.RDS"))

stations <- left_join(stations,
                      stationss_order,
                      by = "station_name")

stations %<>% arrange(stop_number)

# Now, we need to extract and reformat the coordinates of the stations

# Before:
#   stationLabel                coordinates
#   Hamburg Central Station     Point(10.006389 53.552778)
#   Schlump                     Point(9.97 53.56777778)

# After:
#   stationLabel            lat         long
#   Hamburg Central Station 10.006389   53.552778
#   Schlump                 9.97        53.56777778

# Split at the whitespace
stations %<>% 
  separate(coordinates, c("lat", "long"), "\\s")

# Extract the numbers
stations$lat %<>%
  str_extract("\\d{1,}.\\d{1,}") %>% # <Any number of digits from 1>.<Any digits>
  as.double()

stations$long %<>%
  str_extract("\\d{1,}.\\d{1,}") %>% 
  as.double()

# Convert their latitude and longitude into geometries
stations_sf <- st_as_sf(stations,
                        coords = c("lat", "long"),
                        crs = 4326)


# Prepare geodata of "Statisische Stadtgebiete" in Hamburg: --------------------
communities <- st_read(here("01_data", "1_raw", "wfs_hh_statistische_gebiete.gml"))

# Drop unnessesary collumns
communities %<>% select(-gml_id, -flaeche)

# Reformat factors to numbers
communities$statgebiet <- as.numeric(levels(communities$statgebiet))

# Add projection and transform it to a standard projection
st_crs(communities) = 25832 # as indicated in the metadata
                            # Source: http://archiv.transparenz.hamburg.de/hmbtgarchive/HMDK/trefferanzeige_21122_snap_2.HTML

communities %<>% st_transform(4326, check = TRUE) # EPSG 4326 = WGS84 ("Web Mercator")

# Although the downloaded dataset contains the right geometries, I find deviations
# in the numbering / names of the Stat. Gebiete. Various web maps show different
# numbers and the matching with the data of the Sozialmonitoring Bericht leads to
# some location issues.
# Hence, I manually searched for the right numbers and created a "translation" table
# that shows the right number with which we can match the Sozialmonitoring Bericht.

right_community_numbers <- read_csv2(here("01_data", "2_processed", "new_community_numbers.csv"))

communities <- left_join(communities,
                         right_community_numbers)

# Result:
# statgebiet = old numbers (as downloaded but very likely to be wrong)
# new_statgebiet= new numbers (result from a manual search at geoportal-hamburg.de/sga/)


# Prepare the data from the Sozialmonitor 2018 ---------------------------------

# Import only the first columns and excludes the summary stats in the first rows
  # Note, all values are z-values. Hence, we need the mean values and standard
  # deviation that are reported in the first rows to destandardize these values.

sozialmonitor <- read_csv(
  file = here("01_data", "1_raw", "sozialmonitor_2018", "II Indikatoren.csv"),
  skip = 11,
  col_names = c("stadtteil_name", "statgebiet", "bevölk_12_2017",
                "kinder_migration", "kinder_alleinerziehende", "sgb2_empfänger",
                "arbeitslose", "kinder_mindessicherung", "alte_mindestsicherung",
                "schulabschlüsse")
  )

# Import the summary stats in the first few rows separately
sozialmonitor_summary_stats <- read_csv(
  file = here("01_data", "1_raw", "sozialmonitor_2018", "II Indikatoren.csv"),
  skip = 9,
  n_max = 2,
  col_names = c("stadtteil_name", "statgebiet", "bevölk_12_2017",
                "kinder_migration", "kinder_alleinerziehende", "sgb2_empfänger",
                "arbeitslose", "kinder_mindessicherung", "alte_mindestsicherung",
                "schulabschlüsse")
) %>% 
  select(-c(stadtteil_name, statgebiet, bevölk_12_2017))
  # First row: Mean values
  # Second row: Standard Deviation


# Destandardize the data
# So far, we have z-values. But we need to take the mean and standard deviation
# into account to transform them into the actual values back.
destandardize <- function(z_value, mean, std_dev) {
  return(z_value * std_dev + mean)
  
  # Example for Statistisches Gebiet 1008:
  # Kinder mit Migrationshintergrund = 0.91 with mean 0.48 and SD 0.2 
  # destandardize(0.9100009732, 0.487890330189, 0.200120302264) # = 67%
}

# Now get the original values for the seven indicators of the Sozialmonitor report
# Note: These indicators are in columns 4 to 7 of "sozialmonitor"
#       The corresponding mean values are in row 1 of "sozialmonitor_summary_stats"
#       and the corresponding std.dev in row 2 of "sozialmonitor_summary_stats"

for (i in 1:7) {
  sozialmonitor[,i+3] <- destandardize(
    z_value = sozialmonitor[, i+3] ,
    mean = sozialmonitor_summary_stats[[1, i]],
    std_dev = sozialmonitor_summary_stats[[2, i]])
}

# to test:
# scale(sozialmonitor[4:10])
# sozialmonitor_summary_stats


# Add infos from the Sozialmonitor to the geodata of the Stat. Gebiete
communities <- left_join(communities,
                         sozialmonitor,
                         by = c("new_statgebiet" = "statgebiet"))

# Note: Not every "statistisches Gebiet" has information on the indicators. There
# might be areas where only a few residents live such that the records are censored.


# Find the relevant Stat. Gebiete around each station --------------------------
# Consider those areas that are within a distance of 300m around each station
communities <- st_join(communities,
                       stations_sf,
                       st_is_within_distance, dist = 300)

# Save dataframe of communities
saveRDS(communities, here("01_data", "2_processed", "communities.RDS"))


# Compute the average values per station ---------------------------------------
areas_around_stations <- communities %>% 
  as_tibble() %>% 
  group_by(station_name) %>% 
  summarise(stop_number = max(stop_number),
            sum_bevöl = sum(bevölk_12_2017, na.rm = TRUE),
            avg_kinder_migration = mean(kinder_migration, na.rm = TRUE),
            avg_kinder_alleinerziehende = mean(kinder_alleinerziehende, na.rm = TRUE),
            avg_sgb2_empfänger = mean(sgb2_empfänger, na.rm = TRUE),
            avg_arbeitslose = mean(arbeitslose, na.rm = TRUE),
            avg_kinder_mindestsicherung = mean(kinder_mindessicherung, na.rm = TRUE),
            avg_alte_mindestsicherung = mean(alte_mindestsicherung, na.rm = TRUE),
            avg_schulabschluss_kein_abitur = mean(schulabschlüsse, na.rm = TRUE)) %>% 
  arrange(stop_number)


# Prepare electoral districts --------------------------------------------------
# Load the geodata of the electoral districts
electoral_districts <- read_sf(here("01_data", "1_raw", "wahlbezirke_hh_2017"))

# Add and transform to a standard projection (EPSG 4326 = WGS84)
st_crs(electoral_districts) <- 25832
electoral_districts %<>% st_transform(4326, check = TRUE)

electoral_districts$WahlBezSch <- as.double(electoral_districts$WahlBezSch)

# Load the election results
electoral_results <- read_csv2(
  file = here("01_data", "1_raw", "bundestagswahl_2017_hh_zweitstimme.csv"),
  skip = 3,
  locale = locale(encoding = "latin1"))

# Calculate the share of SPD and CDU
electoral_results$share_SPD <-  electoral_results$SPD / electoral_results$`Wähler insgesamt`
electoral_results$share_CDU <- electoral_results$CDU / electoral_results$`Wähler insgesamt`

# Add the election results to the geodata of the electoral districts
electoral_districts <- left_join(electoral_districts,
                                 electoral_results,
                                 by = c("WahlBezSch" = "Wahlbezirk"))


# Derive which electoral districts are around a station ------------------------
election_results_stations <- st_join(electoral_districts,
                                     stations_sf,
                                     st_is_within_distance,
                                     dist = 300) %>%
  group_by(station_name) %>% 
  summarise(share_SPD = mean(share_SPD),
            share_CDU = mean(share_CDU))


# Add info from election results -----------------------------------------------
areas_around_stations <- left_join(areas_around_stations,
                                   as_tibble(election_results_stations))


# Drop Mönckebergstraße as it is no residential areas --------------------------
# We fill the values for Mönckebergstraße with missing values as there are only
# 343 residents in this area

areas_around_stations$sum_bevöl[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_kinder_migration[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_kinder_alleinerziehende[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_sgb2_empfänger[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_arbeitslose[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_kinder_mindestsicherung[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_alte_mindestsicherung[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_kinder_mindestsicherung[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$avg_schulabschluss_kein_abitur[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$share_SPD[areas_around_stations$station_name == "Mönckebergstraße"] <- NA
areas_around_stations$share_CDU[areas_around_stations$station_name == "Mönckebergstraße"] <- NA


# Export the dataframe with the results per station ----------------------------
saveRDS(areas_around_stations,
        here("01_data", "2_processed", "areas_around_stations.RDS"))

write_csv(areas_around_stations,
          here("02_results", "results_per_station.csv"))

# stargazer::stargazer(areas_around_stations,
#                      type = "latex",
#                      out = here("02_results", "results_per_station.tex"),
#                      digits = 2,
#                      summary = FALSE)
