## summary of types per collection
## greater than 50 specimens per type - This means that recent types are not captured since most of 
#### them were introduced years before.
## collection_cde used on x-axis, type statuses listed on y, and specimen numbers are color coded
## when we roll over the dots, information about Collection, type status, and specific count comes up.
### BULLSEYE CHART
library(ggplot2)
#library(plotly)
#library(dplyr)
#library(tidyr)

#types1 <- filter(count_type_collection2, SPECIMENS >= 50) 

#colnames(types1)
#names(types1)[3] <- 'COLLECTION'
#colnames(types1)
#names(types1)[2] <- 'TYPE_STATUS'
#colnames(types1)

#p3a <- ggplot(types1, aes(x=COLLECTION, y=TYPE_STATUS, color=SPECIMENS, group=interaction(TYPE_STATUS,COLLECTION)))+
#  geom_point(size=2)+geom_line()+ylab("TYPE STATUS") + xlab("COLLECTION")
#ggplotly(p3a)

# Create a basic scatter plot
ggplot(
  data = chart_data, 
  aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
  geom_point() +
  labs(title = "Sepal Length vs. Sepal Width by Species",
       x = "Sepal Length",
       y = "Sepal Width") +
  theme_minimal()
