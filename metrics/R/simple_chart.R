# make sure permissions and ownership are correct on png folders/files in directory via ssh

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
#df <- read_csv("C:/Users/mih744/Downloads/chart_data.csv")

# make calculations based on collection grouping
#df %>% group_by(COLLECTIONS)

# filter out Herp Obs row (only 47 rows -- outlier)
filter <- !(df$CATALOGEDITEMS == 47)
df <- df[filter, ]

# makes a column with abbreviated collections for labels after changing export procedure query insert line
# and creating a new column in cf_temp_chart_data
df$COLLECTIONS <- c("Mala","Mamm","Ent","Orn","IZ", "VP","IP","Herp","Cryo","SC", "Ich")

chart1 <- ggplot(df, aes(x="", y=CATALOGEDITEMS, fill=COLLECTION )) +
  geom_bar(stat="identity", width=1) +
  coord_polar("y", start=0) +
  labs(title = "Cataloged Items per Collection (data range: today minus one year)", 
       caption = "Source: Cataloged Items from MCZbase") +
 theme_void()
# uncomment and use chart or print(chart1) during testing
#chart1

# !!!make sure all instances in R plots, environment, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/graphs/chart1.png', chart1, width=7, height=5, units="in", dpi=96)


