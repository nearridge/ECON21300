library(tidyverse)
library(curl)
library(stringr)
library(here)
library(tidycensus)
library(jsonlite)


# Downloads raw data from CSSE github repo. It is updated daily. 
cases_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv"))
deaths_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"))

# Downloads raw data from NYT github repo. It is updated daily. 
NYT <-read_csv(curl("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"))

# Downloads deographic data from the ACS
demo_data <- get_acs(geography = "county", 
        variables = c(`population-` = "B01003_001",
                      `median_income-` = "B19013_001",
                      `num_hh-` = "B10063_001",
                      `num_hh_w_people_under18-` = "B11005_002",
                      `num_hh_w_people_over60-` = "B11006_002",
                      num_owneroccupants_morethan1_per_room = "B25014_005",
                      num_owneroccupants_morethan15_per_room = "B25014_006",
                      num_owneroccupants_morethan2_per_room = "B25014_007",
                      num_renteroccupants_morethan1_per_room = "B25014_011",
                      num_renteroccupants_morethan15_per_room = "B25014_012",
                      num_renteroccupants_morethan2_per_room = "B25014_013",
                      `pop_under18-` = "B09001_001",
                      `enrolled_in_school-` = "B14001_002"), year = 2018, state = "Illinois", output = "wide")

# Downloads raw mobility data from the Descartes Labs github
mobility <- read_csv(curl("https://raw.githubusercontent.com/descarteslabs/DL-COVID-19/master/DL-us-mobility-daterow.csv"))

# Downloads raw .json from IL Department of Public Health

dph_json <- read_lines(curl("https://www.dph.illinois.gov/sitefiles/COVIDHistoricalTestResults.json"))


# Get current system date
date <- Sys.Date() %>%
  str_replace_all("-","")

# Write static files
write_csv(cases_raw, paste("Homework 1/Raw Data/", date, "_JHUcases_US.csv", sep = ""), na = "NA", col_names = TRUE)
write_csv(deaths_raw, paste("Homework 1/Raw Data/", date, "_JHUdeaths_US.csv", sep = ""), na = "NA", col_names = TRUE)
write_csv(NYT, paste("Homework 1/Raw Data/", date, "_NYT_covid_World.csv", sep = ""), na = "NA", col_names = TRUE)
write_csv(demo_data, paste("Homework 1/Raw Data/", date, "_ACS_demographics.csv", sep = ""), na = "NA", col_names = TRUE)
write_csv(demo_data, paste("Homework 1/Raw Data/", date, "_descartes_mobility.csv", sep = ""), na = "NA", col_names = TRUE)
write_json(dph_json, paste("Homework 1/Raw Data/", date, "_DPH_covid.json", sep = ""))



# Run on April 14, 2020. 