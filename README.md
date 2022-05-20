# r-retail-vacancies

An RShiny web application developed at RISC for the purpose of querying the Google Maps API to find businesses, given a zip code, business type keyword, and searching radius, marked as Temporarily Closed. The Temporarily Closed display option was made available by Google post the onset of the COVID-19 pandemic. The application was developed at the request of the Economic and Neighborhood Development Team within the Office of the Mayor of the City of Chicago to support their initiaitve to revitalize vacant retail spaces across the City of Chicago post the onset of COVID-19.

### Potential Avenues for Future Development:

1. run it with multiple keywords - like a predetermined list of keywords
2. cron job to pull every month, save old data set in old data set, and new data set in new and see what the difference is?
3. refactor so API call is separate from creation of appended dataframe
4. refactor so code is less ugly?
5. figure out distribution method - host on shinyapps.io? package as an executable with electron?
