## summary of types per collection
## Years are great than or equal to 1770; there are a few non-dates in the data; 
## The made dates were not filled out on more than half of the specimen records so I used date entered.
## Years used on x-axis, specimen number listed on y, and collections are color coded
## when we roll over the dots, information about year, Collection, type status, and specific count comes up.
## top type status was used - in other words current type status

library(tibble)
library(dplyr)
library(ggplot2)
library(plotly)
library(tidyr)

#prepare data by filtering stange dates (non-dates) before 1770
typesRecentAll <- filter(count_type_collection3, YYYY >= 1770 )
types5 <- filter(typesRecentAll)
colnames(types5)
names(types5)[4] <- 'YEAR'
colnames(types5)
names(types5)[3] <- 'COLLECTION'
colnames(types5)
names(types5)[2] <- 'TYPE'
colnames(types5)
#Type status vs Collection with color coded specimen
p2 <- ggplot(types5, aes(x=YEAR,y=SPECIMENS,color=COLLECTION,group=interaction(TYPE,COLLECTION))) +
  geom_point(size=2) + geom_line() + 
  labs(title="Types per Year ",
       x="YEAR (1770 to present)",
       y="Specimens per Type",
       color="SPECIMENS",
       caption = "Source: MCZbase") 
ggplotly(p2)
