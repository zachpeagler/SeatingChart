# Seating Chart

# dependencies
library("shiny")
library("tidyverse")
library("bslib")
library("plotly")
library("proxy")

# font setup

f_open <- list(
  family = "Helvetica",
  face = "bold"
)
f_mont <- list(
  family = "Helvetica"
)

# UI
ui <- navbarPage("Seating Chart App",
                 theme = bs_theme(bootswatch = "sandstone"),
                 nav_panel("Seating Chart",
 layout_sidebar( sidebar = sidebar(
      fileInput("file1", "Upload CSV File", accept = c(".csv")),
      numericInput("nrows", "Number of Rows", min = 1, max = 20, value = 5),
      numericInput("ncols", "Number of Columns", min = 1, max = 20, value = 5),
      numericInput("g_dist", "Group Distance", min = 0, max = 10, value = 2),
      checkboxInput("s_legend", "Show Legend", value = FALSE),
      actionButton("assign_seats", "Assign Seats")
    ),
    card(layout_columns(
      card(height = 500,
        plotlyOutput("seating_chart")
      ),
      card(card_header("Roster"),
           verbatimTextOutput("roster"),  # Print leftover students
        card(card_header("Students Not Seated"),
        verbatimTextOutput("leftover")  # Print leftover students
            )
      ), col_widths = c(9, 3)
    ))
   )
  ),
 nav_panel("Info",
    tabsetPanel(
      tabPanel("Instructions",
        markdown("
                 ### 1. Upload csv <br>
                 For help creating the csv file, see the [Github repository.](https://github.com/zachpeagler/SeatingChart),
                 which has a template, examples, and more! <br>
                 ### 2. Select options <br>
                 Select how many rows and columns to have on the seating chart, 
                 as well as the distance between members of the same group. <br>
                 ### 3. Hit **Assign Seats** <br>
                 Hit the assign seats button, which will take your csv and 
                 selected options and return a seating chart. If any students were 
                 left out of the seating chart, their names will be displayed below 
                 the chart.
                 ")
      ), # end instruction panel
      tabPanel("Description",
      markdown("For full documentation, example data, and a data template, see the [Github repository.](https://github.com/zachpeagler/SeatingChart) <br>
        This app makes seating charts for teachers.
        Just upload a csv file and it returns a seating chart. <br>
        
        The csv file you provide must be in a specific format, with columns for **name**, **group**, and **frontRow**. A template and an example data file are provided below. <br>
        
        This app is designed to **separate** members of the same group. Though, conversely it can also be used to group them, if group distance is set to 0. <br>
        
        There are inputs for the number of rows, number of columns, and group distance.<br>
        1. **Number of rows:** controls the number of rows in the seating chart<br>
        2. **Number of columns:** controls the number of columns in the seating chart<br>
        3. **Group distance:** controls the number of desks between members of the same group<br>
        
        > If the group distance is set too high, especially on a small seating charts, students will fail to be seated according to the desired **group distance** and will be seated randomly instead.<br>
        
        Coming soon: custom colors, the option to show empty desks, and the option to save charts to pdf or png.
        
        ")
      ) # end description panel
    ) # end tabset panel
  ), # end info nav panel
 nav_spacer(),
 nav_item(tags$a("Github", href = "https://github.com/zachpeagler"))
 )

##### SERVER #####
server <- function(input, output, session) {
# create reactive values
  seating <- reactiveValues(data = NULL, chart = NULL, colors = NULL, nrow = NULL, ncol = NULL, leftover = NULL, showlegend = NULL)
# upload file observe event
  observeEvent(input$file1, {
    # Read the uploaded CSV file and create a seat column
    seating$data <- read.csv(input$file1$datapath) %>%
      mutate(seat = c(1:nrow(.)))  # Create a seat column
    
#    # Debugging: Check the data loaded from the CSV file
#    print("Data loaded from CSV:")
#    print(seating$data)

  })

# assign seat observe event
  observeEvent(input$assign_seats, {
    req(seating$data)  # Ensure data is available
    # Get student information
    students <- seating$data
    num_rows <- input$nrows
    num_cols <- input$ncols
    show_legend <- input$s_legend
    seating$nrow <- num_rows
    seating$ncol <- num_cols
    seating$showlegend <- show_legend
    g_dist <- input$g_dist
    grid <- matrix(NA, nrow = num_rows, ncol = num_cols)  # Initialize an empty grid
    colors <- rainbow(length(unique(students$group)))  # Generate colors for each group
    
    # create empty dataframe for seated students
    seated_students <- data.frame(x = numeric(0), y = numeric(0), name = character(0), group = character(0))
    
# --- Part 1: Assign Front Row Students ---
    front_row_students <- students %>% filter(frontRow == TRUE)
    front_row_students <- front_row_students[sample(1:nrow(front_row_students)),]
    # Assign front row seats (1st row and possibly 2nd row)
    for (i in seq_len(nrow(front_row_students))) {
      if (i <= num_cols) {
        grid[1, i] <- front_row_students$name[i]
        seated_students <- rbind(seated_students,
                                  data.frame(row=1, column=i,
                                  name=front_row_students$name[i],
                                  group = front_row_students$group[i]))
      } else {
        grid[2, i - num_cols] <- front_row_students$name[i - num_cols]
        seated_students <- rbind(seated_students,
                                 data.frame(row=2, column=i - num_cols,
                                 name=front_row_students$name[i - num_cols],
                                 group = front_row_students$group[i - num_cols]))
      }
    }

#    # Debugging: Check grid after assigning front-row students
#    print("Grid after assigning front-row students:")
#    print(grid)

        fr_grid <- grid

# --- Part 2: Assign Group Students ---
    # remove front row students (they're already seated)
    ## we could also do this by filtering out the students in the seated_students
    ## dataframe, but for this application its fine
    non_FR_students <- students %>% filter(frontRow == FALSE)
    grid_df <- data.frame(grid)
    student_groups <- unique(students$group)
    student_groups <- student_groups[nzchar(student_groups)]
    rstudent_groups <- sample(student_groups)
    # student group loop
    for (g in rstudent_groups) {
      # get students in the group
      g_students <- non_FR_students %>% filter(group == g)
      g_students <- g_students[sample(1:nrow(g_students)),]
      # student loop
      for (s in seq_len(nrow(g_students))) {
        # set attempt counter to 0
        attempts = 0
        # before seating each student, get the available seats
        ## get remaining seats
        remaining_seats <- which(is.na(grid), arr.ind = TRUE)
        ##sort remaining seats by row
        remaining_seats <- remaining_seats[order(remaining_seats[,1], decreasing = FALSE),]
        ## turn remaining seats into a data frame, while preserving the original
        remaining_seats_df <- as.data.frame(remaining_seats)
        # get student
        student <- g_students[s,]
        # get seated students with the same group
        seated_group_students <- seated_students %>% filter(group == g)
        # if there are no students already seated with the same group
        if (nrow(seated_group_students) == 0) {
          # place first student in group
          seat <- remaining_seats[s, ]
          grid[seat[1], seat[2]] <- student$name
          seated_students <- rbind(seated_students,
                                   data.frame(row=seat[1], column=seat[2],
                                              name=student$name,
                                              group = student$group))
        } else { # if there ARE students with the same group already seated
          # create new variable for number of attempts to seat a student
          # for each remaining empty seat
          for (rs in seq_len(nrow(remaining_seats_df))) {
            # compare it to the positions of the already seated students
            # create temp df to hold acceptance values
            df_ad <- data.frame(accept=character(0))
            tseat <- remaining_seats[ 1 + attempts,]
            # for each student in the g group already seated
            for (sgs in seq_len(nrow(seated_group_students))) {
              ## Debugging - print distance calculation outcomes
#              print(as.character((abs(tseat[1] - seated_group_students[sgs,1])+
#                                    abs(tseat[2] - seated_group_students[sgs,2]))))
              # check distance
              if ((abs(tseat[1] - seated_group_students[sgs,1])+
                  abs(tseat[2] - seated_group_students[sgs,2])) <= g_dist) {
                # if distance is less than g_dist
                ## add FALSE to result data frame
                df_ad <- rbind(df_ad, data.frame(accept="FALSE"))
              } else { 
                # if distance is greater than g_dist
                ## add TRUE to result data frame
                df_ad <- rbind(df_ad, data.frame(accept="TRUE"))
              }
            } # end seated group student loop
            ad_result <- grep("FALSE", df_ad$accept)
            # if all seated group students accept placement, confirm placement
            ## specifically looking if no df_ad returns false
            if (is_empty(ad_result)==FALSE) {
              ## tick the attempt counter
              brk <- FALSE
              attempts = attempts + 1
              if (rs == nrow(remaining_seats_df)) {
                print(paste("Warning", student$name, "failed to sit in their seat after", attempts, "attempts!"))
              }
              next
            } else {
              # add to grid
              grid[tseat[1], tseat[2]] <- student$name[1]
              # add to seated_students df
              seated_students <- rbind(seated_students,
                                       data.frame(row=tseat[1], column=tseat[2],
                                                  name=student$name,
                                                  group = student$group))
              # print number of attempts
              print(paste(student$name, "seated in", attempts, "attempts."))
              brk <- TRUE
            }
            # break rs loop
            if (brk == TRUE) {
              break
            }
          } # end remaining seat loop
        }
      } # end student loop
      
    } # end student group loop
    
#    # Debugging: Check grid after assigning grouped students
#   print("Grid after assigning grouped students:")
#    print(grid)

# --- Part 3: Assign Remaining Students ---
    # get students not in grid
    other_students <- subset(students, !(students$name %in% grid))
    # get remaining seats
    remaining_seats <- which(is.na(grid), arr.ind = TRUE)
    # order remaining seats by row
    remaining_seats <- remaining_seats[order(remaining_seats[,1], decreasing = FALSE),]
    # shuffle the order of non-front-row students
    shuffled_students <- sample(other_students$name)
    # ensure we do not exceed the available remaining seats
    num_students_to_seat <- min(length(shuffled_students), nrow(remaining_seats))
    # assign remaining students to the empty seats
    for (i in seq_len(num_students_to_seat)) {
      seat <- remaining_seats[i, ]
      grid[seat[1], seat[2]] <- shuffled_students[i]
    }
    # check to see if any students are not seated
    seating$leftover <- subset(students, !(students$name %in% grid))
    # Debugging: Check grid after assigning grouped students
    print("Grid after assigning remaining students:")
    print(grid)
    
# --- Part 4: Fill Empty Seats with "Empty" ---
    empty_seats <- which(is.na(grid), arr.ind = TRUE)  # Get remaining empty seats
    for (i in seq_len(nrow(empty_seats))) {
      seat <- empty_seats[i, ]
      grid[seat[1], seat[2]] <- "Empty"
    }
    
#    # Debugging: Check grid after assigning empty seats
#    print("Grid after assigning empty seats:")
#    print(grid)
    
    # Store the seating chart
    seating$chart <- grid  # Store grid to reactive values
    
    # Create a reactive color map for the students based on groups
    seating$colors <- setNames(colors, unique(students$group))
  })

### Outputs
  # Output showing roster
  output$roster <- renderPrint({
      seating$data[,-4]
  })
# Output showing leftover students
  output$leftover <- renderPrint({
    if (length(seating$leftover$name) < 1){
      "All students seated!"
    } else{
    seating$leftover$name
    }
  })

# Output for the seating chart
  output$seating_chart <- renderPlotly({
    req(seating$chart)  # Ensure the chart is ready
    
    # Define grid dimensions
    num_rows <- seating$nrow
    num_cols <- seating$ncol
    show_legend <- seating$showlegend
    
    temp_df <- data.frame(x = seq(from = 1, to = num_cols, length.out = 5),
                          y = seq(from= 1, to = num_rows, length.out = 5)
                          )
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
      theme_bw()+
      theme(
        plot.margin = margin(t=10)
      )
    # plotly it
    p <- ggplotly(p)
    # add more layout specifics
    p <- p %>% layout(
      font = f_mont,
      title = list(text = "FRONT", font = f_open)
    )
    # legend
    if (show_legend == FALSE) {
      p <- p %>% layout(showlegend = FALSE)
    }
  return(p)
  })
}

# Run the app
shinyApp(ui = ui, server = server)