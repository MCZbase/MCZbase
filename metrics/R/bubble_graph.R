#graph 1: transitioning through time
#animation set up
library(gganimate)
library(tibble)
library(tidyverse)
library(ggplot2)
library(dplyr)
library(plotly)
library(gapminder)
library(ggthemes)
library(gifski)
library(png)
library(ggthemes)

Cit1 <- filter(Chart_Data_Img_per_year, NUMBER_CATALOG_ITEMS >= 1)
Cit2 <- filter(Chart_Data_Img_per_year, NUMBER_OF_TYPES_WITH_IMAGES >= 0)
Cit3 <- filter(Chart_Data_Img_per_year, ENTERED_DATE >= 1800)


BubbleAnim <- ggplot(Cit3, aes(NUMBER_CATALOG_ITEMS, NUMBER_OF_IMAGES, shape = NUMBER_OF_TYPES_WITH_IMAGES, 
              colour = TYPE_STATUS, guide_colourbar(title = "Types with Images" ))) +
  geom_point(size=5,alpha = 0.9, show.legend = TRUE) +
  scale_fill_gradient2(low="#075AFF",mid="#ffffcc",high="#FF0000") +
  scale_shape_binned() +
 # scale_x_log10() +
 # facet_wrap(~CITATION_TYPE) +
  
  # Here comes the gganimate specific bits
  labs(title = 'Year: {frame_time}', x = 'Number of Cataloged Items', y = 'Number of Images') +
  transition_time(ENTERED_DATE) +
  ease_aes('linear')

#pdf("Citation_Images.pdf")
#print(BubbleAnim)
#save_animation("Citation_Images.gif")
print(g) # print first
anim_save("Citation_Images.gif",animation = g)
BubbleAnim

