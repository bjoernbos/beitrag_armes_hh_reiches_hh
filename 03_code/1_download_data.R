# Download necessary data

library(here)

# Geodata on "Statisische Stadtgebiete" in Hamburg
if (!file.exists(here("01_data", "1_raw", "wfs_hh_statistische_gebiete.gml"))) {

  url <- "http://daten-hamburg.de/bevoelkerung/statistische_gebiete/Statistische_Gebiete_HH_2017-02-24.zip"
  path_filename <- here("01_data", "1_raw", "hh_statistische_gebiete.zip")
  path <- here("01_data", "1_raw")
  
  download.file(url, path_filename, method = "curl")
  unzip(path_filename, exdir = path)

  file.remove(path_filename)
}


# Tables from the "Sozialmonitoring-Bericht 2018"
 if (!file.exists(here("01_data", "1_raw", "sozialmonitor_2018"))) {
  
  url <- "http://suche.transparenz.hamburg.de/localresources/Upload_Intern/Upload_Intern9b1f40ca-c634-420b-a14c-bd931d6c3980/Upload__sozialmonitoring-bericht-2018_anhang-tabelle.zip"
  path_filename <- here("01_data", "1_raw", "sozialmonitor_2018.zip")
  path <- here("01_data", "1_raw")
  
  download.file(url, path_filename, method = "curl")
  unzip(path_filename, exdir = path)
  
  file.rename(from = here("01_data", "1_raw", "Upload__sozialmonitoring-bericht-2018_anhang-tabelle"),
              to = here("01_data", "1_raw", "sozialmonitor_2018"))
  
  file.remove(path_filename)
}


# Results from federal elections in 2017 ("Bundestagswahl")
if (!file.exists(here("01_data", "1_raw", "bundestagswahl_2017_hh_erststimmme.csv"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Wahlergebnisse/endg%C3%BCltig/Download/e_23_BTW17_HH_Erst_WaBez.csv"
  path <- here("01_data", "1_raw", "bundestagswahl_2017_hh_erststimme.csv")
  
  download.file(url, path, method = "curl")
}

if (!file.exists(here("01_data", "1_raw", "bundestagswahl_2017_hh_zweitstimmme.csv"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Wahlergebnisse/endg%C3%BCltig/Download/e_24_BTW17_HH_Zweit_WaBez.csv"
  path <- here("01_data", "1_raw", "bundestagswahl_2017_hh_zweitstimme.csv")
  
  download.file(url, path, method = "curl")
}


# Geodata on the local electoral areas ("Wahlbezirke")
if (!file.exists(here("01_data", "1_raw", "wahlbezirke_hh_2017"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Vor_der_Wahl/Wahlbezirke_BTWahl2017.zip"
  path_filename <- here("01_data", "1_raw", "wahlbezirke_hh_2017.zip")
  dir.create(here("01_data", "1_raw", "wahlbezirke_hh_2017"))
  
  download.file(url, path_filename, method = "curl")
  unzip(path_filename, exdir = here("01_data", "1_raw", "wahlbezirke_hh_2017"))
  
  file.remove(path_filename)
}


# Subway stations of the line U3
if (!file.exists(here("01_data", "1_raw", "subway_stations.RDS"))) {

  query <- '
  SELECT ?stationLabel ?coordinates
  WHERE 
  {
    ?station wdt:P81 wd:Q781351.
    #station #is part of #the line U3
  
    # Get coordinates of each station
    ?station wdt:P625 ?coordinates.
  
    SERVICE wikibase:label { bd:serviceParam wikibase:language
    "[AUTO_LANGUAGE],en". }
  }
  '
  
  stations <- WikidataQueryServiceR::query_wikidata(query)

  saveRDS(stations, here("01_data", "1_raw", "subway_stations.RDS"))
}


# Order of subway stations
if (!file.exists(here("01_data", "1_raw", "stations_order.RDS"))) {

  stations_order <- tibble(
    stop_number  = 1:25,
    station_name = c("Wandsbek-Gartenstadt", "Habichtstraße", "Barmbek", "Dehnhaide",
                     "Hamburger Straße", "Mundsburg", "Uhlandstraße", "Lübecker Straße",
                     "Berliner Tor", "Hauptbahnhof", "Mönckebergstraße", "Rathaus",
                     "Rödingsmarkt", "Baumwall", "Landungsbrücken", "St. Pauli",
                     "Feldstraße", "Sternschanze", "Schlump", "Hoheluftbrücke",
                     "Eppendorfer Baum", "Kellinghusenstraße", "Sierichstraße",
                     "Borgweg", "Saarlandstraße")
  )
  
  saveRDS(stations_order, here("01_data", "1_raw", "stations_order.RDS"))
}
