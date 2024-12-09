# Read in the libraries
# library(readxl)
library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(patchwork)
agents_roles <- read.csv("C:/Users/mih744/RedesignMCZbase/metrics/datafiles/Agent_roles_last.csv")
# removes NAs
agents_data <- agents_roles[complete.cases(agents_roles), ]
#First replace.
agents_data$AGENT_ID <- as.numeric(as.character(agents_data$AGENT_ID))
agents_data$AGENT_ID[is.na(agents_data$AGENT_ID)] <- 0  # Replace NAs with 0 or another appropriate value 
# Then remove
agents_data <-  agents_data[agents_data$AGENT_ID != "0",]  
# Unite AgentID and AgentName to create a unique AgentInfo combination
agents_data_name <- agents_data %>%
  unite("AgentInfo", AGENT_ID, AGENT_NAME, sep = " - ")

agents_data_role <- agents_data_name %>%
  unite("Role", TABLE_NAME, COLUMN_NAME, sep = ".")

agents_data_sorted <- agents_data_role %>%
  arrange(AgentInfo)

# Calculate total counts per AgentInfo
total_counts <- agents_data_sorted %>%
  group_by(AgentInfo) %>%
  summarize(TotalCount = sum(COUNT)) %>%
  ungroup()
###############code finds outliers
# any(is.na(agents_data_role$AgentInfo))  # Check for any NA values

total_counts <- total_counts %>%
  mutate(TotalCount = as.numeric(TotalCount))

total_counts_filtered <- total_counts %>%
  filter(TotalCount >= 5)

# Set threshold for outliers
threshold <- 150000

# Determine which agents are outliers based on total count
outliers_agents <- total_counts_filtered %>%
  filter(TotalCount > threshold) %>%
  pull(AgentInfo)
##############code above finds outliers

# Separate main data and outliers based on identified agents
main_data <- agents_data_sorted %>%
  filter(!AgentInfo %in% outliers_agents)

outliers <- agents_data_sorted %>%
  filter(AgentInfo %in% outliers_agents)

# Order stacks within each person by their count in the main_data
main_data <- main_data %>%
  arrange(AgentInfo, desc(COUNT))

####################make legend
# Set levels for AgentInfo based on sorted order
total_counts_sorted <- total_counts_filtered %>% 
  arrange(desc(TotalCount))

main_data$AgentInfo <- factor(main_data$AgentInfo, levels = total_counts_sorted$AgentInfo)
main_data$AgentInfo <- droplevels(main_data$AgentInfo)  # Remove unused levels

# Redefine the factor in-case it's defined with extra levels before
main_data$AgentInfo <- factor(main_data$AgentInfo)
# Assign and connect the role numbers to the roles based on the order in the datasheet
# find a way to order them by the agents and not by position
role_order <- c(agents_data_sorted$Role[1:26])
role_numbers <- setNames(1:length(role_order), role_order)

# Create the RoleLabel by combining RoleNumber and Role
# Assign RoleNumbers and automate factor conversion
agents_data_sorted <- agents_data_sorted %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    #  AdjustedCount = ifelse(COUNT <= 0, 0.1, ifelse(COUNT >1, COUNT+1, COUNT)), 
    Role = factor(Role, levels = unique(Role))  # Automatically set factor levels
  )

# The display is below:
# Define a custom palette corresponding to the roles
custom_palette <- c("#4b0082","#8b0000","#106a93","#cd4b19","#b53b56","#00008b","#2e8b57","#2f4f4f",
                    "#6A5ACD","#483D8B","#4daf4a","#DAA520","#ff7f00","#708090","#665433","#a0522d",
                    "#096d28","#a892f5","#E69F00","#f00000","#334445","#a8786f","#377eb8","#00008b",
                    "#5a5a5a","#556B2F","#0072B2","#5F9EA0","#657843","#a65628","#f781bf","#006400",
                    "#483D8B","#f75147","#56B4E9","#fbefb6","#234b34","#432666","#8B3a3a","#ffe444",
                    "#4682b4","#984ea3","#8B008B","#CC79A7","#c59f00","#03839c","#ff43E9","#b51963",
                    "#5928ed","#708090","#98dda7","#c44601","#394df2","#d796ed","#0073e6","#c42e24",
                    "#e22345","#d24678")

# Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_data_sorted$RoleLabel)

# Main plot for standard range, exclude full stacks that are moved to outliers
main_plot <- ggplot(main_data, aes(x = AgentInfo, y = COUNT, fill = Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = ifelse(COUNT > 10, paste0(as.integer(factor(Role)), ""), "")),  # Conditionally show label
            position = position_stack(vjust = 0.5), 
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = custom_palette, labels = unique(agents_data_sorted$RoleLabel)) +
  scale_y_continuous(labels = scales::comma, expand = c(0.02, 0.02)) +
  theme_minimal() +
  theme(axis.text.x = element_text(size=9,angle =50, hjust = 1)) +
  theme(
    legend.position = "none"
  )


# Outliers plot, now includes whole removed stacks
outliers_plot <- ggplot(outliers, aes(x = AgentInfo, y = COUNT, fill = Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = ifelse(COUNT > 10000, paste0(as.integer(factor(Role)), ""), "")),  # Conditionally show label
            position = position_stack(vjust = 0.5), 
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = custom_palette, labels = unique(agents_data_sorted$RoleLabel)) +
  scale_y_continuous(labels = scales::comma) +
  theme_minimal() +
  #  labs(title = "Outlier Counts", x = NULL, y = "COUNT (> 10000)", fill = NULL) +
  theme(axis.text.x = element_text(size=8,angle =50, hjust = 1))
#+ theme(legend.position = "none")  # Suppress legend in this plot

# Combine the plots using patchwork, place outliers to the left and merge legends
combined_plot <- main_plot + outliers_plot +
  labs(title = "Counts by Role and Agent", x = "Agent Info", y = "COUNT (<= 10,000)", fill = "Role Legend") 
combined_plot <- main_plot + outliers_plot + plot_layout(guides = 'collect', widths = c(11.5,.5)) & 
  theme(legend.position = 'bottom', legend.box="vertical", legend.key.size = unit(0.3, "cm"),
        legend.key.width = unit(.23, "cm"),legend.text = element_text(size = 8),
        legend.spacing = unit(5, "cm"),guides(fill = guide_legend(ncol = 1)),
  )
# Display the combined plot
print(combined_plot)



# !!!make sure all instances in R plots, environment, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/agent_role_chart.png', combined_plot, width=1, height=11, units="in", dpi=96)
