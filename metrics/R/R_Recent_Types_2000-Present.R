## summary of types per collection; problem is that only 77416 types have made date so I used the 
## -- date of the specimen entry coll_object_entered_date.
## recent years (2000+) of specimens entered also having a type status
## collection_cde used on x-axis, type statuses listed on y, and specimen numbers are color coded
## when we roll over the dots, information about Collection, type status, and specific count comes up.
## top type status was used - in other words current type status

library(tibble)
library(dplyr)
library(ggplot2)
library(plotly)
library(tidyr)

#prepare data by filtering for recently named types; years 2000 +
typesRecent <- filter(count_type_collection3, YYYY >=2000 )
types2 <- filter(typesRecent)
colnames(types2)
names(types2)[4] <- 'YEAR'
colnames(types2)
names(types2)[3] <- 'COLLECTION'
colnames(types2)
names(types2)[2] <- 'TYPE'
colnames(types2)
#Type status vs Collection with color coded specimen
p2 <- ggplot(types2, aes(x=YEAR,y=SPECIMENS,color=COLLECTION,group=interaction(TYPE,COLLECTION))) +
  geom_point(size=2) + geom_line() + 
  labs(title="Types per Year ",
       x="YEAR (2000 to Present)",
       y="Specimens per Type",
       color="SPECIMENS",
       caption = "Source: MCZbase") 
ggplotly(p2)
