library(tidyverse)
library(curl)
library(stringr)
library(here)


# Downloads raw data from CSSE github repo. It is updated daily. 
cases_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv"))
deaths_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"))

# Get current system date
date <- Sys.Date() %>%
  str_replace_all("-","")

write_csv(cases_raw, paste("Homework 1/Raw Data/", date, "_cases_US.csv", sep = ""), na = "NA", col_names = TRUE)
write_csv(deaths_raw, paste("Homework 1/Raw Data/", date, "_deaths_US.csv", sep = ""), na = "NA", col_names = TRUE)

# Run on April 9, 2020. 