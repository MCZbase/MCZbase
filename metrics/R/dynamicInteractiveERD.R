install.packages("DiagrammeR")
install.packages("plumber")

library(DiagrammeR)
library(plumber)
library(readr)
data <- read_csv("C:/Users/mih744/OneDrive - Harvard University/Documents 1/SQL/dynamic_interactive_ERD_data.csv", show_col_types = FALSE)

library(plumber)
library(DiagrammeR)

#* @apiTitle ERD Generator

#* Generate a dynamic ERD
#* @get /generateERD
generateERD <- function() {
  # This example assumes that you have your data ready, modify with real data
  tables <- c("TableA", "TableB", "TableC")
  constraints <- data.frame(
    constraint_name = c("PK_A", "FK_AB", "FK_AC"),
    constraint_type = c("P", "R", "R"),
    table_name = c("TableA", "TableB", "TableC"),
    referenced_table = c(NA, "TableA", "TableA"),
    stringsAsFactors = FALSE
  )
  
  graph_code <- ""
  
  # Add nodes for each table
  for (table in tables) {
    graph_code <- paste(graph_code, sprintf("node [label = '%s']", table), sep = "\n")
  }
  
  # Add edges based on constraints
  for (i in 1:nrow(constraints)) {
    if (constraints$constraint_type[i] == "R") {
      from_table <- constraints$referenced_table[i]
      to_table <- constraints$table_name[i]
      graph_code <- paste(graph_code, sprintf("%s -> %s", from_table, to_table), sep = "\n")
    }
  }
  
  graph <- grViz(sprintf("
    digraph {
      graph [layout = dot, rankdir = TB]
      node [shape = rectangle, style = filled, fillcolor = lightblue]
      %s
    }
  ", graph_code))
  
  return(list(status = "success", graph = graph))
}

#' @plumber
function(pr) {
  pr
}