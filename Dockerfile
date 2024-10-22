## get base image with shiny and tidyverse already installed
FROM rocker/shiny-verse

## install debian dependencies
RUN apt-get update -qq && apt-get -y --no-install-recommends install \
    libgdal-dev \
    libproj-dev \
    libgeos-dev \
    libudunits2-dev \
    netcdf-bin \
    libxml2-dev \
    libcairo2-dev \
    libsqlite3-dev \
    libpq-dev \
    libssh2-1-dev \
    unixodbc-dev \
    libcurl4-openssl-dev \
    libssl-dev

## update system libraries
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get clean
    
# install R dependencies
RUN R -e "install.packages(c('bslib', 'showtext', 'plotly'))"

# make a directory in the container
RUN mkdir /home/shiny-app

# copy the shiny app code
COPY /app /home/shiny-app

# expose port
EXPOSE 8180

# run app
CMD ["R", "-e", "shiny::runApp('/home/shiny-app/', host='0.0.0.0', port=8180)"]