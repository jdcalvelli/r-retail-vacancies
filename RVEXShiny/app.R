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
          textInput(inputId = 'zipCode', label = 'Zip Code', value = 'EX: 60615'),
          textInput(inputId = 'keyWord', label = 'Key Word', value = 'EX: cafe'),
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

  output$leaf <- eventReactive(input$submit, {
    print(input$zipCode)
    print(input$keyWord)
    print(input$searchingRadius)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
