library(tidyverse)
library(here)
library(caret)

# Capture the current seed for reproducibility
current_seed <- .Random.seed
# Read in training dataset. All data is read in as doubles. Things that mess that up are NA'ed. 
training <- read_csv(here("Homework 4", "Data", "training_data_final.csv"), na = c("-", "N"))

# Function that replaces an NA value with the mean of the col.
NA2mean <- function(x) replace(x, is.na(x), mean(x, na.rm = TRUE))
# Overwrite training with NA2mean applied. 
training <- replace(training, TRUE, map(training, NA2mean))

# Train the random forest. Goodnight see you tomorrow.
trainingrf_oob <- train(MedianMonthlyHousingCosts ~ .,
                    data = training,
                    method = "rf",
                    ntree = 600,
                    trControl = trainControl(method = "oob"))

# View model results
trainingrf_oob$finalModel

# View important variables in the model
randomForest::varImpPlot(trainingrf_oob$finalModel)

trainingrf <- train(MedianMonthlyHousingCosts ~ .,
                        data = training,
                        method = "rf",
                        ntree = 600)

# View model results
trainingrf$finalModel

# View important variables in the model
randomForest::varImpPlot(trainingrf$finalModel)

# Save the seed and random forest so I don't need to do this ever again. 
save(trainingrf_oob, file = here("Homework 4", "Saved", "trainingrf_oob.RData"))
save(trainingrf, file = here("Homework 4", "Saved", "trainingrf.RData"))
save(current_seed, file = here("Homework 4", "Saved", "seed_trainingrf.RData"))