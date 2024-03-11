library(tidyverse)
library(readr)
database <- read_csv("dados/experimento2.csv")

exp1 <- filter(database, request_size=="big", experiment_id==2)
javahttp <- filter(exp1, app_name=="javahttp")
javagrpc <- filter(exp1, app_name=="javagrpc")
gohttp <- filter(exp1, app_name=="gohttp")
gogrpc <- filter(exp1, app_name=="gogrpc")

# test data normality with histogram and shapiro test

hist(javahttp$value, breaks="Sturges")
hist(javagrpc$value, breaks="Sturges")
hist(gohttp$value, breaks="Sturges")
hist(gogrpc$value, breaks="Sturges")

shapiro.test(javahttp$value)
shapiro.test(javagrpc$value)
shapiro.test(gohttp$value)
shapiro.test(gogrpc$value)

