# Generate maps
# This script produces interactive maps "only". To use static maps for LaTeX
# or somewhere else, simply take a screenshot.

library(here)
library(sf)
library(tmap)

# Load data
communities <- readRDS(here("01_data", "2_processed", "communities.RDS"))
stations_sf <- readRDS(here("01_data", "2_processed", "stations_sf.RDS"))

# Map indicating all Statistische Gebiete and highlight the relevant ones ------
tmap_mode("view")

# Borders of Sozialmonitor
tm_shape(communities$geom,
         bbox = st_bbox(c(xmin = 9.950867, # Zoom for a closer look at the U3
                          xmax = 10.053177,
                          ymin = 53.537859,
                          ymax = 53.594135),
                        crs = st_crs(4326))) +
  tm_borders() +
  
  # + Relevant Stat. Gebiete
  tm_shape(communities$geom[!is.na(communities$station_name)]) +
    tm_fill(col = "orange", alpha = 0.5) +
  
  # + Points of Stations
  tm_shape(stations_sf) + 
    tm_dots() +

  # + Some station names
  tm_shape(stations_sf[stations_sf$station_name %in%
                       c("Wandsbek-Gartenstadt", "Barmbek", "Hauptbahnhof",
                         "St. Pauli", "Schlump", "Kellinghusenstraße"),]) +
   tm_text("station_name",
            col = "black",
            shadow = TRUE,
            just = "bottom")

