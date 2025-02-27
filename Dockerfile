# Use a stable R Shiny image (avoid using "latest" for stability)
FROM rocker/shiny:4.2.2

# Install required R packages, including tidyverse for dplyr operations
RUN R -e "install.packages(c('shiny', 'DT', 'readxl', 'ggplot2', 'dplyr', 'tidyverse', 'lubridate', 'stringr'))"

# Copy the app files into the container
COPY . /srv/shiny-server/

# Set correct permissions
RUN chmod -R 755 /srv/shiny-server

# Expose port 3838 (default Shiny port)
EXPOSE 3838

# Run the Shiny app (ensure correct path to app.R)
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]

