#graph 1: transitioning through time
#animation set up
library(ggplot2)
library(png)
library(readr)
library(tidyr)


simple_chart <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')

chart1 <- fortify(simple_chart, aes(x=NUMBER_OF_TYPES_WITH_IMAGES, y=NUMBER_OF_CITATIONS, fill=TYPE_STATUS)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)
print(chart1)
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png',width=6, height=4,dpi=300)



