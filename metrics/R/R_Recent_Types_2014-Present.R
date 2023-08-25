## summary of types per collection; problem is that only 77416 types have made date so I used the 
## -- date of the specimen entry coll_object_entered_date.
## recent years (2014+) of specimens entered also having a type status
## collection_cde used on x-axis, type statuses listed on y, and specimen numbers are color coded
## when we roll over the dots, information about Collection, type status, and specific count comes up.
## top type status was used - in other words current type status

library(tibble)
library(dplyr)
library(ggplot2)
library(plotly)
library(tidyr)

#prepare data by filtering for recent years
typesRecent2014 <- filter(count_type_collection3, YYYY >=2014 )
types3 <- filter(typesRecent2014)
colnames(types3)
names(types3)[4] <- 'YEAR'
colnames(types2)
names(types3)[3] <- 'COLLECTION'
colnames(types3)
names(types3)[2] <- 'TYPE'
colnames(types3)
#Type status vs Collection with color coded specimen
p2 <- ggplot(types3, aes(x=YEAR,y=SPECIMENS,color=COLLECTION,group=interaction(TYPE,COLLECTION))) +
  geom_point(size=2) + geom_line() + 
  labs(title="Types per Year ",
       x="YEAR (2014 to Present)",
       y="Specimens per Type",
       color="SPECIMENS",
       caption = "Source: MCZbase") 
ggplotly(p2)

