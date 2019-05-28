#!/bin/bash

# Dataprep in R
Rscript --vanilla --verbose 03_code/1_download_data.R
Rscript --vanilla --verbose 03_code/2_data_prep.R

# Create maps and charts
Rscript --vanilla --verbose 03_code/3_maps.R
Rscript --vanilla --verbose 03_code/4_charts.R

# Compile LaTeX document
# pdflatex --shell-escape -interaction=batchmode -output-directory=04_docs/Latex/ 04_docs/Latex/Essay.tex

# Compile interavtive Website
R -e "rmarkdown::render('04_docs/Website/Essay.Rmd', output_file = 'index.html', output_dir = here::here())"
