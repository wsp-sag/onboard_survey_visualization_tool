# install R packages required to run the app, if library does not exist
list.of.packages <- c("shiny", 
                      "shinydashboard", 
                      "shinyFiles",
                      "leaflet", 
                      "tidyverse", 
                      "stringr", 
                      "ggmap", 
                      "rgdal", 
                      "rgeos", 
                      "data.table")

packages_vector <- list.of.packages[!(list.of.packages %in% installed.packages()[,"Package"])]

if(length(new.packages)) install.packages(new.packages)

for (package in list.of.packages){
  library(package, character.only = TRUE)
}
