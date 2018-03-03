library(shiny)
library(shinydashboard)

source('directoryInput.R')

dashboardPage(
  dashboardHeader(title = "BIC"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Modeling", tabName = "train", icon = icon("tasks")),
      menuItem("Results", tabName = "results", icon = icon("eye"))
    )),
  dashboardBody(tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
  ),
  tabItems(
    tabItem(tabName = "train",
            box(title = "Select data sources",
                directoryInput('train_dir', label = 'select train directory'),
                directoryInput('val_dir', label = 'select validation directory'),
                directoryInput('test_dir', label = 'select test directory')
            ),
            box(title = "Predictions",
                directoryInput('pred_dir', label = 'select prediction directory')
            ),
            box(title = "Tune parameters",
                #fileInput("newimg", "Upload image"),
                # imageOutput("myImage"),
                numericInput("num_epoch",
                             h5("Number of Epochs"),
                             value = 1),
                numericInput("steps_epoch",
                             h5("Number of Steps per Epoch"),
                             value = 2),
                numericInput("val_steps",
                             h5("Number of Validation Steps"),
                             value = 5),
                actionButton("do", "Start training")

            )),
    tabItem(tabName = "results",
            box(title = "Model training history",
                plotOutput("viz")
            ),
            box(title = "Prediction results",
                dataTableOutput("batch_predict")
            )

            # textOutput("results"),
            #textOutput("image_classify"),

    )
  )
  )
)
