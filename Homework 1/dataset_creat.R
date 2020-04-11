library(tidyverse)
library(readr)
library(curl)
library(modelr)
library(broom)
library(here)
library(lubridate)
library(jsonlite)
library(readxl)
library(here)
library(stringr)
library(textclean)



# For security reasons, my personal API key is hidden. Permission to access Census/ACS data
# to reproduce my results can be granted here: https://api.census.gov/data/key_signup.html
library(tidycensus)

NYT <-read_csv(curl("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv"))

dph_json <-read_lines(curl("https://www.dph.illinois.gov/sitefiles/COVIDHistoricalTestResults.json"))
dph_formatted <- dph_json %>% fromJSON()
dph <- dph_formatted[[5]][[1]] %>%
  unnest(values) %>%
  # Note that the IL Department of Public Health counts Chicago as distinct from Cook County
  filter(County != "Illinois") %>%
  mutate(testDate = as.Date(testDate, "%m/%d/%y")) %>%
  rename(date = testDate, county = County, tested = total_tested, cases = confirmed_cases) %>%
  select(-lat,-lon) %>%
  mutate(county = if_else(county == "Chicago", "Cook", county)) %>%
  mutate(county = if_else(county == "Suburban Cook", "Cook", county)) %>%
  group_by(date, county) %>%
  summarise_each(funs(sum))# %>%
 # pivot_longer(c(cases, deaths), names_to = "disease status", values_to = "count")

# Create tidy DFs of COVID data for IL only
NYT_counties <- NYT %>%
  filter(state == "Illinois") %>%
  select(-fips,-state) %>%
  filter(date < "2020-03-17")


covid <- full_join(NYT_counties, dph) %>%
  arrange(-desc(date)) %>%
  group_by(county) %>%
  arrange(-desc(county)) %>%
  mutate(days_since_first_case = date - ymd("2020-01-24")) %>%
  mutate(days_since_sheltering = date - mdy("3/20/2020"))

demos_full <- get_acs(geography = "county", 
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
                                             `enrolled_in_school-` = "B14001_002"), year = 2018, state = "Illinois", output = "wide") %>%
  rowwise() %>%
  mutate(`num_hh_morethan1_person_perroom-E` = sum(num_owneroccupants_morethan1_per_roomE + 
                                                     num_owneroccupants_morethan15_per_roomE + 
                                                     num_owneroccupants_morethan2_per_roomE + 
                                                     num_renteroccupants_morethan1_per_roomE + 
                                                     num_renteroccupants_morethan15_per_roomE + 
                                                     num_renteroccupants_morethan2_per_roomE)) %>%
  # aggregating error by square rooting the sum of squared errors
  mutate(`num_hh_morethan1_person_perroom-M` = sqrt(sum(num_owneroccupants_morethan1_per_roomM ^ 2 + num_owneroccupants_morethan15_per_roomM ^
                                                          2 + num_owneroccupants_morethan2_per_roomM ^ 2 + num_renteroccupants_morethan1_per_roomM ^
                                                          2 + num_renteroccupants_morethan15_per_roomM ^ 2 + num_renteroccupants_morethan2_per_roomM ^
                                                          2))) %>%
  select(-GEOID,
         -num_owneroccupants_morethan1_per_roomE,
         -num_owneroccupants_morethan15_per_roomE,
         -num_owneroccupants_morethan2_per_roomE,
         -num_renteroccupants_morethan1_per_roomE,
         -num_renteroccupants_morethan15_per_roomE,
         -num_renteroccupants_morethan2_per_roomE,
         -num_owneroccupants_morethan1_per_roomM,
         -num_owneroccupants_morethan15_per_roomM,
         -num_owneroccupants_morethan2_per_roomM,
         -num_renteroccupants_morethan1_per_roomM,
         -num_renteroccupants_morethan15_per_roomM,
         -num_renteroccupants_morethan2_per_roomM) %>%
  separate(NAME, into = c("Admin2", NA), sep = " County, Illinois")

demos <- demos_full %>%
  select(-(ends_with("-M"))) %>%
  rename(county = Admin2) %>%
  arrange(-desc(county))

covid_demos <- left_join(dph, demos)

# I grab hospital data from Illinois Health Facilities and Services Review Board
# https://www2.illinois.gov/sites/hfsrb/InventoriesData/FacilityProfiles/Pages/default.aspx

hosp <- read_excel(path = "Homework 1/Raw Data/2018 AHQ Data File.xls" , col_names = FALSE, sheet = "Hospital Utilization Data")

hosp <- hosp[-4, ]
hosp[1,8:18] <- paste0("beds", subset(hosp, select = c(8:18))[2,])
hosp[1,19:24] <- paste0("MedicalSurgicalAdmissions", subset(hosp, select = c(19:24))[2,])
hosp[1,25:30] <- paste0("PatientDaysOfCare", subset(hosp, select = c(25:30))[2,])
hosp[1,84:89] <- paste0("AdolescentMentalIllness", subset(hosp, select = c(84:89))[2,])
hosp[1,90:95] <- paste0("AdultMentalIllness", subset(hosp, select = c(90:95))[2,])
hosp <- hosp[-(2:3), ]

colnames(hosp) <- hosp[1,]
hosp <- hosp[-1, ]

hosp_full <- hosp %>% 
  select(Hospital, county = County) %>%
  select(`bedsMedical- Surgical`)
         #, `beds-Intensive Care`, `beds-Pediatric`, `beds-Obstetrics/Gynecology`, `beds-Long-Term Care`, `beds-Neonatal ICU`,
 #                                       `beds-Rehabilitation`, `beds-Acute Mental Illness`, `beds-Long-Term Acute Care`, `Direct Admissions to Intensive Care`, `Transfers into  Intensive Care`, 
 #                                       `Patient Days Direct Admissions to Intensive Care`, `Patient Days Transfers to Intensive Care`, `Intensive Care Peak Beds Set Up`)
         
         






