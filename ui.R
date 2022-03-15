library(shiny)
library(ggplot2)

ui <- fluidPage(
    h3("g-index ranking"),
    plotOutput("rankingBarPlot", click = "rankBarClick"),
    fluidRow(
      column(6, plotOutput("repoBarPlot")),
      column(6, plotOutput("committerPiePlot"))
    )
)
