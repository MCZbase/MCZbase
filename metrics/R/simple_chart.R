#graph 1: 

library(ggplot2)

#data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')

#str(data)
#head(data)
#names(data)

#graph 1: transitioning through time
#animation set up
#library(ggplot2)
library(png)
library(readr)
#library(tidyr)
#library(dplyr)

# use this one for seeing on the webpage
simple_chart <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# change to this for testing in R after importing chart_data.csv
simple_chart <- chart_data
chart0 <- filter(simple_chart,COLLECTION=='Cryogenic')

chart1 <- ggplot(chart0, aes(x=NUMBER_OF_TYPES_WITH_IMAGES, y=NUMBER_OF_CITATIONS, fill=TYPE_STATUS)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)
print(chart1)
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png',width=6, height=4,dpi=300)





