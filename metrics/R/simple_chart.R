#graph 1: 

library(ggplot2)
library(png)
library(readr)
library(tidyr)
library(dplyr)
  
#data <- read.csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
#str(data)
#head(data)
#names(data)

# use this one for seeing on the webpage
#simple_chart <- read_csv('/var/www/html/arctos/metrics/datafiles/chart_data.csv')
# change to this for testing in R after importing chart_data.csv

# First, calculate means and standard deviations
simple_chart <- chart_data_14_ %>%
  group_by(COLLECTION)

simple_chart$log_holdings <- log10(simple_chart$HOLDINGS)
simple_chart$log_holdings <- round(log_holdings,digits = 2)

simple_chart$log_cataloged_items <- log10(simple_chart$CATALOGED_ITEMS)
simple_chart$log_cataloged_items <- round(simple_chart$log_cataloged_items,digits = 2)

# Bar plot for mean MPG with error bars (using standard error)
ggplot(simple_chart, aes(x = factor(COLLECTION), y = ynums)) + 
  geom_bar(stat = "identity", fill = "skyblue") + 
  geom_errorbar(aes(ymin = mean_cataloged - se_cataloged, ymax = mean_cataloged + se_cataloged), width = .2) +
  theme_minimal() + 
  labs(title = "Mean Cataloged Specimens by Collection", 
       x = "Collection", 
       y = "Specimens Cataloged")
