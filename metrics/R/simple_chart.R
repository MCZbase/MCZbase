#graph 1: 
#library(gganimate)
#library(tidyverse)
library(tibble)
library(ggplot2)
library(dplyr)
#library(plotly)
library(gapminder)
library(ggthemes)
library(gifski)
library(png)
library(ggthemes)
library(av)

data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')

str(data)
head(data)
names(data)



