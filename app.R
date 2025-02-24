library(shiny)
library(readxl)
library(ggplot2)
library(dplyr)
library(DT)

# Load Data
file_path <- "Synthetic Dashboard Data.xlsx"
students <- read_excel(file_path, sheet = "students")
CAS <- read_excel(file_path, sheet = "CAS", col_types = c("text", "text", "numeric", "text", "date"))
SE <- read_excel(file_path, sheet = "SE", col_types = c("text", "text", "numeric", "text", "date"))
NSAS <- read_excel(file_path, sheet = "NSAS", col_types = c("text", "text", "numeric", "text", "date"))
USMLE <- read_excel(file_path, sheet = "USMLE", col_types = c("text", "text", "numeric", "text", "date"))
test_details <- read_excel(file_path, sheet = "test_details")
national_comparison <- read_excel(file_path, sheet = "national_comparison")

# UI
ui <- fluidPage(
  tags$head(tags$style(".header-container { display: flex; justify-content: space-between; align-items: center; }
                          .logo { height: 60px; }
                          .title { font-size: 24px; font-weight: bold; }
                        ")),
  div(class = "header-container",
      div(class = "title", "Wharton Street College of Medicine")
  ),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Select Year:", 
                  choices = c("All", unique(students$year)), 
                  selected = "All"),
      selectInput("campus", "Select Campus:", 
                  choices = c("All", unique(students$campus)), 
                  selected = "All"),
      selectizeInput("student", "Select Student ID:", 
                     choices = NULL, multiple = FALSE, options = list(maxOptions = NULL)),
      selectizeInput("student_name", "Select Student Name:", 
                     choices = NULL, multiple = FALSE, options = list(maxOptions = NULL))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Students", DTOutput("student_table")),
        tabPanel("Scores", DTOutput("score_table"))
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  filtered_students <- reactive({
    students_filtered <- students
    if (input$year != "All") {
      students_filtered <- students_filtered[students_filtered$year == input$year, ]
    }
    if (input$campus != "All") {
      students_filtered <- students_filtered[students_filtered$campus == input$campus, ]
    }
    students_filtered
  })
  
  observe({
    updateSelectizeInput(session, "student", 
                         choices = c("All", unique(filtered_students()$student_id)))
    
    student_names <- filtered_students()
    student_names <- student_names[order(student_names$last_name, student_names$first_name), ]
    student_names <- paste(student_names$last_name, student_names$first_name, sep = ", ")
    updateSelectizeInput(session, "student_name", 
                         choices = c("All", unique(student_names)))
  })
  
  output$student_table <- renderDT({
    datatable(filtered_students())
  })
  
  filtered_scores <- reactive({
    all_scores <- rbind(CAS, SE, NSAS, USMLE)
    all_scores <- merge(all_scores, students, by = "student_id", all.x = TRUE)
    all_scores <- merge(all_scores, test_details, by = "test_id", all.x = TRUE)
    all_scores$student_name <- paste(all_scores$last_name, all_scores$first_name, sep = ", ")
    if (input$student != "All") {
      all_scores <- all_scores[all_scores$student_id == input$student, ]
    }
    all_scores[, c("student_id", "student_name", "year", "test_id", "exam_name", "Score", "Result", "test_date")]
  })
  
  output$score_table <- renderDT({
    datatable(filtered_scores())
  })
}

# Run App
shinyApp(ui = ui, server = server)



