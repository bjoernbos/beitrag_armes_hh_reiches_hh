# Generate maps
# This script produces interactive maps "only". To use static maps for LaTeX
# or somewhere else, simply take a screenshot.

library(here)
library(sf)
library(tmap)

# Load data
communities <- readRDS(here("01_data", "2_processed", "communities.RDS"))
stations <- readRDS(here("01_data", "2_processed", "stations.RDS"))
gtfs_shapes_u3_lines <- readRDS(here("01_data", "2_processed", "gtfs_shapes_u3_lines.RDS"))

# Map indicating all Statistische Gebiete and highlight the relevant ones ------
tmap_mode("view")

# Relevant Stat. Gebiete
tm_shape(filter(communities, !is.na(station_name))) +
    tm_fill(col = "darkgrey",
            alpha = 0.5,
            id = "stadtteil_name", # id is shown as hover text
            popup.vars = c("bevölk_12_2017", "arbeitslose")) + 
   tm_borders() +
  
  # + Geomtry of the U3
  tm_shape(gtfs_shapes_u3_lines) +
    tm_lines(col = "yellow",
             lwd = 6,
             id = "") +
  
  # + Points of Stations
  tm_shape(stations) + 
    tm_dots(col = "black",
            id = "station_name",
            popup.vars = "stop_number") +

  # + Some station names
  tm_shape(stations[stations$station_name %in%
                    c("Wandsbek-Gartenstadt", "Barmbek", "Hauptbahnhof Süd",
                      "St.Pauli", "Schlump", "Kellinghusenstraße"),]) +
   tm_text("station_name",
           size = 1.1,
           col = "black",
           just = "bottom")

