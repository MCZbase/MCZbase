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
library(dplyr)
library(viridis)
library(forcats)
library(hrbrthemes)
library(grid)
# use to check for loading errors  
# data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# str(data)
# head(data)
# names(data)


# use this one when testing is finished and want to go "live"
df <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv', show_col_types = FALSE)

# uncomment and use for testing in R after importing dataset in top right box with readr 
# as chart_data.csv after download from testMetrics.cfm 

#df <- chart_data

df$COLLECTIONS <- c("Mala", "Mamm","Ent","Orn","HerpObs","IZ","VP","IP","Herp","Cryo","SC","Ich")


dodge <- position_dodge(width = 0.2)

xmin <- min(df$SPECIMENS[1])
xmax <- max(df$SPECIMENS[5])
df %>% group_by(COLLECTIONS)
pr <- percent_rank(df$CATALOGEDITEMS/df$HOLDINGS)


 chart1 <- ggplot(df, aes(x = "", y = pr, fill = COLLECTIONS)) +
   geom_bar(stat = "identity",width = 1) +
   coord_polar("y", start=0) +
   facet_wrap(~COLLECTIONS,nrow = 3)+
   xlab("") +
   ylab("Percent of Holdings in MCZbase")

#chart1

# make sure all instances in R plots, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=1200, height=900, units=c('px'), dpi=300)

# uncomment and use print(chart1) during testing

#print(chart1)

