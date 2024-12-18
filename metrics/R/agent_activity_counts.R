# Read in the libraries
library(readr)
library(ggplot2)
library(dplyr)
library(patchwork)
library(svglite)
#agents_roles <- read_csv('C:/Users/mih744/RedesignMCZbase/metrics/datafiles/agent_activity_counts.csv', show_col_types=FALSE)
agents_roles <- read_csv('/var/www/html/arctos/metrics/datafiles/agent_activity_counts.csv', show_col_types = FALSE)
# removes NAs
agents_data <- agents_roles[complete.cases(agents_roles), ]


# Unite AgentID and AgentName to create a unique AgentInfo combination
agents_data_name <- agents_data %>%
  mutate(AgentInfo = paste(AGENT_ID, AGENT_NAME, sep = " - "))

agents_data_role <- agents_data_name %>%
  mutate(Role = paste(TABLE_NAME, COLUMN_NAME, sep = "."))

agents_data_sorted <- agents_data_role %>%
  arrange(AgentInfo)

agents_data_sorted$AgentInfo <- substr(agents_data_sorted$AgentInfo,1,18) 
# Calculate total counts per AgentInfo
total_counts <- agents_data_sorted %>%
  group_by(AgentInfo) %>%
  summarize(TotalCount = sum(COUNT)) %>%
  ungroup()


###############code finds outliers
# any(is.na(agents_data_role$AgentInfo))  # Check for any NA values

total_counts <- total_counts %>%
  mutate(TotalCount = as.numeric(TotalCount))

suppressWarnings({
total_counts_filtered <- total_counts %>%
  dplyr::filter(TotalCount > 1700)
})
#head(total_counts_filtered)
# Create the RoleLabel by combining RoleNumber and Role
# Assign RoleNumbers and automate factor conversion
agents_data_sorted <- agents_data_sorted %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    AdjustedCount = ifelse(COUNT <= 0, 1, ifelse(COUNT > 1, COUNT+100, COUNT)), 
    Role = factor(Role, levels = unique(Role))  # Automatically set factor levels
  )
##############code above finds outliers
# Set threshold for outliers
threshold <- 100000
suppressWarnings({
# Determine which agents are outliers based on total count
outliers_agents <- total_counts_filtered %>%
  dplyr::filter(TotalCount > threshold) %>%
  pull(AgentInfo)
})
####################make legend
# ALL BARS ORDER: tallest bars to the left
# Add all agent Role counts and determine ORDER of AGENTS; Set levels for AgentInfo based on sorted order
total_counts_sorted <- total_counts_filtered %>% 
  arrange(desc(TotalCount))

# Assign and connect the role numbers to the roles based on the order in the datasheet
# find a way to order them by the agents and not by position
role_order <- c(agents_data_sorted$Role[1:26])
role_numbers <- setNames(1:length(role_order), role_order)

suppressWarnings({
# Separate main data and outliers based on identified agents
main_data <- agents_data_sorted %>%
  dplyr::filter(!AgentInfo %in% outliers_agents)
})

suppressWarnings({
outliers <- agents_data_sorted %>%
  dplyr::filter(AgentInfo %in% outliers_agents)
})

# PER PERSON ORDER: Order stacks within each person by their count in the main_data
main_data <- main_data %>%
  arrange(AgentInfo, desc(AdjustedCount))
outliers <- outliers %>%
  arrange(AgentInfo, desc(AdjustedCount))

main_data$AgentInfo <- factor(main_data$AgentInfo, levels = total_counts_sorted$AgentInfo)
outliers$AgentInfo <- factor(outliers$AgentInfo, levels = total_counts_sorted$AgentInfo)

main_data <- na.omit(main_data)
# The display is below: Define a custom palette corresponding to the roles
palette <- c("#E69F00","#FF4500","#006400","#03839c","#d24678",
             "#665433","#5928ed","#0073e6","#8b0000","#8B008B",
             "#00008b","#a0522d","#2f2f2f","#e22345","#984ea3",
             "#6A5ACD","#cd4b19","#2e8b57","#ff7f00","#394df2",
             "#096d28","#4b0082","#a892f5","#f00000","#334445",
             "#a8786f","#5a5a5a","#0072B2","#657843","#a65628",
             "#f75147","#8B3a3a","#56B4E9","#234b34","#432666",
             "#b53b56","#708090","#4682b4","#106a93","#b51963",
             "#556B2F","#483D8B","#c42e24","#4daf4a","#2f4f4f"
)

# Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_data_sorted$RoleLabel)

# Main plot for standard range, exclude full stacks that are moved to outliers
main_plot <- ggplot(main_data, aes(x = AgentInfo, y = AdjustedCount, fill=Role)) +
  geom_bar(stat = "identity", position = "stack") +
  guides(color = guide_legend(title = "Agent Role Legend")) +
  geom_text(aes(label = ifelse(AdjustedCount > 3000, 
                paste0(as.integer(factor(Role)), ""), "")),  
                position = position_stack(vjust = 0.5),
                size = 1, color = "white"
                ) +
  labs(title = "Counts by Role and Agent",
       x = "Agent Info",
       y = "COUNT (<= 100,000)", 
       fill = "") +
  scale_color_manual(values = palette) +
  scale_fill_manual(values = c(palette), labels = unique(agents_data_sorted$RoleLabel)) +
  scale_y_continuous(labels = scales::comma, expand = c(0.02, 0.02)) +
  theme_minimal() +
  theme(plot.title = element_text(size=unit(7,"pt"), face="bold"), 
        axis.text.x = element_text(size=unit(3.2,"pt"),angle =50, hjust = 1),
        axis.text.y = element_text(size=unit(3.2,"pt")),
        axis.title.x = element_text(size=unit(5,"pt")),
        axis.title.y = element_text(size=unit(5,"pt")) 
  )  

# Outliers plot, now includes whole removed stacks
outliers_plot <- ggplot(outliers, aes(x = AgentInfo, y = AdjustedCount, fill = Role)) +
  geom_bar(stat = "identity", 
           position = "stack"
           ) + 
  geom_text(aes(label = ifelse(AdjustedCount > 10000, 
                paste0(as.integer(factor(Role)), ""), "")), 
                size = 1, color = "white", position=position_stack(vjust=0.5)
                ) +
  scale_fill_manual(values = palette, 
                    labels = unique(agents_data_sorted$RoleLabel),
                    guide="none"
                    ) +
  scale_y_continuous(labels = scales::comma) + 
  theme_minimal() +
  labs(title = "Outliers", 
       x = NULL, 
       y = "COUNT (> 100000)", 
       fill = NULL
       ) +
  theme(plot.title = element_text(size=unit(7,"pt"), face="bold"), 
        axis.text.x = element_text(size=unit(3.2,"pt"),angle =50, hjust = 1),
        axis.text.y = element_text(size=unit(3.2,"pt")),
        axis.title.y = element_text(size=unit(5,"pt")),
        axis.title.x = element_text(size=unit(5,"pt"))
        ) 

# Combine the plots using patchwork, place outliers to the left and merge legends
combined_plot <- main_plot + outliers_plot +
  plot_layout(guides = 'collect', widths = c(19.5, 1.5)) & 
  theme(
    legend.position = "bottom",               # Place legend at the bottom
    legend.direction = "horizontal",          # Arrange legend items in a row
    legend.box = "horizontal",            # Ensure across-the-page spread
    legend.key.size = unit(0.15, "cm"),        # Adjust the size of the legend key (o.3 -1 cm)
    legend.key.height = unit(0.18, "cm"),      # Optionally adjust height separately
    legend.key.width = unit(0.23, "cm"),        # Optionally adjust width separately
    legend.text = element_text(size=2),
    legend.title = element_text(size=2),
    legend.position = "left", 
    legend.spacing.x = unit(0.15, "cm"),
    legend.spacing.y = unit(0.15, "cm")
  ) 
# Display the combined plot
#print(combined_plot)

# !!!make sure all instances in R plots, environment, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/Agent_Activity.svg', plot=combined_plot, width = 7, height = 4.5)


