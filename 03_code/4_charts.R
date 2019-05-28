# Create Charts from the results

library(here)
library(tidyverse)


# Load data
areas_around_stations <-  readRDS(here("01_data", "2_processed", "areas_around_stations.RDS"))

# Line charts
station_plot <- function(df, y_var, y_lab, y_min, y_max) {
  
  plot <- ggplot(data = filter(df, !is.na(station_name)),
                 aes_string(x = paste0("reorder(","station_name", ", stop_number)"),
                            y = y_var,
                            group = 1)) +
    geom_line(colour = "#173F5F") +
    geom_point(colour = "#173F5F") +
    scale_y_continuous(expand = c(0,0),
                       limits = c(y_min, y_max),
                       labels = scales::percent_format(accuracy = 1)) +
    labs(x = "",
         y = y_lab) +
    theme_minimal() +
    theme(plot.title = element_text(hjust = 0.5),
          axis.text.x = element_text(angle = 90, hjust = 1),
          axis.line.x = element_line(colour = "darkgrey", size = 0.5, linetype = "solid"),
          panel.grid.minor = element_blank(),
          panel.grid.major.y = element_line(colour = "lightgrey", size = 0.3, linetype = "dotted"),
          panel.grid.major.x = element_blank()
    )
  return(plot)
}


# Unemployment -----------------------------------------------------------------
station_plot(areas_around_stations,
             y_var = "avg_arbeitslose",
             y_lab = "Arbeitslosigkeit",
             y_min = 0.0,
             y_max = 0.105)

ggsave(filename = "fig_unemployment.pdf",
       path = here("02_results"),
       device = "pdf",
       width = 7,
       height = 5)


# Poverty among elderly (via "Mindestsicherung im Alter") ----------------------
station_plot(areas_around_stations,
             y_var = "avg_alte_mindestsicherung",
             y_lab = "Personen mit Mindestsicherung im Alter",
             y_min = 0.0,
             y_max = 0.32)

ggsave(filename = "fig_mindestsicherung_alter.pdf",
       path = here("02_results"),
       device = "pdf",
       width = 7,
       height = 5)


# Equal opportunities for children (via "Schulabgänger ohne Abitur") -----------
station_plot(areas_around_stations,
             y_var = "avg_schulabschluss_kein_abitur",
             y_lab = "Schulabgänger ohne Abitur",
             y_min = 0.0,
             y_max = 0.62)

ggsave(filename = "fig_schulabgaenger_ohne_abitur.pdf",
       path = here("02_results"),
       device = "pdf",
       width = 7,
       height = 5)


# Party preferences (via previous election results) ----------------------------

# First define colour codes. This allows allows for the legend in the plot
party_colors <- c("SPD" = "red",
                  "CDU" = "black")

ggplot(data = filter(areas_around_stations, !is.na(station_name)),
       aes_string(x = paste0("reorder(","station_name", ", stop_number)"))) +
  # Data of SPD
  geom_line(aes(y = share_SPD, group = 1, colour = "SPD")) +
  geom_point(aes(y = share_SPD, group = 1, colour = "SPD")) +
  # Data of CDU
  geom_line(aes(y = share_CDU, group = 1, colour = "CDU")) +
  geom_point(aes(y = share_CDU, group = 1, colour = "CDU")) +
  # Aesthetics...
  scale_y_continuous(expand = c(0,0),
                     limits = c(0.0, 0.42),
                     labels = scales::percent_format(accuracy = 1)) +
  scale_colour_manual(name="",
                      values = party_colors) +
  labs(x = "",
       y = "Anteil Zweitstimmen") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 90, hjust = 1),
        axis.line.x = element_line(colour = "darkgrey", size = 0.5, linetype = "solid"),
        panel.grid.minor = element_blank(),
        panel.grid.major.y = element_line(colour = "lightgrey", size = 0.3, linetype = "dotted"),
        panel.grid.major.x = element_blank(),
        legend.position = "top"
        )

ggsave(filename = "fig_ergebnis_bundestagswahl_2017.pdf",
       path = here("02_results"),
       device = "pdf",
       width = 7,
       height = 5)
