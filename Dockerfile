# Use the official R Shiny image
FROM rocker/shiny:latest

# Install required R packages
RUN R -e "install.packages(c('shiny', 'DT', 'readxl'))"

# Copy app files into the container
COPY . /srv/shiny-server/

# Set permissions
RUN chmod -R 755 /srv/shiny-server

# Expose port 3838 (Shiny default)
EXPOSE 3838

# Run the Shiny app
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server', host='0.0.0.0', port=3838)"]
