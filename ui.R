library(shiny)
library(ggplot2)

ui <- fluidPage(
    h1("University Ranking By Github Contribution"),
    plotOutput("rankingBarPlot", click = "rankBarClick"),
    fluidRow(
      column(7, plotOutput("repoBarPlot")),
      column(5, plotOutput("committerPiePlot"))
    )
)
