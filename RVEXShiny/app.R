#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)

# using JD's personal API key for google maps (google developer console)
API_KEY <- Sys.getenv("GOOGLE_MAPS_RV_API_KEY")

# loading libraries
library(httr)
library(jsonlite)
library(tidyverse)
library(data.table)

library(leaflet)
library(htmltools)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Retail Vacancies EX"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
          textInput(inputId = 'zipCode', label = 'Zip Code', value = '60623'),
          textInput(inputId = 'keyWord', label = 'Key Word', value = 'clothing'),
          sliderInput(inputId = 'searchingRadius', label = 'Searching Radius', 
                      min = 500, max = 2500, step = 500, value = 1500),
          actionButton(inputId = 'submit', label = 'Show Vacant Buildings')
        ),

        # Show a plot of the generated distribution
        mainPanel(
           leafletOutput('leaf')
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
  
  #saves a function you have to call in a render elsewhere
  re <- eventReactive(input$submit, withProgress(message = 'Calculating Map', value = 0, {
    # ZIP CODE TO BOUNDING BOX API CALL
    ## get bounding box based on zip code - text search
    zipCodeAPICall <- GET('https://maps.googleapis.com/maps/api/place/textsearch/json',
                          query = list(query = input$zipCode,
                                       key = API_KEY))
    
    zipCodeAPICallResults <- fromJSON(rawToChar(zipCodeAPICall$content))$results
    
    boundingBox <- list(NE_Lat = zipCodeAPICallResults$geometry$viewport$northeast$lat,
                        NE_Lng = zipCodeAPICallResults$geometry$viewport$northeast$lng,
                        SW_Lat = zipCodeAPICallResults$geometry$viewport$southwest$lat,
                        SW_Lng = zipCodeAPICallResults$geometry$viewport$southwest$lng)
    
    
    # BOUNDING BOX TO COORDINATES FCN
    ## create set of coordinates based on the bounding box
    DESIRED_GRID_LENGTH = 3
    INTERMEDIATE_GRID_LENGTH = DESIRED_GRID_LENGTH - 1
    LAT_STEP_SIZE = (boundingBox$NE_Lat - boundingBox$SW_Lat) / INTERMEDIATE_GRID_LENGTH
    LNG_STEP_SIZE = (boundingBox$NE_Lng - boundingBox$SW_Lng) / INTERMEDIATE_GRID_LENGTH
    
    coordinatesVector = c()
    
    lat = boundingBox$SW_Lat
    while(lat <= boundingBox$NE_Lat) {
      lng = boundingBox$SW_Lng
      while(lng <= boundingBox$NE_Lng) {
        coordinatesVector = append(coordinatesVector, paste(lat, lng, sep=" "))
        lng = lng + LNG_STEP_SIZE
      }
      lat = lat + LAT_STEP_SIZE
    }
    
    # COORDINATES + KEYWORD TO BUSINESSES API CALL
    # run a search for each coordinate and combine results
    # first we need to create a data frame to join all the others to
    establishmentsAppended <- data.table()
    
    # then we need to make the queries and join them to the final dataframe WO PAGES
    # for in R is like forEach array method in js
    for(coordinate in coordinatesVector) {
      establishmentsAPICall <- GET('https://maps.googleapis.com/maps/api/place/nearbysearch/json',
                                   query = list(keyword = input$keyWord,
                                                location = coordinate,
                                                radius = input$searchingRadius,
                                                key = API_KEY))
      establishmentsAPICallResults <- fromJSON(rawToChar(establishmentsAPICall$content),
                                               flatten = TRUE)$results
      setDT(establishmentsAPICallResults)
      
      establishmentsAppended <- rbind(establishmentsAppended, establishmentsAPICallResults, fill=TRUE)
    
      incProgress(amount = 1/length(coordinatesVector))
    }
    
    # FILTERING ESTABLISHMENTSDF TO ONLY TEMP/PERM CLOSED

    # keep only the temp/perm closed establishments
    ESTTEMP <- filter(establishmentsAppended, business_status == 'CLOSED_TEMPORARILY')
    # remove any and all duplicates
    ESTTEMP <- distinct(ESTTEMP)
    
    # MAP MAKING
    
    leaf <- leaflet(data = ESTTEMP) %>%
      addTiles() %>%
      addCircleMarkers(lat = ESTTEMP$geometry.location.lat, 
                       lng = ESTTEMP$geometry.location.lng,
                       popup = sprintf('<h3> %s </h3>
                                        <p> %s </p>
                                        <p> %s </p>',
                                       ESTTEMP$name,
                                       ESTTEMP$vicinity,
                                       ESTTEMP$business_status) %>% lapply(HTML)) %>%
      setView(lng = zipCodeAPICallResults$geometry$location$lng,
              lat = zipCodeAPICallResults$geometry$location$lat,
              zoom = 12)
    leaf
  }))
  
  #actually calling the render and saving it to the output
  output$leaf <- renderLeaflet({
    re()
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
