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
library(grid)
library(tidyverse)
library(purrr)
library(scales)
library(tidyverse)
library(showtext)
library(ggtext)
library(waffle)
# use to check for loading errors  
# data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# str(data)
# head(data)
# names(data)


# use this one when testing is finished and want to go "live"
df <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv', show_col_types = FALSE)

# uncomment and use for testing in R after importing dataset in top right box with readr 
# as chart_data.csv after download from testMetrics.cfm 

#local load
#df <- read_csv("C:/Users/mih744/Downloads/chart_data.csv")

# makes a column with abbreviated collections for labels
df$COLLECTIONS <- c("Mala", "Mamm","Ent","Orn","HerpObs","IZ","VP","IP","Herp","Cryo","SC","Ich")

# make calculations based on collection grouping
df %>% group_by(COLLECTIONS)

# filter out Herp Obs row
df <-df %>% 
  filter(COLLECTIONS != 'HerpObs')

# use purrr package to change the NAs to zeros so the rows don't get deleted.
df %>% mutate(across(where(is.numeric),
                      replace_na, 0))
TOTAL <- sum(df$HOLDINGS)
# create scatter plot colored by genre in different panels
ggplot(df, aes(x="", y=df$HOLDINGS, fill=COLLECTIONS)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  geom_text(aes(label = paste0(format(round(df$HOLDINGS/sum(df$HOLDINGS)*100, 1), nsmall = 0), " %")), 
            position = position_stack(vjust = .5),size=4, color="white") +
            labs(title = "Holdings per Collection", 
            caption = "Source: Annual Metrics Reported by Collections Staff") +
      theme_void()

# make sure all instances in R plots, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=1200, height=900, units=c('px'), dpi=300)

# uncomment and use print(chart1) during testing

#print(chart1)

