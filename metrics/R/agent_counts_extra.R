# Read in the libraries
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)
library(patchwork)

# Import data from an Excel file - only Colls Ops agents for this demo.
AgentData <- read_excel("C:/Users/mih744/OneDrive - Harvard University/Desktop/AgentData.xlsx")

# Rename
agents_data <- AgentData

# Unite AgentID and AgentName to create a unique AgentInfo combination
agents_data <- agents_data %>%
  unite("AgentInfo", AgentID, AgentName, sep = " - ")

# Pivot longer using column selection helper
agents_long <- agents_data %>%
  pivot_longer(cols = -c(AgentInfo), names_to = "Role", values_to = "Count")

# Calculate total counts per AgentInfo
total_counts <- agents_long %>%
  group_by(AgentInfo) %>%
  summarize(TotalCount = sum(Count)) %>%
  ungroup()

# Set threshold for outliers
threshold <- 75000

# Determine which agents are outliers based on total count
outliers_agents <- total_counts %>%
  filter(TotalCount > threshold) %>%
  pull(AgentInfo)

# Separate main data and outliers based on identified agents
main_data <- agents_long %>%
  filter(!AgentInfo %in% outliers_agents)
  

outliers <- agents_long %>%
  filter(AgentInfo %in% outliers_agents)

# Order stacks within each person by their count in the main_data
main_data <- main_data %>%
  arrange(AgentInfo, desc(Count))

# Set levels for AgentInfo based on sorted order
total_counts_sorted <- total_counts %>% 
  arrange(desc(TotalCount))
main_data$AgentInfo <- factor(main_data$AgentInfo, levels = total_counts_sorted$AgentInfo)

# Assign and connect the role numbers to the roles based on the order in the datasheet
# find a way to order them by the agents and not by position
role_order <- c(agents_long$Role[1:18])
role_numbers <- setNames(1:length(role_order), role_order)

# Create the RoleLabel by combining RoleNumber and Role
# Assign RoleNumbers and automate factor conversion
agents_long <- agents_long %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    AdjustedCount = ifelse(Count == 0, 0.1, ifelse(Count >1, Count+1, Count)), 
    Role = factor(Role, levels = unique(Role))  # Automatically set factor levels
  )

# The display is below:
# Define a custom palette corresponding to the roles
custom_palette <- c("attribute_determiner"="#4b0082",
                    "cat_items_entered_by"="#8b0000",
                    "cat_items_last_edited_by"="#006400",
                    "citations"="#00008b",
                    "collected_specimens"="#2e8b57",
                    "encumbrance"="#2f4f4f",
                    "georef_created"="#6A5ACD",
                    "georef_verified"="#DAA520",
                    "id_determiner"="#483D8B",
                    "media_created_by"="#4682b4",
                    "media_labels"="#5F9EA0",
                    "media_relationships"="#8B008B",
                    "permits_rights"="#5a5a5a",
                    "prepared_specimens"="#8B3a3a",
                    "publication_total"="#a0522d",
                    "reconciled_loans"="#556B2F",
                    "shipments"="#FF4500",
                    "transactions"="#708090")

# Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_long$RoleLabel)

# Main plot for standard range, exclude full stacks that are moved to outliers
main_plot <- ggplot(main_data, aes(x = AgentInfo, y = Count, fill = Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = ifelse(Count > 900, paste0(as.integer(factor(Role)), ""), "")),  # Conditionally show label
            position = position_stack(vjust = 0.5), 
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = custom_palette, labels = unique(agents_long$RoleLabel)) +
  scale_y_continuous(labels = scales::comma, expand = c(0.02, 0.02)) +
  theme_minimal() +
  labs(title = "Counts by Role and Agent", x = "Agent Info",
       y = "Count (<= 75,000)", fill = "Role Legend") +
  theme(axis.text.x = element_text(angle =50, hjust = 1)) 

# Outliers plot, now includes whole removed stacks
outliers_plot <- ggplot(outliers, aes(x = AgentInfo, y = Count, fill = Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label = ifelse(Count > 2500, paste0(as.integer(factor(Role)), ""), "")),  # Conditionally show label
            position = position_stack(vjust = 0.5), 
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = custom_palette, labels = unique(agents_long$RoleLabel)) +
  scale_y_continuous(labels = scales::comma) +
  theme_minimal() +
  labs(title = "Outlier Counts", x = NULL, y = "Count (> 75,000)", fill = NULL) +
  theme(axis.text.x = element_text(angle =50, hjust = 1)) +
  theme(legend.position = "none")  # Suppress legend in this plot

# Combine the plots using patchwork, place outliers to the left and merge legends
combined_plot <- outliers_plot + main_plot + 
  plot_layout(guides = "collect", widths = c(1, 4))  # Adjust relative widths

# Display the combined plot
print(combined_plot)

