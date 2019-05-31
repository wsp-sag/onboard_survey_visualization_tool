shinyServer(function(input, output, session) {
    
    # function to create customized markers for survey locations
    pchIcons = function(pch = 1, width = 30, height = 30, bg = "transparent", col = "black", ...) {
        n = length(pch)
        files = character(n)
        # create a sequence of png images
        for (i in seq_len(n)) {
            f = tempfile(fileext = '.png')
            png(f, width = width, height = height, bg = bg)
            par(mar = c(0, 0, 0, 0))
            plot.new()
            points(.5, .5, pch = pch[i], col = col[i], cex = min(width, height) / 8, ...)
            dev.off()
            files[i] = f
        }
        files
    }
    
    # ====================== SURVEY DATA CLEAN-UP =============================
    
    survey_data <- reactive({
    
        # read in survey data from user-specified file
        inFile <- input$obs_data_file  
        if (is.null(inFile)) return(NULL)
        
        obs_data <- read.csv(inFile$datapath, sep = ',', quote = '"',
                            stringsAsFactors = FALSE)
                             
        # if optional columns do not exist in survey file, create columns with NAs
        # so the summary table can be shown properly                    
        for (optional_column in c("origin_loc", "destination_loc", "access", "egress", "all_routes")) {
            if (!optional_column %in% colnames(obs_data)) {
                obs_data$new_column = NA
                colnames(obs_data)[ncol(obs_data)] <- optional_column
            }
        }
        
        # clean coordinate fields and convert NAs to zeros
        obs_data <- obs_data %>% 
            mutate_at(vars(c(origin_lon, origin_lat, boarding_lon, boarding_lat,
                             alighting_lon, alighting_lat, destination_lon, destination_lat)), 
                      funs(as.numeric(.))) %>% 
            mutate_at(vars(c(origin_lon, origin_lat, boarding_lon, boarding_lat,
                             alighting_lon, alighting_lat, destination_lon, destination_lat)), 
                      funs(ifelse(is.na(.), 0, .)))
                      
        # create flags to identify if record has missing coordinate data
        # to be used in creating summary later
        obs_data <- obs_data %>% 
          mutate(missing_origin = if_else(origin_lon == 0, 1, 0),
                 missing_dest   = if_else(destination_lon == 0, 1, 0),
                 missing_bding  = if_else(boarding_lon == 0, 1, 0),
                 missing_alting = if_else(alighting_lon == 0, 1, 0)) %>% 
        
        # records have coordinates for all four locations are valid
        mutate(valid = if_else(missing_origin == 0 & 
                                 missing_dest == 0 &
                                 missing_bding == 0 &
                                 missing_alting == 0, 
                               TRUE, FALSE))

        return(obs_data)
    })
    
    # ==================== CREATE LEAFLET MAP PANEL ============================
    
    # update drop down selection list using survey data
    observe({
        route_list <- unique(survey_data()[, c("route_name")])
        route_direction <- unique(survey_data()[, c("direction")])
        updateSelectInput(session, "selected_route", choices = route_list)
        updateSelectInput(session, "selected_direction", choices = route_direction)
    })
    
    # read in user-specified GTFS directory
    volumes <- getVolumes()
    shinyDirChoose(input, 'gtfs_directory', roots = volumes, session = session)
    gtfsDir <- reactive({
        return(print(parseDirPath(volumes, input$gtfs_directory)))
    })
    
    # print out select GTFS directory
    output$gtfs_folder_path <- renderText({  
        paste0(" GTFS Folder Selected: ", gtfsDir())
    })
    
    # read in GTFS files from user-specified GTFS directory
    gtfs_route <- eventReactive(input$gtfs_directory, {
        read.csv(paste0(gtfsDir(), "/routes.txt"), header = TRUE, stringsAsFactors = FALSE) })
        
    gtfs_trips <- eventReactive(input$gtfs_directory, {
        read.csv(paste0(gtfsDir(), "/trips.txt"), header = TRUE, stringsAsFactors = FALSE) })
    
    gtfs_stops <- eventReactive(input$gtfs_directory, {
        read.csv(paste0(gtfsDir(), "/stops.txt"), header = TRUE, stringsAsFactors = FALSE) })

    stop_times <- eventReactive(input$gtfs_directory, {
        read.csv(paste0(gtfsDir(), "/stop_times.txt"), header = TRUE, stringsAsFactors = FALSE) })

    # for selected route and direction, get route stops from GTFS data
    route_pts <- reactive({

        selected_route_gtfs <- gtfs_route() %>%
            filter(route_short_name == input$selected_route)
        
        selected_route_id = selected_route_gtfs$route_id
        
        INBOUND_VALUE  = as.numeric(input$checkbox)
        OUTBOUND_VALUE = as.numeric(!INBOUND_VALUE) 
        
        direction_value = ifelse(input$selected_direction == "Outbound", 
                                 OUTBOUND_VALUE, INBOUND_VALUE)
        
        selected_trips <- gtfs_trips() %>%
            filter(route_id == selected_route_id & direction_id == direction_value)
            
        selected_trip_id_list <- unique(unlist(selected_trips$trip_id))
        
        selected_stops <- stop_times() %>%
            filter(trip_id %in% selected_trip_id_list) 
        
        selected_stop_id_list <- unique(unlist(selected_stops$stop_id))
        
        route_stops <- gtfs_stops() %>% 
            filter(stop_id %in% selected_stop_id_list) %>% 
            select(stop_id, stop_name, stop_lon, stop_lat)
        
        stop_coords <- SpatialPoints(route_stops[, c("stop_lon", "stop_lat")])
        SpatialPointsDataFrame(stop_coords, route_stops)
    })
    
    # get all origin locations for selected route from survey
    origin_pts <- reactive({
        
        survey_data() %>% 
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>% 
            filter(origin_lon != -Inf & destination_lon != -Inf) %>% 
            filter(route_name == input$selected_route & direction == input$selected_direction) %>% 
            filter(!is.na(origin_lon))
        
    })
    
    # get all boarding locations for selected route from survey
    boarding_pts <- reactive({
        
        survey_data() %>% 
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>% 
            filter(origin_lon != -Inf & destination_lon != -Inf) %>% 
            filter(route_name == input$selected_route & direction == input$selected_direction) %>% 
            filter(!is.na(boarding_lon))
        
    })
    
    # get all alighting locations for selected route from survey
    alighting_pts <- reactive({
        
        survey_data() %>% 
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>% 
            filter(origin_lon != -Inf & destination_lon != -Inf) %>% 
            filter(route_name == input$selected_route & direction == input$selected_direction) %>% 
            filter(!is.na(alighting_lon))
    })
    
    # get all destination locations for selected route from survey
    destination_pts <- reactive({
        
        survey_data() %>% 
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>% 
            filter(origin_lon != -Inf & destination_lon != -Inf) %>% 
            filter(route_name == input$selected_route & direction == input$selected_direction) %>% 
            filter(!is.na(destination_lon))
    })
    
    
    # set legend features
    colors <- c("#CD6889", "#EEC900", "#43CD80", "#27408B", "#009ACD")
    labels <- c("Origin", "Boarding", "Alighting", "Destination", "GTFS Stops")
    sizes <- c(12, 12, 12, 12, 10)
    shapes <- c("circle", "circle", "circle", "circle", "cross")
    borders <- c("#CD6889", "#EEC900", "#43CD80", "#27408B", "#009ACD")
    
    # function to create customized legend for leaflet map
    addLegendCustom <- function(map, colors, labels, sizes, shapes, borders, opacity = 0.5){
        
        make_shapes <- function(colors, sizes, borders, shapes) {
            shapes <- gsub("circle", "; border-radius:50%", shapes)
            shapes <- gsub("square", "; border-radius:0%", shapes)
            shapes <- gsub("cross", "; &#10006", shapes)
            paste0(colors, "; width:", sizes, "px; height:", sizes, "px; border:3px solid ", 
                   borders, shapes)
        }
        make_labels <- function(sizes, labels) {
            paste0("<div style='display: inline-block;height: ", 
                   sizes, "px;margin-top: 4px;line-height: ", 
                   sizes, "px;'>", labels, "</div>")
        }
        
        legend_colors <- make_shapes(colors, sizes, borders, shapes)
        legend_labels <- make_labels(sizes, labels)
        
        return(addLegend(map, colors = legend_colors, labels = legend_labels, opacity = opacity))
    }
    
    
    # create leaflet map to show origin, boarding, alighting, destination location,
    # and GTFS route stops
    output$routemap <- renderLeaflet({
        leaflet() %>%
            addProviderTiles('CartoDB.Positron', group = 'CartoDB') %>%
            addMarkers(data = route_pts(), ~stop_lon, ~stop_lat,
                       icon = ~icons(iconUrl = pchIcons(4, 5, 5, col = "#009ACD", lwd = 2),
                                      popupAnchorX = 0, popupAnchorY = 0),
                       label = ~stop_name
            ) %>% # light blue
            addCircleMarkers(data = origin_pts(), lng = ~origin_lon, lat = ~origin_lat, 
                             radius = 6, color = "#CD6889", fillOpacity = 0.5, stroke = FALSE, 
                             label = ~paste(as.character(index), origin_loc, sep = " "),
                             layerId = ~index, group = "Origin"
            ) %>%  # pink
            addCircleMarkers(data = boarding_pts(), lng = ~boarding_lon, lat = ~boarding_lat, 
                             radius = 6, color = "#EEC900", fillOpacity = 0.5, stroke = FALSE, 
                             label = ~as.character(index), layerId = ~index, group = "Boarding"
            ) %>%  # yellow
            addCircleMarkers(data = alighting_pts(), lng = ~alighting_lon, lat = ~alighting_lat, 
                             radius = 6, color = "#43CD80", fillOpacity = 0.5, stroke = FALSE, 
                             label = ~as.character(index), layerId = ~index, group = "Alighting"
            ) %>%  # green
            addCircleMarkers(data = destination_pts(), lng = ~destination_lon, lat = ~destination_lat, 
                             radius = 6, color = "#27408B", fillOpacity = 0.5, stroke = FALSE, 
                             label = ~paste(as.character(index), destination_loc, sep = " "),
                             layerId = ~index, group = "Destination"
            ) %>%  # blue
            addLayersControl(baseGroups = c( "CartoDB"),
                             overlayGroups = c("Origin", "Boarding", "Alighting", "Destination"),
                             options = layersControlOptions(collapsed = FALSE)) %>%
            addLegendCustom(colors, labels, sizes, shapes, borders) %>% 
            setView(lng = (max(route_pts()@data$stop_lon) + min(route_pts()@data$stop_lon))/2, 
                    lat = (max(route_pts()@data$stop_lat) + min(route_pts()@data$stop_lat))/2, 
                    zoom = 12) 
        
    })
    
    
    # ======================= CREATE CLICK EVENT =============================
    
    # function to highlight marker
    hiliMarker <- function(map, x, y, hicolor, layerid) 
        addCircleMarkers(map, x, y, radius=6, color="red", 
                         fillColor=hicolor, fillOpacity=0.8, opacity=1, weight=3, 
                         stroke=TRUE, layerId = layerid)
    
    # when a marker is clicked on, highlight the origin, boarding, alighting, and 
    # destination marker associated with the same record 
    observeEvent(input$routemap_marker_click, {
        
        p <- input$routemap_marker_click$id
        proxy <- leafletProxy("routemap")

        selected_record <- survey_data() %>%
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>%
            filter(origin_lon != -Inf & destination_lon != -Inf) %>%
            filter(index == p)

        proxy %>%
            hiliMarker(selected_record$origin_lon, selected_record$origin_lat,
                             "#CD6889", layerid = "slo") %>%
            hiliMarker(selected_record$destination_lon, selected_record$destination_lat,
                       "#27408B", layerid = "sld") %>%
            hiliMarker(selected_record$boarding_lon, selected_record$boarding_lat,
                       "#EEC900", layerid = "slb") %>%
            hiliMarker(selected_record$alighting_lon, selected_record$alighting_lat,
                       "#43CD80", layerid = "sla")
        
        
    })
    
    # give error message when no clicking event is detected
    id1 <- reactive({
        validate(
            need(!is.null(input$routemap_marker_click), "Please select a location from the map left")
        )
        input$routemap_marker_click$id
        
    })
    
    
    # ========================= SHOW RECORD INFORMATION ========================
    
    selected_record <- reactive({ 
        
        survey_data() %>% 
            filter(origin_lon != 0 & boarding_lon != 0 & alighting_lon != 0 & destination_lon != 0) %>% 
            filter(origin_lon != -Inf & destination_lon != -Inf) %>% 
            filter(index == id1()) 
        
        })
    
    # get additional information of the selected record
    output$record_index    <- renderText({paste("Index of record selected: ", id1())})
    output$origin_location <- renderText({paste("Origin Location:", selected_record()$origin_loc)})
    output$destination_location   <- renderText({paste("Destination Location:", selected_record()$destination_loc)})
    output$access_mode     <- renderText({paste("Access Mode:", selected_record()$access)})
    output$egress_mode     <- renderText({paste("Egress Mode:", selected_record()$egress)})
    output$route_taken     <- renderText({paste("Bus Routes Taken:", selected_record()$all_routes)})
    
    # in the "Survey Record" tab, print out the survey data file content
    output$survey_data_table <- DT::renderDataTable({
        
        read.csv(input$obs_data_file$datapath, sep = ',', quote = '"',
                 stringsAsFactors = F)
        
    })
    
    # show route summary that count number of records with missing cooridnates
    output$route_summary <- renderTable({
        
        df <- data.frame(Records = c("Total Records", "Missing Origin", "Missing Destination",
                                     "Missing Boarding Location", "Missing Alighting Location",
                                     "Valid Records"), stringsAsFactors = FALSE)
        
        route_record <- survey_data() %>% 
            filter(route_name == input$selected_route)
        num_of_record <- aggregate(index ~ direction, data = route_record, length)
        route_summary <- aggregate(cbind(missing_origin, missing_dest, missing_bding, 
                                         missing_alting, valid) ~ direction,
                              data = route_record, sum)
        route_summary <- merge(num_of_record, route_summary, by = "direction")
        route_summary <- data.frame(t(route_summary), stringsAsFactors = FALSE)
        colnames(route_summary) <- route_summary[1,]
        route_summary <- route_summary[2:7,]
        
        route_summary <- cbind(df, route_summary)
        route_summary
        
    })
    
})