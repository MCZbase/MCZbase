#graph 1: 

library(ggplot2)

data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')

str(data)
head(data)
names(data)

ggplot(
  data = iris, 
  aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
  geom_point() +
  labs(title = "Sepal Length vs. Sepal Width by Species",
       x = "Sepal Length",
       y = "Sepal Width") +
  theme_minimal()





