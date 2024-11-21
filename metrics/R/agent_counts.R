library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)
library(RColorBrewer)

# Import data from an Excel file - only 4 agents for demo - need to show name at bottom or top.
AgentDisplay1 <- read_excel("C:/Users/mih744/OneDrive - Harvard University/Desktop/AgentDisplay1.xlsx")

# Rename the data table to return to original import if needed
agents_data <- AgentDisplay1



# Step 2: Reshape data from wide to long format
agents_long <- agents_data %>%
  pivot_longer(cols = -agent_id, names_to = "Role", values_to = "Count")

# Sample lookup table with agent_id and Name
agent_names <- data.frame(
  agent_id = c('3359','15172','15180','21622','91972','92115','15187','95696','102150','109023','112230','119856'),
  Name = c('Breda','Brendan', 'Jon','Paul','Gonzalo','Diana','Hashi','John','Michelle','Emily','Jeremy','Cynthia')
)

# Ensure 'agent_id' is consistent as character type
agent_names$agent_id <- as.character(agent_names$agent_id)
agents_long$agent_id <- as.character(agents_long$agent_id)




agents_long_named <- agents_long %>%
  left_join(agent_names, by = "agent_id")

agents_long_named$Label <- paste(agents_long_named$Name, agents_long_named$agent_id, sep = " - ")
agents_long_named_filtered <- agents_long_named %>% 
  filter(Count > 0)

num_role < length(unique(agents_long_named_filtered$Role))

custom_palette <- colorRampPalette(brewer.pal(9, "Set1"))(num_roles)

# Plot using ggplot2 (stacked bar chart) with a suitable color palette for more than 12 roles
ggplot(agents_long_named_filtered, aes(x = Label, y = Count, fill = Role)) +
  geom_bar(stat = "identity") +
  theme_minimal() +
  scale_fill_manual(values = custom_palette) +  # Use a palette suitable for many colors
  scale_y_continuous(trans = scales::modulus_trans(p = 0.5),  # Square root transformation
                     breaks = scales::pretty_breaks(n = 5),
                     labels = scales::comma) +
  labs(title = "Agent Activity by Role", x = "Agent Name", y = "Role Counts") +
  theme(axis.text.x = element_text(angle =50, hjust = 1))

