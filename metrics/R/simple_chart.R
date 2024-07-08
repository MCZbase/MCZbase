# HOLDINGS stores reported metric counts that include those not cataloged. 
# RECEIVEDSPECIMENS stores the sum(decode(total_parts,null,1,total_parts))
# from flat after joining on holdings to accn transactions and grouped by collection and limited by a date range for received_date.
# RECEIVEDCATITEMS stores count(distinct collection_object_id) receivedCatitems, joined on holdings to accn based on range for received_date
# ENTEREDCATITEMS stores the distinct collection_object_ids from flat 
## based on accn transactions limited by a date range for entered_date
#NCBISPECIMENS stores all other ID with NCBI up until endDate of range
# make sure permissions and ownership are correct on png files in directory via ssh

# library(viridis)
# library(forcats)
# library(grid)
# library(purrr)
# library(scales)
# library(showtext)
# library(showtextdb)
# library(sysfonts)
# library(ggtext)

library(ggplot2)
library(ggthemes)
library(png)
library(readr)

# use this one when testing is finished and want to go "live"
df <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv', show_col_types = FALSE)

# use to check for loading errors  
# str(data)
# head(data)
# names(data)

#local load for testing
df <- read_csv("C:/Users/mih744/Downloads/chart_data.csv")

# make calculations based on collection grouping
#df %>% group_by(COLLECTIONS)

# filter out Herp Obs row (only 47 rows -- outlier)
filter <- !(df$CATALOGEDITEMS == 47)
df <- df[filter, ]

# makes a column with abbreviated collections for labels after changing export procedure query insert line
# and creating a new column in cf_temp_chart_data
df$COLLECTIONS <- c("Mala","Mamm","Ent","Orn","IZ", "VP","IP","Herp","Cryo","SC", "Ich")

# create scatter plot colored by genre in different panels
# chart1 <- ggplot(df, aes(x="", y=df$HOLDINGS, fill=COLLECTION )) +
#   geom_bar(stat="identity", width=1) +
#   coord_polar("y", start=0) +
#   labs(title = "Holdings per Collection", 
#   caption = "Source: Annual Metrics Reported by Collections Staff") +
#   theme_void()
# # uncomment and use chart or print(chart1) during testing
# chart1

chart1 <- ggplot(df, aes(x="", y=CATALOGEDITEMS, fill=COLLECTION )) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  labs(title = "Cataloged Items per Collection", 
       caption = "Source: Cataloged Items from MCZbase") +
 theme_void()
# uncomment and use chart or print(chart1) during testing
chart1



p = ggplot(df, aes(x=COLLECTION, y=CATALOGEDITEMS, fill=CATALOGEDITEMS)) +
  geom_bar(width=.5, stat="identity") + theme_light() +
  scale_fill_gradient(low="red", high="white", limits=c(4000,2000000)) +
  theme(axis.title.y=element_text(angle=0))
p + theme(axis.text.x = element_text(angle=45, vjust = 1, hjust=1))
# text with angle to avoid name overlap
p + coord_polar() + aes(x=reorder(COLLECTION, CATALOGEDITEMS)) +
  theme(axis.text.x = element_text(angle=-30)) 


# !!!make sure all instances in R plots, environment, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=7, height=5, units="in", dpi=96)
ggsave('/var/www/html/arctos/metrics/R/graphs/chart2.png', chart2, width=7, height=5, units="in", dpi=96)
# this was about labs in chart1 to put white percentages in the pie parts
#  geom_text(aes(label = paste0(format(round(df$HOLDINGS/sum(df$HOLDINGS)*100, 1), nsmall = 0), "")), 
#       position = position_stack(vjust = .5),size=3, color="white")

#print(chart1)

