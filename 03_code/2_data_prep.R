# Prepare the data

library(here)
library(tidyverse)
library(magrittr)
library(sf)


# Prepare GTFS data from the HVV (stations and geometry of the U3) -------------
  # This data contains the location of the stations as well as the geometries
  # of each line. It also contains the timetable of each trip but we are just
  # interested in the location of each station and the geometries of the U3

  # The GTFS data is strucuted in a specific way. For each route there are
  # multiple trips. The geomtries of each trip are stored as a shape.
  # Each trip has several strop_times that can be used to get the location of
  # each station in the table "stops".

  # For more information refer to:
  # https://en.wikipedia.org/wiki/General_Transit_Feed_Specification

## Retrieve the geometries of the U3 ----
# 1. Import the routes and retrieve the route_id for the U3
gtfs_routes <- read_delim(here("01_data", "1_raw", "hvv_gtfs_2019", "routes.txt"),
                          delim = ",")

route_id_u3 <- gtfs_routes %>% 
  filter(route_short_name == "U3") %>% 
  select(route_id) %>%
  first() # = 8803_1

# 2. Import the trips and retrieve the shape_id for the U3
gtfs_trips <- read_delim(here("01_data", "1_raw", "hvv_gtfs_2019", "trips.txt"),
                         delim = ",")

shape_ids_u3 <- gtfs_trips %>% 
  filter(route_id == route_id_u3) %>% 
  select(shape_id) %>% 
  distinct()

# Note: There are 15 different shape_id as trips of the U3 can go in both
# directions and some trips start or end at different stations

# 3. Import and select the geometries (shapes) of the trips on the route U3
gtfs_shapes <- read_delim(here("01_data", "1_raw", "hvv_gtfs_2019", "shapes.txt"),
                          delim = ",")

# Select the relevant shapes of those trips that are running on the route of the U3
gtfs_shapes_u3 <- gtfs_shapes %>% 
  filter(shape_id %in% shape_ids_u3$shape_id)

# Transfom the single points into linestrings for each shape_id (trip)
gtfs_shapes_u3_lines <- gtfs_shapes_u3 %>%
  st_as_sf(coords = c("shape_pt_lon", "shape_pt_lat"),
           crs = 4326) %>%
  group_by(shape_id) %>% 
  summarise(do_union = FALSE) %>% 
  st_cast("LINESTRING")

# Save the geometry of the U3
saveRDS(gtfs_shapes_u3_lines, here("01_data", "2_processed", "gtfs_shapes_u3_lines.RDS"))

## Retrieve the location of each station via the stops ----
# 1. Retrieve the trip ids from those trips of the U3
gtfs_trips_u3 <- gtfs_trips %>% 
  filter(route_id ==route_id_u3) %>% 
  select(trip_id)

# 2. Retrieve the stop_ids from each trip
gtfs_stop_times <- read_delim(here("01_data", "1_raw", "hvv_gtfs_2019", "stop_times.txt"),
                              delim = ",")

gtfs_stop_times_u3 <- gtfs_stop_times %>% 
  filter(trip_id %in% gtfs_trips_u3$trip_id) %>% 
  select(stop_id) %>% 
  distinct()

# 3. Retrieve the coordinates of the stations from these stops
gtfs_stops <- read_delim(here("01_data", "1_raw", "hvv_gtfs_2019", "stops.txt"),
                         delim = ",")

# Each station has two stops as the U3 is running in both directions. Hence,
# we only select one stop-point for each station
gtfs_stops_u3 <- gtfs_stops %>% 
  filter(stop_id %in% gtfs_stop_times_u3$stop_id) %>% 
  distinct(stop_name, .keep_all = TRUE) %>% # This selects only one coordinate per station
  filter(stop_name != "Barmbek(2)") # This stop is also a dublicate
  
gtfs_stops_u3_sf <- gtfs_stops_u3 %>% 
  st_as_sf(coords = c("stop_lon", "stop_lat"),
           crs = 4326)

# 4. Finally, we add the stop order to each station
gtfs_stops_u3_sf %<>% 
  rename("station_name" = "stop_name")

stations_order <- readRDS(here("01_data", "2_processed", "stations_order.RDS"))
  
stations <- left_join(gtfs_stops_u3_sf,
                      stations_order,
                      by = "station_name")

# Save the coordinates of the stations of the U3
saveRDS(stations, here("01_data", "2_processed", "stations.RDS"))


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
# We do not consider the Stat. Gebiet "20004" which is south the Elbe river and
# would be considered for the station Landungsbrücke otherwise.

communities <- st_join(filter(communities, statgebiet != 20004),
                       stations,
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
                                     stations,
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

areas_around_stations$sum_bevöl[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_kinder_migration[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_kinder_alleinerziehende[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_sgb2_empfänger[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_arbeitslose[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_kinder_mindestsicherung[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_alte_mindestsicherung[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_kinder_mindestsicherung[areas_around_stations$station_name == "Rathaus"] <- NA
areas_around_stations$avg_schulabschluss_kein_abitur[areas_around_stations$station_name == "Rathaus"] <- NA

# Round statistics to 3 digits -------------------------------------------------
areas_around_stations %<>% 
  mutate_if(is.numeric, round, 3)


# Export the dataframe with the results per station ----------------------------
saveRDS(areas_around_stations,
        here("01_data", "2_processed", "areas_around_stations.RDS"))

areas_around_stations %>% 
  select(-geometry) %>% 
  filter(!is.na(station_name)) %>% 
  write_csv(here("02_results", "results_per_station.csv"))


# Prepare data from Straßenbaumkataster ----------------------------------------
trees <- read_sf(here::here("01_data", "1_raw", "Straßenbaumkataster_-_Hamburg.geojson")) # 190 MB
stations <- readRDS(here("01_data", "2_processed", "stations.RDS"))

# Obtain the trees that are within a radius of 500m around a station
trees <- st_join(trees,
                 stations,
                 st_is_within_distance, dist = 500)

trees %<>%
  dplyr::filter(!is.na(station_name))

# Export those trees
saveRDS(trees,
        here("01_data", "2_processed", "trees.RDS"))


# Export Session Info to ensure reproducability --------------------------------
writeLines(capture.output(sessionInfo()), "sessionInfo.txt")
