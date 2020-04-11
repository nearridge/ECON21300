library(tidyverse)
library(readr)
library(curl)
library(modelr)
library(broom)
library(here)
library(lubridate)

# For security reasons, my personal API key is hidden. Permission to access Census/ACS data
# to reproduce my results can be granted here: https://api.census.gov/data/key_signup.html
library(tidycensus)

# Pulls in the most recent version of COVID 19 cases and deaths from CSSE github repo.
# Static (April 9) versions of both of these datasets  are saved in "Raw Data." 
cases_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv"))
deaths_raw <- read_csv(curl("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv"))

# Create tidy DFs of COVID data for IL only
cases_counties <- cases_raw %>%
  filter(Province_State == "Illinois") %>%
  select(-UID, -iso2, -iso3, -code3, -FIPS, -Lat, -Long_, -Combined_Key) %>%
  pivot_longer(c(-Admin2,  -Province_State, -Country_Region), names_to = "date", values_to = "cases") %>%
  mutate(date = as.Date(date, "%m/%d/%y"))

deaths_counties <- deaths_raw %>%
  filter(Province_State == "Illinois") %>%
  select(-UID, -iso2, -iso3, -code3, -FIPS, -Combined_Key, -Lat, -Long_) %>%
  pivot_longer(c(-Admin2, -Province_State, -Country_Region, -Population), names_to = "date", values_to = "deaths") %>%
  mutate(date = as.Date(date, "%m/%d/%y"))

# Summarizes data to reflect statewide trends
cases_IL<- cases_counties %>%
  group_by(date, Admin2, Province_State, Country_Region) %>%
  summarize(cases = sum(cases))

deaths_IL <- deaths_counties %>%
  group_by(date, Admin2, Province_State, Country_Region, Population) %>%
  summarize(deaths = sum(deaths))

# Group together cases and deaths
cases_deaths_IL <- left_join(cases_IL, deaths_IL) %>%
  pivot_longer(c(cases, deaths), names_to = "disease status", values_to = "count") %>%
  mutate(percapita = count/Population) %>%
  mutate(days_since_first_case = date - ymd("2020-01-24")) %>%
  mutate(days_since_sheltering = date - mdy("3/20/2020"))