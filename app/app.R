# Seating Chart

# dependencies
library("shiny")
library("tidyverse")
library("bslib")
library("showtext")
library("plotly")

# font setup
font_add_google("Open Sans", family = "open")
font_add_google("Montserrat", family = "mont")
showtext_auto()

# UI
ui <- navbarPage("Seating Chart App",
                 theme = bs_theme(bootswatch = "sandstone"),
                 nav_panel("Seating Chart",
 layout_sidebar( sidebar = sidebar(
      fileInput("file1", "Upload CSV File", accept = c(".csv")),
      numericInput("nrows", "Number of Rows", min = 1, max = 20, value = 5),
      numericInput("ncols", "Number of Columns", min = 1, max = 20, value = 5),
      actionButton("assign_seats", "Assign Seats")
    ),
    card(height = 500,
      plotlyOutput("seating_chart")  # Placeholder for the seating chart
    ),
      card(card_header("Students Not Seated"),
      verbatimTextOutput("leftover")  # Print leftover students
          )
   )
  )
 )

server <- function(input, output, session) {
  seating <- reactiveValues(data = NULL, chart = NULL, colors = NULL, nrow = NULL, ncol = NULL, leftover = NULL)
  
  observeEvent(input$file1, {
    # Read the uploaded CSV file and create a seat column
    seating$data <- read.csv(input$file1$datapath) %>%
      mutate(seat = c(1:nrow(.)))  # Create a seat column
    
    # Debugging: Check the data loaded from the CSV file
    print("Data loaded from CSV:")
    print(seating$data)
  })
  observeEvent(input$assign_seats, {
    req(seating$data)  # Ensure data is available
    # Get student information
    students <- seating$data
    num_rows <- input$nrows
    num_cols <- input$ncols
    seating$nrow <- num_rows
    seating$ncol <- num_cols
    grid <- matrix(NA, nrow = num_rows, ncol = num_cols)  # Initialize an empty grid
    colors <- rainbow(length(unique(students$group)))  # Generate colors for each group
    
    # --- Part 1: Assign Front Row Students ---
    front_row_students <- students %>% filter(frontRow == TRUE)
    
    # Assign front row seats (1st row and possibly 2nd row)
    for (i in seq_len(nrow(front_row_students))) {
      if (i <= num_cols) {
        grid[1, i] <- front_row_students$name[i]
      } else {
        grid[2, i - num_cols] <- front_row_students$name[i - num_cols]
      }
    }
    
    # Debugging: Check grid after assigning front-row students
    print("Grid after assigning front-row students:")
    print(grid)
    
    # --- Part 2: Assign Group Students ---
    other_students <- students %>% filter(frontRow == FALSE)  # Non-front-row students
    remaining_seats <- which(is.na(grid), arr.ind = TRUE)  # Get remaining empty seats
    remaining_seats <- remaining_seats[order(remaining_seats[,1], decreasing = FALSE),]
    
    # Shuffle the order of non-front-row students
    shuffled_students <- sample(other_students$name)
    
    # Ensure we do not exceed the available remaining seats
    num_students_to_seat <- min(length(shuffled_students), nrow(remaining_seats))
    
    # Assign remaining students to the empty seats
    for (i in seq_len(num_students_to_seat)) {
      seat <- remaining_seats[i, ]
      grid[seat[1], seat[2]] <- shuffled_students[i]
    }
    
    # Debugging: Check grid after assigning remaining students
    print("Grid after assigning remaining students:")
    print(grid)
    
    seating$leftover <- subset(students, !(students$name %in% grid))
    # --- Part 3: Assign Remaining Students ---
    
    # --- Part 4: Fill Empty Seats with "Empty" ---
    empty_seats <- which(is.na(grid), arr.ind = TRUE)  # Get remaining empty seats
    for (i in seq_len(nrow(empty_seats))) {
      seat <- empty_seats[i, ]
      grid[seat[1], seat[2]] <- "Empty"
    }
    
    # Debugging: Check grid after assigning empty seats
    print("Grid after assigning empty seats:")
    print(grid)
    
    # Store the seating chart
    seating$chart <- grid  # Store grid to reactive values
    
    # Create a reactive color map for the students based on groups
    seating$colors <- setNames(colors, unique(students$group))
  })
  
  output$leftover <- renderPrint({
    if (length(seating$leftover$name) < 1){
      "All students seated!"
    } else{
    seating$leftover$name
    }
  })
  
  output$seating_chart <- renderPlotly({
    req(seating$chart)  # Ensure the chart is ready
    
    # Define grid dimensions
    num_rows <- seating$nrow
    num_cols <- seating$ncol
    temp_df <- data.frame(x = seq(from = 1, to = num_cols, length.out = 5),
                          y = seq(from= 1, to = num_rows, length.out = 5)
                          )
#    # Set up the plot with no points
#    p <- ggplot(temp_df, aes(x,y))+
#      geom_blank()+
#      theme_bw()+
#      xlab("")+
#      ylab("")

    # Make a dataframe of student positions with name and group
    student_positions <- data.frame(x = numeric(0), y = numeric(0), name = character(0), group = character(0))
    
    ## Add names to dataframe
    for (r in 1:num_rows) {
      for (c in 1:num_cols) {
        if (!is.na(seating$chart[r, c]) && seating$chart[r, c] != "Empty") {
          ### Get the student name and group for coloring
          student_name <- seating$chart[r, c]
          student_group <- seating$data$group[match(student_name, seating$data$name)]
          if (student_group == "") {
            student_group <- "Ungrouped"
          }
          #### Store the position for later plotting
          student_positions <- rbind(student_positions, data.frame(x = c, y = num_rows - r + 1, name = student_name, group = student_group))
        }
      }
    }
    # Initialize plot
    p <- ggplot(data=student_positions) + 
      geom_point(data=student_positions,
        aes(x = x,
            y = y,
            color = group
            ),
        shape = 0,
        size = 15
        ) + # Add points (squares so they look like desks)
      geom_text(data=student_positions,
         label = student_positions$name,
         aes(x = x,
             y = y
             ),
         color = "black"
         ) + # Add the text label
      xlim(min(student_positions$x - .5), max(student_positions$x + .5))+
      ylim(min(student_positions$y - .5), max(student_positions$y + .5))+
      xlab("")+
      ylab("")+
      theme_bw()
    # plotly it
    p <- ggplotly(p)
  return(p)
  })
}

# Run the app
shinyApp(ui = ui, server = server)