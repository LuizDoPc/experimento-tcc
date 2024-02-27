library(tidyverse)
library(readr)
database <- read_csv("dados/experimento1.csv")


exp1 <- filter(database, request_size=="small", experiment_id==7)
javahttp <- filter(exp1, app_name=="javahttp")[1:10,]
javagrpc <- filter(exp1, app_name=="javagrpc")[1:10,]
gohttp <- filter(exp1, app_name=="gohttp")[1:10,]
gogrpc <- filter(exp1, app_name=="gogrpc")[1:10,]

xjavahttp <- mean(javahttp$value)
sjavahttp <- sd(javahttp$value)

xjavagrpc <- mean(javagrpc$value)
sjavagrpc <- sd(javagrpc$value)

xgohttp <- mean(gohttp$value)
sgohttp <- sd(gohttp$value)

xgogrpc <- mean(gogrpc$value)
sgogrpc <- sd(gogrpc$value)

n <- 10
z <- 3.250 # 99% 9df
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






