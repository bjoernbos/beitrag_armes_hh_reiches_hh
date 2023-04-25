# Download necessary data

library(here)

# Geodata on "Statisische Stadtgebiete" in Hamburg -----------------------------
if (!file.exists(here("01_data", "1_raw", "wfs_hh_statistische_gebiete.gml"))) {

  url <- "http://daten-hamburg.de/bevoelkerung/statistische_gebiete/Statistische_Gebiete_HH_2017-02-24.zip"
  path_filename <- here("01_data", "1_raw", "hh_statistische_gebiete.zip")
  path <- here("01_data", "1_raw")
  
  download.file(url, path_filename)
  unzip(path_filename, exdir = path)
  
  file.remove(path_filename)
}


# Tables from the "Sozialmonitoring-Bericht 2018" ------------------------------
if (!file.exists(here("01_data", "1_raw", "sozialmonitor_2018"))) {
  
  url <- "http://suche.transparenz.hamburg.de/localresources/Upload_Intern/Upload_Intern9b1f40ca-c634-420b-a14c-bd931d6c3980/Upload__sozialmonitoring-bericht-2018_anhang-tabelle.zip"
  path_filename <- here("01_data", "1_raw", "sozialmonitor_2018.zip")
  path <- here("01_data", "1_raw")
  
  download.file(url, path_filename)
  unzip(path_filename, exdir = path)
  
  file.rename(from = here("01_data", "1_raw", "Upload__sozialmonitoring-bericht-2018_anhang-tabelle"),
              to = here("01_data", "1_raw", "sozialmonitor_2018"))
  
  file.remove(path_filename)
}


