# /ScheduledTasks/runRAgentMetrics.cfm
#
#Copyright 2024-2025 President and Fellows of Harvard College
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
#
# R Script to generate agent activity graphic metrics/datafiles/Agent_Activity.svg'
#
# @see: /metrics/R/agent_activity_counts.R
# @see: /metrics/AgentRoles.cfm

## This will not generate the svg file if there are any errors.  
## Run this script manually through R to debug

## Prerequisite dependencies 
#
## Install required packages
# dnf install R fontconfig-devel
## fonntconfig-devel is required for install of svglite R package, which depends on systemfonts R package, which requires fontconfig/fontconfig.h
#
## Run the following as a user with permissions to write to: /usr/lib64/R/library/
# install.packages(c("readr", "ggplot2", "dplyr", "patchwork", "svglite", "stringr"))
#

# Read in the libraries
library(readr)
library(ggplot2)
library(dplyr)
library(patchwork)
library(svglite)
library(stringr)

## change to locally saved csv for running the code while developing
#agents_roles <- read_csv('C:/Users/mih744/RedesignMCZbase/metrics/datafiles/agent_activity_counts.csv', show_col_types=FALSE)
agents_roles <- read_csv('/var/www/html/arctos/metrics/datafiles/agent_activity_counts.csv', show_col_types = FALSE)
## removes NAs
agents_data <- agents_roles[complete.cases(agents_roles), ]


## Unite AgentID and AgentName to create a unique AgentInfo combination
agents_data_name <- agents_data %>%
  mutate(AgentInfo = paste(AGENT_ID, AGENT_NAME, sep = " - "))

agents_data_role <- agents_data_name %>%
  mutate(Role = paste(TABLE_NAME, COLUMN_NAME, sep = "."))

agents_data_sorted <- agents_data_role %>%
  arrange(AgentInfo)

agents_data_sorted$AgentInfo <- substr(agents_data_sorted$AgentInfo,1,20) 
## Calculate total counts per AgentInfo
total_counts <- agents_data_sorted %>%
  group_by(AgentInfo) %>%
  summarize(TotalCount = sum(COUNT)) %>%
  ungroup()


###############code finds outliers
## any(is.na(agents_data_role$AgentInfo))  # Check for any NA values

total_counts <- total_counts %>%
  mutate(TotalCount = as.numeric(TotalCount))

suppressWarnings({
total_counts_filtered <- total_counts %>%
  dplyr::filter(TotalCount > 3500)
})
#head(total_counts_filtered)
## Create the RoleLabel by combining RoleNumber and Role
## Assign RoleNumbers and automate factor conversion
agents_data_sorted <- agents_data_sorted %>%
  mutate(
    RoleNumber = as.integer(factor(Role, levels = unique(Role))),
    RoleLabel = paste0(RoleNumber, ". ", Role),
    AdjustedCount = ifelse(COUNT <= 0, 1, ifelse(COUNT > 1, COUNT+100, COUNT)), 
    Role = factor(Role, levels = unique(Role))  # Automatically set factor levels
  )
## truncates the legend values if they were to be table_name.column_name
#agents_data_sorted$RoleLabel <- substr(agents_data_sorted$RoleLabel,1,30) 

