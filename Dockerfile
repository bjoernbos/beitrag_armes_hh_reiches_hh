FROM rocker/geospatial:3.5

# Install curl in the container to be able to download data in R
RUN apt-get update \
    && apt-get install -y curl 

# Install further R packages
RUN R -e "install.packages(c('lwgeom', 'tmap', 'here'), repos='http://cran.rstudio.com/')"

# Copy files into the image
COPY . /home/rstudio