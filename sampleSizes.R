library(tidyverse)
library(readr)
database <- read_csv("dados/experimento4.csv")


# experiments small 2, 3, 4, 5
# experiments big 1, 3, 4, 5, 6
expSmall <- filter(database, request_size=="small")
expBig <- filter(database, request_size=="big")
exp1 <- expBig
javahttp <- filter(exp1, app_name=="javahttp")
javagrpc <- filter(exp1, app_name=="javagrpc")
gohttp <- filter(exp1, app_name=="gohttp")
gogrpc <- filter(exp1, app_name=="gogrpc")

xjavahttp <- mean(javahttp$value)
sjavahttp <- sd(javahttp$value)

xjavagrpc <- mean(javagrpc$value)
sjavagrpc <- sd(javagrpc$value)

xgohttp <- mean(gohttp$value)
sgohttp <- sd(gohttp$value)

xgogrpc <- mean(gogrpc$value)
sgogrpc <- sd(gogrpc$value)

n <- 2100
z <- 1.660# 99% 9df
r <- 5

szjavahttp = ((100*z*sjavagrpc)/(r*xjavahttp))^2
szjavagrpc = ((100*z*sjavagrpc)/(r*xjavagrpc))^2
szgohttp = ((100*z*sjavagrpc)/(r*xgohttp))^2
szgogrpc = ((100*z*sjavagrpc)/(r*xgogrpc))^2

print(xjavahttp)
print(sjavahttp)
print(szjavahttp)

print(xjavagrpc)
print(sjavagrpc)
print(szjavagrpc)

print(xgohttp)
print(sgohttp)
print(szgohttp)

print(xgogrpc)
print(sgogrpc)
print(szgogrpc)

