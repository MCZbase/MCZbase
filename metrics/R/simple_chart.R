# HOLDINGS stores reported metric counts that include those not cataloged. 
# RECEIVEDSPECIMENS stores the sum(decode(total_parts,null,1,total_parts))
# from flat after joining on holdings to accn transactions and grouped by collection and limited by a date range for received_date.
# RECEIVEDCATITEMS stores count(distinct collection_object_id) receivedCatitems, joined on holdings to accn based on range for received_date
# ENTEREDCATITEMS stores the distinct collection_object_ids from flat 
## based on accn transactions limited by a date range for entered_date
#NCBISPECIMENS stores all other ID with NCBI up until endDate of range

library(ggplot2)
library(ggthemes)
library(png)
library(readr)
library(tidyr)

  
# data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# str(data)
# head(data)
# names(data)

# use this one for seeing on the webpage
simple_chart <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# change to this for testing in R after importing chart_data.csv
# simple_chart <- chart_data_mk3

#simple_chart <- chart_data


chart2 <- ggplot(simple_chart, aes(x="HOLDINGS", y=ENTEREDCATITEMS, fill=COLLECTION)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)

ggsave('/var/www/html/arctos/metrics/R/graphs/chart2.png', chart1, width=6, height=4,dpi=300)
#print(chart2)
