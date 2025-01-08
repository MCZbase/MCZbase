# Libraries
library(ggraph)
library(igraph)
library(tidyverse)
library(RColorBrewer) 
library(readr)
agents_roles <- read_csv('C:/Users/mih744/RedesignMCZbase/metrics/datafiles/agent_activity_counts.csv', show_col_types=FALSE)

df1 <-data.frame(specimens_augmented = c("attributes.determined_by_agent_id", 
                                        "media_relations.created_by_agent_id", 
                                        "geology_attributes.geo_att_determiner_id",
                                        "lat_long.determined_by_agent_id",
                                        "lat_long.verified_by_agent_id"),
                              counts = c(13370,3834,0,3341,4109))
                
df2 <- data.frame(specimens_entered = c("coll_object.entered_person_id"),
                             counts = c(2848))
                
df3 <- data.frame(specimens_edited = c("coll_object.last_edited_person_id"),
                            counts = c(2848))

df4 <- data.frame(activities_tracked =  c("permit.contact_agent_id", 
                                     "loan_item.created_by_agent_id", 
                                     "deacc_item.reconciled_by_person_id", 
                                     "encumbrance.encumbering_agent_id", 
                                     "trans.trans_entered_agent_id", 
                                     "shipment.packed_by_agent_id"),
                              counts = c(718,0,858,2834,0,520))

df5 <- data.frame(collected_specimens = c("collector.agent_id"), 
                              counts = c(678))

# create a data frame giving the hierarchical structure of your individuals
d0 <- data.frame(group = c("specimens_entered","specimens_edited","activities_tracked","collected_specimens","specimens_augmented"))
d1 <- data.frame(from="origin", "origin", "origin","origin","origin",
                 to= c(df1$specimens_augmented,df2$specimens_entered,df3$specimens_edited,df4$activities_tracked,df5$collected_specimens))
d2 <- data.frame(from=rep(d1$to,each=5), to=paste("subgroup", seq(1,5), sep="_"))
edges=rbind(d1, d2)

# create a vertices data.frame. One line per object of our hierarchy
vertices = data.frame(
  name = unique(c(as.character(edges$from), as.character(edges$to))) , 
  value = runif(11)
) 
# Let's add a column with the group of each name. It will be useful later to color points
vertices$group = edges$from[ match( vertices$name, edges$to ) ]


#Let's add information concerning the label we are going to add: angle, horizontal adjustement and potential flip
#calculate the ANGLE of the labels
vertices$id=NA
myleaves=which(is.na( match(vertices$name, edges$from) ))
nleaves=length(myleaves)
vertices$id[ myleaves ] = seq(1:nleaves)
vertices$angle= 90 - 360 * vertices$id / nleaves

# calculate the alignment of labels: right or left
# If I am on the left part of the plot, my labels have currently an angle < -90
vertices$hjust<-ifelse( vertices$angle < -90, 1, 0)

# flip angle BY to make them readable
vertices$angle<-ifelse(vertices$angle < -90, vertices$angle+180, vertices$angle)

# Create a graph object
mygraph <- graph_from_data_frame( edges, vertices=vertices )

# Make the plot
ggraph(mygraph, layout = 'dendrogram', circular = TRUE) + 
  geom_edge_diagonal(colour="grey") +
  scale_edge_colour_distiller(palette = "RdPu") +
  geom_node_text(aes(x = x*1.15, y=y*1.15, filter = leaf, label=name, angle = angle, 
                     hjust=hjust, colour=group), size=3.7, alpha=1) +
  geom_node_point(aes(filter = leaf, x = x*1.07, y=y*1.07, colour=group, size=value, alpha=0.6)) +
  scale_colour_manual(values= rep( brewer.pal(5,"Paired") , 30)) +
  scale_size_continuous( range = c(0.1,10) ) +
  theme_void() +
  theme(
    legend.position="none",
    plot.margin=unit(c(0,0,0,0),"cm"),
  ) +
  expand_limits(x = c(-1.3, 1.3), y = c(-1.3, 1.3))
##########################################

# Example data: 3-level hierarchy
library(tibble)

hierarchy_data <- tibble(
  parent = c("Root", "Root", "Root", "Root", "Root", "Level 1A", "Level 1B", "Level 1C"),
  child = c("Level 1A", "Level 1B", "Level 1C", "Level 2A", "Level 2B", "Level 2C"),
  count = c(NA, NA, NA, 5, 10, 15)  # Assuming these are counts for the "Level 2" nodes
)
library(igraph)
library(ggraph)
library(dplyr)

# Create graph from data
graph <- graph_from_data_frame(hierarchy_data)

# Add size attribute to nodes based on count
V(graph)$size <- ifelse(is.na(V(graph)$name %in% hierarchy_data$parent), hierarchy_data$count[match(V(graph)$name, hierarchy_data$child)], 1)

ggraph(graph, layout = 'dendrogram', circular = FALSE) +
  geom_edge_diagonal(aes()) +
  geom_node_point(aes(size = size), color = "steelblue") +  # Size based on count
  geom_node_text(aes(label = name), vjust = -1) +
  theme_void() +
  ggtitle("Dendrogram with 3 Levels and Node Size Proportional to Count") +
  scale_size_continuous(range = c(3, 10))  # Adjust scaling of size for clearer visibility

