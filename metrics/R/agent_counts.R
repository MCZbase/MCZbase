# Load necessary libraries
library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)

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

role_order <- c(agents_long$Role[0:18])
role_numbers <- setNames(0:length(role_order), role_order)


# Create the RoleLabel by combining RoleNumber and Role
# Assign RoleNumbers and automate factor conversion
agents_long <- agents_long %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    AdjustedCount = ifelse(Count == 0, 0.1, ifelse(Count >1, Count+250, Count)), 
    Role = factor(Role, levels = unique(Role))  # Automatically set factor levels
  )

# Define a custom palette corresponding to the roles
custom_palette <- c("attribute_determiner"="#4b0082","cat_items_entered_by"="#8b0000","cat_items_last_edited_by"="#006400","citations"="#00008b","collected_specimens"="#2e8b57","encumbrance"="#2f4f4f","georef_created"="#6A5ACD","georef_verified"="#DAA520","id_determiner"="#483D8B","media_created_by"="#4682b4","media_labels"="#5F9EA0","media_relationships"="#8B008B","permits_rights"="#5a5a5a","prepared_specimens"="#8B3a3a","publication_total"="#a0522d","reconciled_loans"="#556B2F","shipments"="#FF4500","transactions"="#708090")



# Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_long$RoleLabel)

cbrt_trans <- scales::trans_new(
  name = "cbrt",
  transform = function(x) sign(x) * abs(x)^(1/3), # Cubic root transformation
  inverse = function(x) sign(x) * (abs(x)^3)     # Inverse of cubic root
)

# Plot with RoleLabel in the legend, ensuring consistent mapping # Only show RoleNumber on bars  # Apply cubic root transformation
ggplot(agents_long, aes(x = AgentInfo, y = AdjustedCount, fill = Role)) +
  geom_bar(stat = "identity", position = "stack") +
  geom_text(aes(label =  ifelse(AdjustedCount >= 250, RoleNumber, "")),  
            position = position_stack(vjust = 0.5),
            size = 2.5, color = "white", fontface = "bold") +
  scale_fill_manual(values = custom_palette, 
                    breaks = role_order,
                    labels = legend_labels) +
  scale_y_continuous(trans = cbrt_trans, 
                     labels = scales::comma, expand = c(0.02, 0.02)) +
  theme_minimal() +
  labs(title = "Counts by Role and Agent", x = "Agent Info", y = "Count", fill = "Role Legend") +
  theme(axis.text.x = element_text(angle =50, hjust = 1)) +
  theme(legend.position = "right")



