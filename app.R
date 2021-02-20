## app.R ##
library(shiny)
library(shinydashboard)
library(dplyr)
library(data.table)
options(shiny.maxRequestSize = 0.015*1024^2)

ui <- dashboardPage(
  dashboardHeader(title = "dplyr to SQL translator"),
  dashboardSidebar(
  
    
fileInput("dataset", "Upload CSV file. Size limit is 15kb; only upload header and first row. Ideally, replace the data from the first row by mock data from the same type. This is sufficient to get the SQL translation back. The data does not get saved anyways (check the app's source code if you don't believe me) but that's not a reason to upload your company's quarterly turnover.",
          multiple = FALSE,
          accept = c("text/csv",
                     "text/comma-separated-values,text/plain",
                     ".csv")),

includeHTML("include.html")

  ),
  dashboardBody(
    tags$head(
           tags$style(HTML('
.skin-blue .main-header .logo {
    background-color: #002b36;
}
.skin-blue .main-header .navbar{
    background-color: #002b36;
}
.content-wrapper, .right-side{
    background-color: #002b36;
    color: #FFFFFF;
}
.main-sidebar.main-sidebar {
    background-color: #002b36;
}
'))
           
         ),

    fluidRow(
      textAreaInput("source_code", "Input your dplyr code here. The name of your data set needs to be \"dataset\" in the code below. You can delete the example code.", "dataset %>% summarise(n_rows = n())"),
      actionButton("translate", "Get translation"),
      textOutput("sql_code", container = span)
    )
  )
)

server <- function(input, output) {

  con <- DBI::dbConnect(RSQLite::SQLite(), dbname = ":memory:")


  output$sql_code <- renderText({
    req(input$dataset)
    input$translate
    dataset <- fread(input$dataset$datapath)

    copy_to(con, dataset, "dataset", overwrite = TRUE)

    dataset <- tbl(con, "dataset")

    sql_query <- isolate(capture.output(show_query(eval(parse(text = input$source_code)))))
    sql_query <- sql_query[2:length(sql_query)]
    sql_query <- gsub("`", "", sql_query)
    sql_query
  })
}

shinyApp(ui = ui, server = server)
