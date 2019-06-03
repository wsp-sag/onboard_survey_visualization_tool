# Transit On-Board Survey Visualization Tool

This tool was created to assist in validating the accuracy and usability of reported trip origin, destination, boarding and alighting locations in transit on-board surveys. This interactive tool can read in origin, destination, boarding and alighting location coordinates from user-specified survey data file, and plot them on an open source map. Users would be able to select one surveyed route for examination each time, and the application would display reported origin, destination, boarding and alighting of all survey records surveyed on this route, in addition to stop locations of the selected route from the General Transit Feed Specification (GTFS). Users can further click on any trip end, and the application would highlight corresponding origin, destination, boarding and alighting associated with the same record. In this way, the user can visually scrutinize if the reported trip ends, access and egress mode, and the use of transfers are logical. 

## Getting Started

### Software Requirement

To run this Shiny app, please download R Studio, open either "server.R" or "ui.R" in R Studio, and click "Run App". This tool has been tested with R version 3.4.3 and 3.5.1.

### Data Requirement

For this tool to run properly, the survey data file needs be a comma separated csv or text file. It should have the following fields:
- **gtfs_route_short_name**         - The name of the route that Surveyee was surveyed on. 
                                      This needs to match **route_short_name** in GTFS __"routes.txt"__ file.
- **direction**                     - Direction of the route. Acceptable values are "Inbound" and "Outbound".
- **origin_lon**                    - Longitude of the origin location of the surveyed route.
- **origin_lat**                    - Latitude of the origin location of the surveyed route. 
- **destination_lon**               - Longitude of the destination location of the surveyed route.
- **destination_lat**               - Latitude of the destination location of the surveyed route.
- **boarding_lon**                  - Longitude of the boarding location of the surveyed route.
- **boarding_lat**                  - Latitude of the boarding location of the surveyed route. 
- **alighting_lon**                 - Longitude of the alighting location of the surveyed route.
- **alighting_lat**                 - Latitude of the alighting location of the surveyed route.
- **origin_loc** _Optional._        - Origin location of the trip. Examples: Home, International Mall, Downtown Miami. 
- **destination_loc** _Optional._   - Destination location of the trip. Example: Walmart, International Mall, Home. 
- **all_routes** _Optional._        - All routes that were taken during this trip between trip origin and destination.
- **access** _Optional._            - Access mode used to get from trip origin to the the first transit stop of the trip.
- **egress** _Optional._            - Egress mode used to get from the last transit stop to the final destination.

Please make sure all the coordinate fields are numeric, otherwise the shiny app might not run properly. The leaflet map in this tool has a base map. If the base map is not loaded correctly, please open the tool in browser. To use the sample data included in the _\data_ folder, please download [King County Metro GTFS data](http://transitfeeds.com/p/king-county-metro/73).

### Contributing

Pull requests and suggestions are welcome. Please open an issue first to discuss what you would like to change.

### Contact Information

The WSP member responsible for this repository is Dora Wu (j.wu@wsp.com). 
