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

# use to check for loading errors  
# data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# str(data)
# head(data)
# names(data)

# use this one when testing is finished and want to go "live"
simple_chart <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv', show_col_types = FALSE)

# uncomment and use for testing in R after importing dataset in top right box with readr 
# as chart_data.csv after download from testMetrics.cfm 

#simple_chart <- chart_data


chart1 <- ggplot(simple_chart, aes(x="HOLDINGS", y=ENTEREDCATITEMS, fill=COLLECTION)) +
  geom_bar(stat="identity",width = 1)+
  coord_polar("y", start=0)

# make sure all instances in R plots, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=1000, height=640, units=c('px'), dpi=72)

# uncomment and use print(chart1) during testing

#print(chart1)
