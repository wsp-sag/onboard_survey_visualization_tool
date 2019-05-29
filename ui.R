library(shinydashboard)
library(leaflet)
library(data.table)
library(shinyFiles)

navbarPage("Transit On-Board Survey",
           tabPanel("Survey Records",
                    fluidPage(
                        fileInput("obs_data_file", "Choose Survey Data File",
                                  multiple = FALSE,
                                  accept = c("text/csv",
                                             "text/comma-separated-values, text/plain",
                                             ".csv")),
                        
                        shinyDirButton("gtfs_directory", label = "Select GTFS Directory",
                                       title = "Please select GTFS Folder"),
                        
                        tags$div("",
                                 tags$br()),
                        
                        fluidRow(
                            column(6, tags$b(textOutput("gtfs_folder_path")))),
                            
                        checkboxInput("checkbox", "GTFS direction_id=1 is inbound", 
                                      value = TRUE),

                        # Horizontal line ----
                        tags$hr(),
                        
                        # Create a new row for the table.
                        DT::dataTableOutput("survey_data_table")
                    )

                    
           ),
           tabPanel("Visualization", 
                    tags$style(type = "text/css", 
                               "html, body {width:100%;height:100%}",
                               ".leaflet .legend i{
                               width: 10px;
                               height: 10px;
                               margin-top: 4px;
                               }
                               "
                    ),
                      fluidRow(
                        column(width = 9,
                          box(width = NULL, solidHeader = TRUE,
                            leafletOutput("routemap", height = 850)
                          )
                        ),
                        column(width = 3,
                          box(width = NULL, status = "warning",
                            selectInput(inputId = "selected_route",
                                        label = "Route:",
                                        choices = NULL),
                            selectInput(inputId = "selected_direction",
                                        label = "Direction:",
                                        choices = NULL)
                          ),
                          box(width = NULL,
                              h4(strong('Route Survey Summary')),
                              tableOutput("route_summary")
                              ),
                        
                          box(width = NULL, 
                              h4(strong('Record Information')),
                              textOutput("record_index"),
                              textOutput("origin_location"),
                              textOutput("dest_location"),
                              textOutput("access_mode"),
                              textOutput("egress_mode"),
                              textOutput("route_taken")
                          )
                    
                        )
                      )
                   
)
)


