# install R packages required to run the app, if library does not exist
list.of.packages <- c("shiny", "leaflet", "tidyverse", "stringr", "ggmap", 
                      "rgdal", "rgeos", "shinydashboard", "data.table", "shinyFile")
new.packages <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages)