# Results from federal elections in 2017 ("Bundestagswahl") --------------------
if (!file.exists(here("01_data", "1_raw", "bundestagswahl_2017_hh_erststimmme.csv"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Wahlergebnisse/endg%C3%BCltig/Download/e_23_BTW17_HH_Erst_WaBez.csv"
  path <- here("01_data", "1_raw", "bundestagswahl_2017_hh_erststimme.csv")
  
  download.file(url, path)
}

if (!file.exists(here("01_data", "1_raw", "bundestagswahl_2017_hh_zweitstimmme.csv"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Wahlergebnisse/endg%C3%BCltig/Download/e_24_BTW17_HH_Zweit_WaBez.csv"
  path <- here("01_data", "1_raw", "bundestagswahl_2017_hh_zweitstimme.csv")
  
  download.file(url, path)
}


# Geodata on the local electoral areas ("Wahlbezirke") -------------------------
if (!file.exists(here("01_data", "1_raw", "wahlbezirke_hh_2017"))) {
  
  url <- "https://www.statistik-nord.de/fileadmin/Dokumente/Wahlen/Hamburg/Bundestagswahlen/2017/Vor_der_Wahl/Wahlbezirke_BTWahl2017.zip"
  path_filename <- here("01_data", "1_raw", "wahlbezirke_hh_2017.zip")
  dir.create(here("01_data", "1_raw", "wahlbezirke_hh_2017"))
  
  download.file(url, path_filename)
  unzip(path_filename, exdir = here("01_data", "1_raw", "wahlbezirke_hh_2017"))
  
  file.remove(path_filename)
}


# Order of subway stations -----------------------------------------------------
if (!file.exists(here("01_data", "2_processed", "stations_order.RDS"))) {

  stations_order <- tibble::tibble(
    stop_number  = 1:25,
    station_name = c("Wandsbek-Gartenstadt", "Habichtstraße", "Barmbek", "Dehnhaide",
                     "Hamburger Straße", "Mundsburg", "Uhlandstraße", "Lübecker Straße",
                     "Berliner Tor", "Hauptbahnhof Süd", "Mönckebergstraße", "Rathaus",
                     "Rödingsmarkt", "Baumwall (Elbphilharmonie)", "Landungsbrücken",
                     "St.Pauli", "Feldstraße (Heiligengeistfeld)", "Sternschanze (Messe)",
                     "Schlump", "Hoheluftbrücke", "Eppendorfer Baum", "Kellinghusenstraße",
                     "Sierichstraße", "Borgweg (Stadtpark)", "Saarlandstraße")
  )
  
  saveRDS(stations_order, here("01_data", "2_processed", "stations_order.RDS"))
}


# GTFS data from the HVV -------------------------------------------------------
if (!file.exists(here("01_data", "1_raw", "hvv_gtfs_2019"))) {
  
  url <- "http://daten.transparenz.hamburg.de/Dataport.HmbTG.ZS.Webservice.GetRessource100/GetRessource100.svc/b3ca9f0a-3fe5-4e59-80b1-43a828f7dfef/Upload__HVV_Rohdaten_GTFS_Fpl_20190506.zip"
  path_filename <- here("01_data", "1_raw", "hvv_gtfs_2019.zip")
  dir.create(here("01_data", "1_raw", "hvv_gtfs_2019"))
  
  download.file(url, path_filename, method = "curl")
  unzip(path_filename, exdir = here("01_data", "1_raw", "hvv_gtfs_2019"))
  
  file.remove(path_filename)
}


# Straßenbaumkataster Hamburg --------------------------------------------------
if (!file.exists(here("01_data", "1_raw", "Straßenbaumkataster_-_Hamburg.geojson"))) {
  
  url <- "https://opendata.arcgis.com/api/v3/datasets/d89b8f400b2a4cd4a262b8b8101fa346_0/downloads/data?format=geojson&spatialRefId=4326&where=1%3D1"
  path_filename <- here("01_data", "1_raw", "Straßenbaumkataster_-_Hamburg.geojson")

  download.file(url, path_filename) # 191 MB
}


# VanDonkelaar v5 Annual Mean for Europe ---------------------------------------
if (!file.exists(here("01_data", "1_raw", "V5GL03.HybridPM25.Europe.202101-202112.nc"))) {
  
  # Check link at: https://sites.wustl.edu/acag/datasets/surface-pm2-5/#V5.GL.03
  url <- "https://dl2.boxcloud.com/d/1/b1!4jKL2lHtXwcOpcHayO0rBYTTqbbVFBT2ij7VTf2NJHJIxGWB5tq319in-bXyiq0iTK36X10eQXv4gdZqVKy7miAyLehDZsuZKdbp5-XuIS8YrF4upyTQ8bSG0zDGy6d22qQ8WIWdFmmXl_YjVB6QB8fDEXzwxjsYeuxg0Lj7VjFHc8LYMMRXQHUhYMWXFvawxyGyQbuk3gcYMhgYn_5z8FABrLs6SG4NN656UhHk0aKU65ym8-5UsPQ0PFC9V0WTYziB44pGM-EVUZmTVvDq7TbCpnJoP2j5GcYYUs673RwMCCTw2OCEZGZyb465jSi8NfPlXOweqUjFORvajMUjVP_ROUtAcsdUSLMEZB-QTFh1aptnpDN7pblkmLOuqnAko3C0cDN6Ycz3tsMefqGVdRS1gBSyMbTho_uus_My0QMQUuNz8oGtoFL8Km-ee1VZ8BcNCUMKPYXmc6xDcvmeC6vLa3kstMNEYDOfdU5deo833F4KXWlDcwR88j6Cj-bxKYgAlJNdTYXnGpkArYgR6od_bEwvnH_TAmmCLAvkBMQdbtLlmNGufdBh7J-Fkmd09hnzxvhw9nGXEBB-nL3ERjtFj0PXb0bWI9rbyWhBfwTbvSxTIAyafGOHWA3JP8pPjl_cLMWCiAEIzWmjG89jV5EriYZEIc9uQczORl5X9Xgcvcboz4JC8s1UUkZmU0MWaI40DeJu3mDw4Xk-Wq_8I3-DeuXKs-V7pWqYfkFmS8V5IUwtUfQmCMqtmz1S4ZtByCVdxm2eth1k-q_UvfHC-5Cs4ts0TFr0z8JzHv-oS4jIWD3MWolQbNAsPIvLSBEeGkVBD-P5lvjsJiIFnnQis5OSkp4PoZzX4aFXolgmU7yMFhocdNuetSd3x2IGvEEXtX1AlDTZjEcdVklfcYYv7nKk87A27ePp8gqCH0wmwXBDriKkqAQhvilJJ0Mz2Fs9wwzdQFe8DaZHCbmeUThRVDjbhYP5mZ7SROzOcc2H5h96E-IhSvmrcRXHu_hPY_tk0hgyq2CyhobQmDxsnpmemtsL7_9-oMhLBzJm-AhHWsnXYenKXYHKndci2KvdY-gnavuwOHAf402KeSFHM3Fv9a7XgQaVqDXnDuKoFEA1uPUmDlLMEZ-QVRds_dt2PRJc4YlBSarTcULt1UIBvs1xbtkgut5FjMQ9-NLwU8gYnVCMJhe2c4Bp2ivdXi4cIPbLiWjFoDYwNZ5uSsi-dS4xJVf-FhTIf6d5ZDYGWz6j5Ziqtx9Nrm_tinzpjSqnI8JmpotK5ciS4AlCGeDnzO78TAKChJEKkTKWHWVnQb5yrFFzJUvQ/download"
  path_filename <- here("01_data", "1_raw", "V5GL03.HybridPM25.Europe.202101-202112.nc")
  
  download.file(url, path_filename)
}
