library(shiny)
library(tidyr)
library(readr)
library(dplyr)
library(ggplot2)


# Fetch and preprocess data
#commits <- read_csv("https://dl.dropboxusercontent.com/s/b8cxtb63ed65cyp/bq-results-20220313-174259-48iohc32usq1.csv")
commits <- read_csv("bq-results-20220313-174259-48iohc32usq1.csv")
commits$institution <- extract(commits, email, into = c("institution"), "@(?:.*\\.)*(.*)\\.edu$")$institution

commits_by_committer <- commits %>% 
  group_by(name, email, institution) %>%
  summarize(committer_commit = sum(num_commits))

commits_by_institution <- commits_by_committer  %>%
  group_by(institution) %>%
  summarize(institution_commit = sum(committer_commit),
            num_committer = n(),
            commit_per_committer = institution_commit / num_committer) %>%
  drop_na() %>%
  slice_max(order_by = institution_commit, n = 30)


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
    labs(title = "GitHub Ranking (click on a school to reveal more details)",
         x = "Accumulated GitHub commits",
         y = "Institution",
         fill = "Commit per committer") +
    theme(
      axis.text.y = element_text(size = 6),
      axis.ticks = element_blank(),
      panel.grid.major.y = element_blank()
    )
}


# Pie plot for top-ranking committers from the selected institution
pieplot_committer <- function(selected_institution, commits_by_committer, commits_by_institution){
  commiters_from_institution <- commits_by_committer %>%
    filter(institution == selected_institution) %>%
    group_by(name) %>%
    summarise(num_commit = sum(committer_commit)) %>%
    slice_max(order_by = num_commit, n = 9)
  
  ggplot(commiters_from_institution, aes(x="", y=num_commit, fill=name)) +
    geom_bar(stat="identity", width=1) +
    coord_polar("y", start=0)  + 
    geom_text(aes(label = paste0(round(100*num_commit/(commits_by_institution%>%filter(institution==selected_institution))$institution_commit,digits=0), "%")), position = position_stack(vjust=0.5)) +
    labs(title = paste("Power Contributers at ", selected_institution, sep =""),
         x = NULL, 
         y = NULL) +
    theme_classic() +
    theme(axis.line = element_blank(),
          axis.text = element_blank(),
          axis.ticks = element_blank()) +
    scale_fill_brewer(palette="Blues")
}

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
    labs(title = paste("Repositories Contribued by ", selected_institution, sep =""),
         x = "Number of GitHub commits", 
         y = "Repo") +
    theme(
      axis.text.y = element_text(size = 6),
      axis.ticks = element_blank(),
      panel.grid.major.y = element_blank()
    )
}

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
}
