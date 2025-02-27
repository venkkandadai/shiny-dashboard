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

# Combine CAS, SE, and NSAS into one dataframe
exam_data <- bind_rows(CAS, SE, NSAS)
exam_data <- merge(exam_data, students, by = "student_id", all.x = TRUE)
exam_data <- merge(exam_data, test_details, by = "test_id", all.x = TRUE)
exam_data$exam_year <- format(as.Date(exam_data$test_date), "%Y")

# UI
ui <- fluidPage(
  tags$head(tags$style(".header-container { display: flex; justify-content: space-between; align-items: center; }
                          .logo { height: 60px; }
                          .title { font-size: 24px; font-weight: bold; }")),
  div(class = "header-container",
      div(class = "title", "Wharton Street College of Medicine")
  ),
  sidebarLayout(
    sidebarPanel(
      selectInput("year", "Select Year:", choices = c("All", unique(students$year)), selected = "All"),
      selectInput("campus", "Select Campus:", choices = c("All", unique(students$campus)), selected = "All"),
      selectizeInput("student", "Select Student ID:", choices = NULL, multiple = FALSE, options = list(maxOptions = NULL)),
      selectizeInput("student_name", "Select Student Name:", choices = NULL, multiple = FALSE, options = list(maxOptions = NULL))
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Students", DTOutput("student_table")),
        tabPanel("Scores", DTOutput("score_table")),
        tabPanel("Aggregate Exam Statistics",
                 selectInput("exam", "Select Exam:", choices = unique(exam_data$exam_name)),
                 selectInput("exam_year", "Select Exam Year:", choices = c("All", unique(exam_data$exam_year)), selected = "All"),
                 selectInput("exam_campus", "Select Campus:", choices = c("All", "All Campuses Combined", unique(exam_data$campus)), selected = "All"),
                 DTOutput("exam_stats_table"),
                 tags$h4("Field Descriptions:"),
                 tags$p("School-Level Metrics: mean_score, median_score, sd_score, min_score, max_score, num_students"),
                 tags$p("National-Level Metrics: natl_mean (national), natl_sd (national), natl_perc25, natl_perc50, natl_perc75, natl_pass_rate")
        )
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
    updateSelectizeInput(session, "student", choices = c("All", unique(filtered_students()$student_id)))
    student_names <- filtered_students()
    student_names <- student_names[order(student_names$last_name, student_names$first_name), ]
    student_names <- paste(student_names$last_name, student_names$first_name, sep = ", ")
    updateSelectizeInput(session, "student_name", choices = c("All", unique(student_names)))
  })
  
  output$student_table <- renderDT({
    datatable(filtered_students())
  })
  
  filtered_scores <- reactive({
    all_scores <- bind_rows(CAS, SE, NSAS)
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
  
  filtered_exam_stats <- reactive({
    stats <- exam_data[exam_data$exam_name == input$exam, ]
    if (input$exam_year != "All") {
      stats <- stats[stats$exam_year == input$exam_year, ]
    }
    stats <- stats %>% group_by(test_id, exam_name, exam_year, campus)
    if (input$exam_campus == "All Campuses Combined") {
      stats <- stats %>% group_by(test_id, exam_name, exam_year) %>%
        summarise(mean_score = mean(Score, na.rm = TRUE),
                  median_score = median(Score, na.rm = TRUE),
                  sd_score = sd(Score, na.rm = TRUE),
                  min_score = min(Score, na.rm = TRUE),
                  max_score = max(Score, na.rm = TRUE),
                  num_students = n()) %>%
        ungroup()
    } else {
      stats <- stats %>%
        summarise(mean_score = mean(Score, na.rm = TRUE),
                  median_score = median(Score, na.rm = TRUE),
                  sd_score = sd(Score, na.rm = TRUE),
                  min_score = min(Score, na.rm = TRUE),
                  max_score = max(Score, na.rm = TRUE),
                  num_students = n()) %>%
        ungroup()
    }
    
    stats <- merge(stats, national_comparison, by = "test_id", all.x = TRUE)
    stats
  })
  
  output$exam_stats_table <- renderDT({
    datatable(filtered_exam_stats())
  })
}

# Run App
shinyApp(ui = ui, server = server)


