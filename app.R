library(shiny)
library(tidyr)
library(readr)
library(dplyr)
library(ggplot2)
library(ggraph)
library(tidygraph)

# Load preprocessed data
commits <- read_csv("data/commits.csv")
commits_by_committer <- read_csv("data/commits_by_committer.csv")
commits_by_institution <- read_csv("data/commits_by_institutions.csv")
network <- read_csv("data/network.csv")

# Bar plot for the general ranking
barplot_institution <- function(commits_by_institution){
  commits_by_institution$group<-cut(commits_by_institution$commit_per_committer, 
                                    breaks = c(0,50,80,100,150,200,800))
  ggplot(commits_by_institution) +
    geom_bar(
      aes(institution_commit, reorder(institution, institution_commit), fill = group),
      width = 1, stat = "identity"
    ) +
    scale_fill_brewer(palette = "YlOrRd") +
    scale_x_continuous(label = scales::label_number_si(), expand = c(0, 0, 0.1, 0.1)) + # remove scientific notation. scales::comma() is also useful.
    labs(title = "GitHub Ranking (click on school to reveal more details)",
         x = "Accumulated GitHub commits",
         y = "Institution",
         fill = "Commit per committer") +
    theme(
      axis.text.y = element_text(),
      axis.ticks = element_blank(),
      panel.grid.major.y = element_blank(),
      plot.title = element_text(hjust = 0.5, size=20)
    )
}


# Pie plot for top-ranking committers from the selected institution
pieplot_committer <- function(selected_institution, commits_by_committer, commits_by_institution){
  # select the top 5 committers
  top_commiters_from_institution <- commits_by_committer %>%
    filter(institution == selected_institution) %>%
    group_by(name) %>%
    summarise(num_commit = sum(committer_commit)) %>%
    slice_max(order_by = num_commit, n = 5) %>%
    select(name, num_commit)
  
  # calculate "others"
  institution_commit = (commits_by_institution %>% filter(institution==selected_institution))$institution_commit
  others = data.frame("others", institution_commit - sum(top_commiters_from_institution$num_commit))
  names(others)=c("name","num_commit") 
  top_commiters_from_institution = rbind(top_commiters_from_institution,others) 
  
  ggplot(top_commiters_from_institution, aes(x="", y=num_commit, fill=name)) +
    geom_bar(stat="identity", width=1) +
    coord_polar("y", start=0)  + 
    geom_text(aes(label = paste0(round(100*num_commit/institution_commit,digits=0), "%")), position = position_stack(vjust=0.5)) +
    labs(title = paste("TOP 5 Power Contributers at ", selected_institution, sep =""),
         x = NULL, 
         y = NULL) +
    theme_classic() +
    theme(axis.line = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank(),
          plot.title = element_text(hjust = 0.5, size=20)
          )
}

# Bar plot for the top-ranking repositories from the selected institution
barplot_repo <- function(selected_institution, commits){
  commits_by_institution_and_repo <- commits %>% 
    filter(institution == selected_institution) %>%
    group_by(repo_name) %>%
    summarize(repo_commit = sum(num_commits)) %>%
    drop_na() %>%
    slice_max(order_by = repo_commit, n = 30)
  
  ggplot(commits_by_institution_and_repo) +
    geom_bar(
      aes(repo_commit, reorder(repo_name, repo_commit)),
      width = 1, stat = "identity",
      fill = 'lightblue'
    ) +
    scale_x_continuous(label = scales::label_number_si(), expand = c(0, 0, 0.1, 0.1)) + # remove scientific notation. scales::comma() is also useful.
    labs(title = paste("TOP 30 Repositories Contribued by ", selected_institution, sep =""),
         x = "Number of GitHub commits", 
         y = "Repo") +
    theme(
      axis.text.y = element_text(),
      axis.ticks = element_blank(),
      panel.grid.major.y = element_blank(),
      plot.title = element_text(hjust = 0.5, size=20)
    )
}

# Node-link diagram for the connections of academic institutions
network_institution <- function(selected_institution){
  institution_network <- network %>%
    group_by(src_institution, dst_institution) %>%
    summarize(value=n()) %>%
    filter(src_institution != dst_institution & value > 20)
  
  E <- data.frame(
    source = institution_network$src_institution,
    target = institution_network$dst_institution,
    value = institution_network$value
  )
  
  G <- as_tbl_graph(E, directed = FALSE)
  
  G <- G %>%
    activate(edges) %>%
    mutate(connection_strength = runif(value))
  
  ggraph(G, layout = 'fr') + 
    geom_edge_link(aes(col=connection_strength), alpha = 0.5) +
    geom_node_label(aes(label = name, color=ifelse(name == selected_institution, "#ff0000", "#000000"))) +
    coord_fixed() +
    theme_void() +
    scale_edge_colour_viridis() + 
    scale_color_identity() +
    guides(edge_width = FALSE) + 
    ggtitle(paste("Connections Between Academic Institutions: Highlighting ", selected_institution, sep ="")) + 
    theme(plot.title = element_text(hjust = 0.5, size=20))
}


# Define UI 
ui <- fluidPage(
    h1("University Ranking By Github Contribution"),
    h5("initial loading may take a few seconds"),
    plotOutput("rankingBarPlot", click = "rankBarClick"),
    plotOutput("institution_network", width = "100%", height = "600px"),
    fluidRow(
      column(7, plotOutput("repoBarPlot")),
      column(5, plotOutput("committerPiePlot"))
    ),
)


# Define server logic
server <- function(input, output) {
    global <- reactiveValues(
      toHighlight = rep(FALSE, length(commits_by_institution$institution)), 
      selectedBar = 'wisc')
    observeEvent(eventExpr = input$rankBarClick, {
      global$selectedBar <- commits_by_institution$institution[1+nrow(commits_by_institution)-round(input$rankBarClick$y)]
      global$toHighlight <- commits_by_institution$institution %in% global$selectedBar
    })
    output$rankingBarPlot <- renderPlot({barplot_institution(commits_by_institution)})
    output$committerPiePlot <- renderPlot({pieplot_committer(global$selectedBar, commits_by_committer, commits_by_institution)})
    output$repoBarPlot <- renderPlot({barplot_repo(global$selectedBar, commits)})
    output$institution_network <- renderPlot({network_institution(global$selectedBar)})
}


# Run the application 
shinyApp(ui = ui, server = server)

