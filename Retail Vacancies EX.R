# using JD's personal API key for google maps (google developer console)
API_KEY <- Sys.getenv("GOOGLE_MAPS_RV_API_KEY")

# loading libraries
library(httr)
library(jsonlite)
library(tidyverse)
library(data.table)

library(leaflet)
library(htmltools)

# UX VARS
# zip code for first api call to determine bounding box
zipCode <- 60623
# keyWord for second api calls to find temp/perm closed places
keyWord <- 'clothes'
# radius for second api calls to find temp/perm closed places
searchingRadius <- 1000

# ZIP CODE TO BOUNDING BOX API CALL
## get bounding box based on zip code - text search
zipCodeAPICall <- GET('https://maps.googleapis.com/maps/api/place/textsearch/json',
                      query = list(query = zipCode,
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
                               query = list(keyword = keyWord,
                                            location = coordinate,
                                            radius = searchingRadius,
                                            key = API_KEY))
  establishmentsAPICallResults <- fromJSON(rawToChar(establishmentsAPICall$content),
                                           flatten = TRUE)$results
  setDT(establishmentsAPICallResults)
  
  establishmentsAppended <- rbind(establishmentsAppended, establishmentsAPICallResults, fill=TRUE)
}

# FILTERING ESTABLISHMENTSDF TO ONLY TEMP/PERM CLOSED

# keep only the temp/perm closed establishments
ESTTEMP <- filter(establishmentsAppended, business_status == 'CLOSED_TEMPORARILY')
# remove any and all duplicates
ESTTEMP <- distinct(ESTTEMP)

# MAP MAKING

leaf <- leaflet(data = ESTTEMP) %>%
  setView(lng = zipCodeAPICallResults$geometry$location$lng,
          lat = zipCodeAPICallResults$geometry$location$lat,
          zoom = 12) %>%
  addTiles() %>% 
  addMarkers(lng = ~geometry.location.lng,
             lat = ~geometry.location.lat,
             popup = sprintf(
               '<h3> %s </h3>
               <p> %s </p>',
               ESTTEMP$name,
               ESTTEMP$business_status) %>% lapply(htmltools::HTML)
             )
leaf