## We change the legend labels to be customized. If a new label is added, it will show as other unless added here.
agents_data_sorted <- agents_data_sorted %>%
  mutate(simplified = case_when(
    str_detect(RoleLabel,"COLL_OBJECT.LAST_EDITED_PERSON_ID") ~ "1. Last to Edit Spec. Record",
    str_detect(RoleLabel, "GEOLOGY_ATTRIBUTES.GEO_ATT_DETERMINER_ID") ~ "2. Geology Att. Determiner",
    str_detect(RoleLabel, "LAT_LONG.VERIFIED_BY_AGENT_ID") ~ "3. Georeference Verifier",
    str_detect(RoleLabel, "MEDIA_RELATIONS.CREATED_BY_AGENT_ID") ~ "4. Created Media",
    str_detect(RoleLabel, "SHIPMENT.PACKED_BY_AGENT_ID") ~ "5. Packed Loan Shipment",
    str_detect(RoleLabel, "ENCUMBRANCE.ENCUMBERING_AGENT_ID") ~ "6. Created Encumbrance",
    str_detect(RoleLabel, "LAT_LONG.DETERMINED_BY_AGENT_ID") ~ "7. Georeference Determiner",
    str_detect(RoleLabel, "TRANS.TRANS_ENTERED_AGENT_ID") ~ "8. Transactions",
    str_detect(RoleLabel, "ATTRIBUTES.DETERMINED_BY_AGENT_ID") ~ "9. Attribute Determiner",
    str_detect(RoleLabel, "COLL_OBJECT.ENTERED_PERSON_ID") ~ "10. Created Specimen Record",
    str_detect(RoleLabel, "DEACC_ITEM.RECONCILED_BY_PERSON_ID") ~ "11. Deaccession Reconciled",
    str_detect(RoleLabel, "COLLECTOR.AGENT_ID") ~ "12. Collector",
    str_detect(RoleLabel, "IDENTIFICATION_AGENT.AGENT_ID") ~ "13. Identified Specimen",
    str_detect(RoleLabel, "LOAN_ITEM.CREATED_BY_AGENT_ID") ~ "14. Created Loan",
    str_detect(RoleLabel, "PERMIT.CONTACT_AGENT_ID") ~ "15. Permit Tracker",
    TRUE ~ "other"
  ))
##############code above finds outliers
## Set threshold for outliers
threshold <- 100000

## Determine which agents are outliers based on total count
outliers_agents <- total_counts_filtered %>%
  dplyr::filter(TotalCount > threshold) %>%
  pull(AgentInfo)

####################make legend
## ALL BARS ORDER: tallest bars to the left
## Add all agent Role counts and determine ORDER of AGENTS; Set levels for AgentInfo based on sorted order
total_counts_sorted <- total_counts_filtered %>% 
  arrange(desc(TotalCount))

## Assign and connect the role numbers to the roles based on the order in the datasheet
## find a way to order them by the agents and not by position
role_order <- c(agents_data_sorted$Role[1:15])
role_numbers <- setNames(1:length(role_order), role_order)


## Separate main data and outliers based on identified agents
main_data <- agents_data_sorted %>%
  dplyr::filter(!AgentInfo %in% outliers_agents)



outliers <- agents_data_sorted %>%
  dplyr::filter(AgentInfo %in% outliers_agents)


## PER PERSON ORDER: Order stacks within each person by their count in the main_data
main_data <- main_data %>%
  arrange(AgentInfo, desc(AdjustedCount))
outliers <- outliers %>%
  arrange(AgentInfo, desc(AdjustedCount))

main_data$AgentInfo <- factor(main_data$AgentInfo, levels = total_counts_sorted$AgentInfo)
outliers$AgentInfo <- factor(outliers$AgentInfo, levels = total_counts_sorted$AgentInfo)

main_data <- na.omit(main_data)
## The display is below: Define a custom palette corresponding to the roles
cpalette <- c("#E69F00","#FF4500","#006400","#03839c","#d24678",
              "#665433","#5928ed","#0073e6","#8B008B","#8B0000",
              "#00008b","#a0522d","#2f2f2f","#e22345","#657843",
              "#708090")
## extra color-blind safe colors
    # "#984ea3","#cd4b19","#2e8b57","#ff7f00","#394df2","#096d28","#4b0082","#a892f5","#f00000","#334445",
    # "#a8786f","#5a5a5a","#0072B2","#657843","#a65628","#f75147","#8B3a3a","#56B4E9","#234b34","#432666",
    # "#b53b56","#708090","#4682b4","#106a93","#b51963","#556B2F","#483D8B","#c42e24","#4daf4a","#2f4f4f"

## Use RoleLabel for legend labels, which should be unique
legend_labels <- unique(agents_data_sorted$RoleLabel)

