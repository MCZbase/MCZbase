#graph 1: transitioning through time
#animation set up
library(gganimate)
library(tibble)
library(tidyverse)
library(ggplot2)
library(dplyr)
library(plotly)
library(gapminder)
library(ggthemes)
library(gifski)
library(png)
library(ggthemes)

simple_chart <- read_csv('/metrics/datafiles/chart_data.csv')
#simple_chart <- `chart_data1`
chart <- filter(simple_chart,COLLECTION=='Herpetology')
chart0 <- filter(chart, CITATION_TYPE =='Primary')

chart1 <- ggplot(chart0, aes(x=TYPE_STATUS, y=NUMBER_OF_CITATIONS, fill=TYPE_STATUS)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)
chart1





