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


Cit2 <- filter(CitationCountsColl2, Number.of.cataloged.items >= 1)
Cit3 <- filter(CitationCountsColl2, Number.of.types.with.images >= 1)
Cit4 <- filter(CitationCountsColl2, Number.of.types.with.images >= 1)
Cit4 <- filter(CitationCountsColl2, Entered.Date >= 1800)

cit4Anim <- ggplot(Cit4, aes(Number.of.cataloged.items, Number.of.images, size = Number.of.types.with.images, 
                 colour = TYPE_STATUS, guide_colourbar(title = "Types with Images" ))) +
  geom_point(alpha = 0.7, show.legend = TRUE) +
  scale_fill_gradient2(low="#075AFF",mid="#ffffcc",high="#FF0000") +
  scale_size(range = c(2, 12)) +
  scale_x_log10() +
  facet_wrap(~COLLECTION_CDE) +
  # Here comes the gganimate specific bits
  labs(title = 'Year: {frame_time}', x = 'Number of Cataloged Items', y = 'Number of Images') +
  transition_time(Entered.Date) +
  ease_aes('linear')
anim_save("images_per_catnum_per_year.gif")
cit4Anim
