# Read in the libraries
library(readr)
library(ggplot2)
library(dplyr)
library(patchwork)
library(png)
library(svglite)
#agents_roles <- read_csv('C:/Users/mih744/RedesignMCZbase/metrics/datafiles/agent_activity_counts.csv', show_col_types=FALSE)
agents_roles <- read_csv('/var/www/html/arctos/metrics/datafiles/agent_activity_counts.csv', show_col_types = FALSE)
# removes NAs
agents_data <- agents_roles[complete.cases(agents_roles), ]
#First replace.
agents_data$AGENT_ID <- as.numeric(as.character(agents_data$AGENT_ID))
agents_data$AGENT_ID[is.na(agents_data$AGENT_ID)] <- 0  # Replace NAs with 0 or another appropriate value 
# Then remove
agents_data <-  agents_data[agents_data$AGENT_ID != "0",]

# Unite AgentID and AgentName to create a unique AgentInfo combination
agents_data_name <- agents_data %>%
  mutate(AgentInfo = paste(AGENT_ID, AGENT_NAME, sep = " - "))

agents_data_role <- agents_data_name %>%
  mutate(Role = paste(TABLE_NAME, COLUMN_NAME, sep = "."))

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

suppressWarnings({
total_counts_filtered <- total_counts %>%
  dplyr::filter(TotalCount > 200)
})
#head(total_counts_filtered)
# Create the RoleLabel by combining RoleNumber and Role
# Assign RoleNumbers and automate factor conversion
agents_data_sorted <- agents_data_sorted %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    AdjustedCount = ifelse(COUNT <= 0, 1, ifelse(COUNT > 1, COUNT+50, COUNT)), 
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

# The display is below: Define a custom palette corresponding to the roles
custom_palette <- c("#E69F00","#4b0082","#006400","#03839c","#2f4f4f","#394df2",
                    "#483D8B","#4682b4","#8b0000","#8B008B","#8B3a3a","#a0522d",
                    "#708090","#b53b56","#106a93","#6A5ACD","#cd4b19","#4daf4a",
                    "#ff7f00","#665433","#096d28","#FF4500","#a892f5","#f00000",
                    "#334445","#a8786f","#5a5a5a","#0072B2","#657843","#a65628",
                    "#006400","#f75147","#c42e24","#56B4E9","#234b34","#432666",
                    "#e22345","#d24678","#0073e6","#984ea3","#b51963","#556B2F",
                    "#5928ed","#00008b","#2e8b57"
)

# Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_data_sorted$RoleLabel)

# Main plot for standard range, exclude full stacks that are moved to outliers
main_plot <- ggplot(main_data, aes(x = AgentInfo, y = AdjustedCount, fill=Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = ifelse(AdjustedCount > 5000, 
                               paste0(as.integer(factor(Role)), ""), "")
                ),  
            position = position_stack(vjust = 0.5),
            size = unit(3.5,"px"), color = "white", fontface = "bold") +
  labs(title = "Counts by Role and Agent",
       x = "Agent Info",
       y = "COUNT (<= 100,000)", 
       fill = "") +
  scale_color_manual(values = custom_palette) +
  scale_fill_manual(values = c(custom_palette), labels = unique(agents_data_sorted$RoleLabel)) +
  scale_y_continuous(labels = scales::comma, expand = c(0.02, 0.02)) +
  theme_minimal() +
  theme(plot.title = element_text(size=3, face="bold"), 
        axis.text.x = element_text(size=2.5,angle =50, hjust = 1),
        axis.text.y = element_text(size=unit(10,"px")),
        axis.title.x = element_text(size=unit(12,"px")),
        axis.title.y = element_text(size=unit(12,"px"))
  )  


# Outliers plot, now includes whole removed stacks
outliers_plot <- ggplot(outliers, aes(x = AgentInfo, y = AdjustedCount, fill = Role)) +
  geom_bar(stat = "identity", 
           position = "stack"
           ) + 
  geom_text(aes(label = ifelse(AdjustedCount > 0, 
                              paste0(as.integer(factor(Role)), ""), "")), 
                              size = 2.5,
                              color = "white",
                              position=position_stack(vjust=0.5)
                              ) +
  scale_fill_manual(values = custom_palette, 
                    labels = unique(agents_data_sorted$RoleLabel),
                    guide="none"
                    ) +
  scale_y_continuous(labels = scales::comma) + 
  theme_minimal() +
  labs(title = "Outlier Counts", 
       x = NULL, 
       y = "COUNT (> 100000)", 
       fill = NULL
       ) +
  theme(plot.title = element_text(size=4, face="bold"), 
        axis.text.x = element_text(size=4.5,angle =50, hjust = 1),
        axis.text.y = element_text(size=unit(10,"px")),
        axis.title.y = element_text(size=unit(12,"px"))
        ) 

# Combine the plots using patchwork, place outliers to the left and merge legends
combined_plot <- main_plot + outliers_plot +
  plot_layout(guides = 'collect', widths = c(12,.75)) & 
  theme(plot.title = element_text(size=3, face="bold"),legend.position = 'bottom', 
        legend.box="vertical", legend.key.size = unit(0.2, "cm"),
        legend.key.width = unit(.20, "cm"),
        legend.text = element_text(size = unit(10, "px")),
        legend.title = element_text(size = unit(10, "px")),
        legend.spacing = unit(unit(2, "px")),
        guides(fill = guide_legend(ncol = 1))
        )

# Display the combined plot
print(combined_plot)

# !!!make sure all instances in R plots, environment, Photoshop, etc are closed before refreshing webpage.
ggsave('/var/www/html/arctos/metrics/R/Agent_Activity.svg', plot=combined_plot, width = 7, height = 4.5)


