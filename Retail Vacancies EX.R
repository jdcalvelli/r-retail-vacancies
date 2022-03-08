# using JD's personal API key for google maps (google developer console)
API_KEY <- Sys.getenv("GOOGLE_MAPS_RV_API_KEY")

# loading libraries
library(httr)
library(jsonlite)
library(tidyverse)

zipCode <- 60623

## get bounding box based on zip code - text search
zipCodeAPICall <- GET('https://maps.googleapis.com/maps/api/place/textsearch/json',
                      query = list(query = zipCode,
                                   key = API_KEY))

zipCodeAPICallResults <- fromJSON(rawToChar(zipCodeAPICall$content))$results

boundingBox <- list(NE_Lat = zipCodeAPICallResults$geometry$viewport$northeast$lat,
                    NE_Lng = zipCodeAPICallResults$geometry$viewport$northeast$lng,
                    SW_Lat = zipCodeAPICallResults$geometry$viewport$southwest$lat,
                    SW_Lng = zipCodeAPICallResults$geometry$viewport$southwest$lng)


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

coordinatesVector

# run a search for each coordinate and combine results
# first we need to create a data frame to join all the others to
establishmentsDF <- data.frame()

# then we need to make the queries and join them to the final dataframe WO PAGES
# for in R is like forEach array method in js
for(coordinate in coordinatesVector) {
  establishmentsAPICall <- GET('https://maps.googleapis.com/maps/api/place/nearbysearch/json',
                               query = list(location = coordinate,
                                            radius = 2500,
                                            key = API_KEY))
  establishmentsAPICallResults <- fromJSON(rawToChar(establishmentsAPICall$content), 
                                           flatten = TRUE)$results
  
  establishmentsFiltered <- select(establishmentsAPICallResults,
                                   place_id, name, business_status, 
                                   geometry.location.lat, geometry.location.lng)
  
  establishmentsDF <- rbind(establishmentsDF, establishmentsFiltered)
}


# TO-DO
# 1. add in the next page token stuff?
# 2. run it with a lot more places - up the grid
# 3. add filtration to only look at the closed temporarily or permanently
# 4. put it on a map of some kind?
# 5. maybe turn it into a shiny app? user can input a zip code (and maybe a type?)