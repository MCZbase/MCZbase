# HOLDINGS stores reported metric counts that include those not cataloged. 
# RECEIVEDSPECIMENS stores the sum(decode(total_parts,null,1,total_parts))
# from flat after joining on holdings to accn transactions and grouped by collection and limited by a date range for received_date.
# RECEIVEDCATITEMS stores count(distinct collection_object_id) receivedCatitems, joined on holdings to accn based on range for received_date
# ENTEREDCATITEMS stores the distinct collection_object_ids from flat 
## based on accn transactions limited by a date range for entered_date
#NCBISPECIMENS stores all other ID with NCBI up until endDate of range


# library(viridis)
# library(forcats)
# library(grid)
# library(purrr)
# library(scales)
# library(showtext)
# library(showtextdb)
# library(sysfonts)
# 

library(ggplot2)
library(ggthemes)
library(png)
library(readr)
library(ggtext)
# use this one when testing is finished and want to go "live"
#df <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv', show_col_types = FALSE)

# use to check for loading errors  
# str(data)
# head(data)
# names(data)

#local load for testing
df <- read_csv("C:/Users/mih744/Downloads/chart_data.csv")

# makes a column with abbreviated collections for labels
df$COLLECTIONS <- c("Mala", "Mamm","Ent","Orn","HerpObs","IZ","VP","IP","Herp","Cryo","SC","Ich")

# make calculations based on collection grouping
#df %>% group_by(COLLECTIONS)

# filter out Herp Obs row
df <- filter(COLLECTIONS != 'HerpObs')

TOTAL <- sum(df$HOLDINGS)

# create scatter plot colored by genre in different panels
chart1 <- ggplot(df, aes(x="", y=df$HOLDINGS, fill=COLLECTIONS)) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  labs(title = "Holdings per Collection", 
  caption = "Source: Annual Metrics Reported by Collections Staff") +
  theme_void()
# uncomment and use chart or print(chart1) during testing
chart1

# make sure all instances in R plots, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=840, height=600, units=c('px'), dpi=72)

# this was about labs in chart1 to put white percentages in the pie parts
#  geom_text(aes(label = paste0(format(round(df$HOLDINGS/sum(df$HOLDINGS)*100, 1), nsmall = 0), "")), 
#       position = position_stack(vjust = .5),size=3, color="white")

#print(chart1)

