library(shiny)
library(ggplot2)

ui <- fluidPage(
    h1("University Ranking By Github Contribution"),
    h5("initial loading may take a few seconds"),
    plotOutput("rankingBarPlot", click = "rankBarClick"),
    fluidRow(
      column(7, plotOutput("repoBarPlot")),
      column(5, plotOutput("committerPiePlot"))
    )
)