## Main plot for standard range, exclude full stacks that are moved to outliers
main_plot <- ggplot(main_data, aes(x = AgentInfo, y = AdjustedCount, fill=Role)) +
    geom_bar(stat = "identity", position = "stack") +
    guides(color = guide_legend(title = "Agent Role Legend")) +
    geom_text(aes(label = ifelse(AdjustedCount > 3000, 
                paste0(as.integer(factor(Role)), ""), "")),  
                position = position_stack(vjust = 0.5),
                size = 1, color = "white"  
                ) +
                labs(
                title = "Counts by Type of Action (Role) and Agent",
                x = "Agents (in rank order by number of actions)", 
                y = "Count of actions (3500 to 100,000)"
                ) +
    scale_color_manual(values=cpalette,labels=unique(agents_data_sorted$simplified)) +
    scale_fill_manual(values=cpalette,labels=agents_data_sorted$simplified) +
    scale_y_continuous(labels = scales::comma, expand=c(0.02, 0.02)) +  # removed this after comma: ", expand = c(0.02, 0.02)" makes space between labels and text smaller
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(size=rel(0.45), face="bold",family="sans"),
        plot.margin = margin(t=1,r=1,b=0,l=10),
        axis.text.x = element_text(margin=margin(t=0,b=0), size=rel(0.4), color='white', angle =0, hjust = 0),
        axis.text.y = element_text(margin=margin(t=0.25), size=rel(0.4)),
        axis.title.x = element_text(margin=margin(t=0,b=0), size=rel(0.4)),
        axis.title.y = element_text(size=rel(0.4)), 
        legend.direction = "vertical",   # Typically more space-efficient when inside plots
        legend.box = "vertical",
        legend.background = element_rect(fill=alpha('white', 0.0)), # Make the legend background transparent
        legend.key.size = unit(0.33, "lines"),
        legend.box.margin = margin(0.05, 0.05, 0.05, 0.0), # Tighten the box margin if needed
        legend.text = element_text(margin=margin(l=0.5),size=rel(0.33),hjust=0),
        legend.spacing.x = unit(0.02, "cm"),
        legend.spacing.y = unit(0.02, "cm"),
        legend.justification = c("right", "top"),
        legend.box.just = "left",
        legend.title = element_text(margin=margin(b=0.9),size=rel(0.42), hjust=0.5, family="sans"), 
        legend.margin = margin(3, 3, 3, 3)
    )

## Outliers plot, now includes whole removed stacks
outliers_plot <- ggplot(outliers, aes(x = AgentInfo, y = AdjustedCount, fill = Role)) +
      geom_bar(stat = "identity", position = "stack") + 
      geom_text(aes(label = ifelse(AdjustedCount > 100000, 
              paste0(as.integer(factor(Role)), ""), "")), 
              size = 1, color = "white", position=position_stack(vjust=0.5)
              ) +
      scale_fill_manual(values = cpalette, 
              labels = legend_labels,
              guide="none"
              ) +
      scale_y_continuous(labels = scales::comma, expand = c(0.02, 0.02)) + 
      theme_minimal(base_size = 12) +
      labs(title = "Outliers", 
              x = NULL, 
              y = "COUNT (> 100,000)", 
              fill = NULL
              ) +
      theme(plot.title = element_text(size=rel(0.45), face="bold",family="sans"), 
            axis.text.x = element_text(margin=margin(t=0,b=0), size=rel(0.4), color='white', angle =0, hjust = 0),
            axis.text.y = element_text(margin=margin(t=0.25), size=rel(0.4)),
            axis.title.x = element_text(margin=margin(t=0,b=0), size=rel(0.4)),
            axis.title.y = element_text(size=rel(0.4))
            ) 

## Combine the plots using patchwork, place outliers to the left and merge legends
combined_plot <- main_plot + outliers_plot + plot_layout(guides = 'collect', widths = c(92.5, 6.8))

 
## Display the combined plot, can have comment removed for debugging.
#print(combined_plot)

## Save the svg file to the expected location.
ggsave('/var/www/html/arctos/metrics/datafiles/Agent_Activity.svg', plot=combined_plot, width = 6.5, height = 2.8)
