# Beitrag zum Wettbewerb "Armes Hamburg - Reiches Hamburg"

Arm und Reich sind häufig nicht weit voneinander entfernt. Dieser Essay zeigt regionale Unterschiede entlang der Linie U3 in Hamburg. Er ist ein Beitrag zum Wettbewerb "Armes Hamburg - Reiches Hamburg", welcher im Sommer 2019 an der Universität Hamburg ausgeschrieben wurde.

<a href="https://bjoernbos.github.io/beitrag_armes_hh_reiches_hh/"><img style="box-shadow: 5px 5px 20px grey" src="Screenshot.jpg"></a>

[Zum PDF](https://github.com/bjoernbos/beitrag_armes_hh_reiches_hh/blob/master/04_docs/Latex/Essay.pdf)

[Zur interaktiven Website](https://bjoernbos.github.io/beitrag_armes_hh_reiches_hh/)

[Zur Präsentation](https://bjoernbos.github.io/beitrag_armes_hh_reiches_hh/slides.html) (April 2023)


## Idee
In Hamburg findet man in vielen Straßen prunkvolle Fassaden und Villen reihen sich an Alster und Elbe nebeneinander. Doch ist Hamburg damit reich? Und partizipieren alle Hamburger im gleichen Maß vom allgemein angenommen Wohlstand?

Um auf regionalen Ungleichheiten aufmerksam zu machen, zeichnet dieser Essay eine Fahrt mit der Stadtbahn U3 nach, deren Verlauf einmal um die ganze Alster führt. Auf Basis von Daten des Sozialmonitoring Bericht 2018 zeigt er, dass Arm und Reich häufig nur ein paar Haltestellen voneinander entfernt sind.

## Daten
Die grundlegenden Daten stammen aus folgenden frei verfügbaren Quellen:

* Informationen zur sozialräumlichen Entwicklung stammen aus dem [Sozialmonitoring Bericht 2018](https://www.hamburg.de/sozialmonitoring). Für 941 Statistische Gebiete innerhalb Hamburgs sind darin beispielsweise Informationen zur Arbeitslosigkeit, zu Schulabschlüssen und zur Mindestsicherung unter Kindern und Rentnern angegeben.

* Die [Ergebnisse der letzten Bundestagswahl 2017](https://www.bundeswahlleiter.de/bundestagswahlen/2017/ergebnisse/weitere-ergebnisse.html) sind pro Wahlkreis vom Bundeswahlleiter abgerufen worden.

* Und schließlich stammen die Koordinaten der Haltestellen der Linie U3, sowie deren Linienverlauf aus [GTFS Daten des Hamburg Verkehrsverbund](http://suche.transparenz.hamburg.de/dataset/hvv-fahrplandaten-gtfs-mai-2019-bis-dezember-2019).


## Reproduzierbarkeit
Um die Analyse nachzuvollziehen und den Essay zu reproduzieren ist der gesamte Code in diesem Repository verfügbar. Er wurden unter `R 3.5.1` geschrieben und benötigt u.a. die Packages `tidyverse`, `sf` sowie `tmap`. Die jeweiligen Versionsnummer für diese Packages sowie Details zu weiteren Packages sind in der Datei `sessionInfo.txt` enthalten.

Im Ordner `03_code` ist der Code zum Herunterladen der Daten, zur Datenaufbereitung, sowie zur Erstellung der Karten und Grafiken enthalten.

In einer entsprechenden Umgebung können das pdf, die interaktive Website und die Präsentation auch über das `Makefile` reproduziert werden.

**Alternativ** kann der Beitrag auch über einen Dockercontainer reproduziert werden.

Dazu wird dieses Repository am besten über die Kommandozeile heruntergeladen. Anschließend kann ein Docker Image erstellt werden und R über den Docker Container gestartet werden:

```
# Herunterladen des Repo
git clone https://github.com/bjoernbos/beitrag_armes_hh_reiches_hh

# Erstellen des Docker Image
docker build -t rstudio_beitrag beitrag_armes_hh_reiches_hh/

# Starten des Docker Containers
# TODO: ändere <user_name> und <password>
docker run --rm -e USER=<user_name> \
  -e PASSWORD=<password> \
  -p 8787:8787 \
  rstudio_beitrag
```
Anschließend kann RStudio im Browser unter `localhost:8787`aufgerufen werden (der Benutzername und das Passwort wurden im letzten Befehl angegeben). Schließlich kann darüber die Analyse reproduziert werden.

Falls der Container auf einem Server gestartet werden soll, sollte ein Docker Volume als Speicherplatz angelegt werden. Andernfalls kann es zu Konflikten mit Schreibrechten kommen. Nach dem Erstellen des Docker Containers ist dafür folgendes notwendig:

```
# Erstellen eines Docker Volume
docker volume create shared_docker_volume

# Starten des Docker Container und einbinden des Volume
# TODO: ändere <user_name> und <password>
docker run --rm -e USER=<user_name> \
  -e PASSWORD=<password> \
  -p 8787:8787 \
  --mount source=shared_docker_volume,target=/home/rstudio/shared_docker_volume
  rstudio_beitrag
```

Beachte, dass in diesem Fall die Dateipfade angepasst werden müssen, da RStudio heruntergeladene Datein nur im Ordner `shared_docker_volume` speichern kann.

## Author
Björn Bos – [Mail](mailto:bjoern.bos@web.de)
