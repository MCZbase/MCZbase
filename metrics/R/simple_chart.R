#graph 1: transitioning through time
#animation set up
library(ggplot2)
library(png)
library(sqldf)
library(readr)
library(gsubfn)
library(tidyr)


simple_chart <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv',"select * from file where COLLECTION='Herpetology' and CITATION_TYPE='Primary'")
#simple_chart <- `chart_data1`

#chart <- filter(simple_chart,COLLECTION=='Herpetology')
#chart0 <- filter(chart, CITATION_TYPE =='Primary')


chart1 <- ggplot2::fortify(simple_chart, aes(x=TYPE_STATUS, y=NUMBER_OF_CITATIONS, fill=TYPE_STATUS)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)
print(chart1)
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png',width=6, height=4,dpi=300)



