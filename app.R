# NHANES HbA1c Explorer
#
# Aplicacion interactiva en R Shiny para explorar la relacion entre la
# hemoglobina glicosilada (HbA1c) y variables antropometricas y
# sociodemograficas en datos de la encuesta NHANES.
#
# Companero interactivo del analisis estatico en:
# https://github.com/camireeb/hba1c-diabetes-analysis
#
# Formato de entrada esperado (columnas requeridas):
#   age, sex, re (raza/etnia), income, dx (0/1 diagnostico), gh (HbA1c),
#   bmi, waist
#
# Prueba la app con el archivo incluido: example_data/example_nhanes.tsv

# Cargamos los paquetes necesarios para la aplicación
library(shiny)
library(ggplot2)
library(dplyr)

options(shiny.maxRequestSize = 50 * 1024^2)

# Definimos la interfaz del usuario
ui <- fluidPage(
  #Título de la app
  titlePanel("Aplicación de visualización de datos para NHANES"),

# Panel izquierdo
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Cargar archivo",#Archivo
                accept = c(".tsv",".csv")),
      checkboxInput("header", "Archivo con cabecera", TRUE), # Indica si el archivo tiene cabecera con nombres de columnas
      selectInput("sep", "Separador",
                  choices = c("Coma" = ",",
                              "Punto y coma" = ";",
                              "Tabulador" = "\t")), # Separadores
      hr(), # Línea horizontal para separar secciones

      uiOutput("filters"), # Filtros

      hr(),
      
      # Opción para seleccionar variable antropométrica que será analizada junto a la HbA1c en el gráfico de dispersión de la cuarta pestaña
      selectInput("x_var", "Variable antropométrica (en eje x)",
                  choices = c("IMC"="bmi", "Circunferencia de cintura"="waist"),
                  selected = "waist"),
      # Opción para seleccionar el factor de agrupación para comparar los valores de HbA1c en la tercera pestaña
      selectInput("group_var", "Agrupar HbA1c por",
                  choices = c("Diagnóstico de diabetes o prediabetes"="dx", "Sexo"="sex", "Raza/Etnia"="re", "Ingresos familiares"="income"),
                  selected = "dx"),
      # Opción para remover valores NA en los gráficos
      checkboxInput("remove_na", "Eliminar NA en gráficos", TRUE)
    ),

    # Panel principal
    mainPanel(
      # Cinco pestañas principales de visualización de resultados
      tabsetPanel(
        tabPanel("Vista previa",
                 tableOutput("preview")),
        tabPanel("HbA1c por edad",
                 plotOutput("hba1c_age", height = 350)),
        tabPanel("HbA1c por grupos",
                 plotOutput("box_hba1c", height = 350)),
        tabPanel("Relación HbA1c vs antropometría",
                 plotOutput("scatter_plot", height = 350)),
        tabPanel("Resumen",
                 tableOutput("summary_tbl"))
      )
    )
  )
)

# Definimos la lógica

server <- function(input, output, session) {

# Leemos el archivo y creamos un dataframe
  data_raw <- reactive({
   req(input$file)
   df <- read.csv(input$file$datapath,
                  header = input$header,
                  sep = input$sep,
                  stringsAsFactors = FALSE)

   # Convertimos NA de income a categoría explícita, porque sino quedaban excluidos del N total en el resumen
   if ("income" %in% names(df)) {
     df$income <- ifelse(is.na(df$income), "Missing", as.character(df$income))
   }

   df
   })


# Damos una vista previa para verificar que el archivo se leyó bien
  output$preview <- renderTable({
    head(data_raw(), 10)
  })

  # Filtros dinámicos a partir de los checkboxes del panel lateral
  output$filters <- renderUI({
    df <- data_raw()

    tagList(
      sliderInput("age_rng", "Rango de edad",
                  min = min(df$age, na.rm = TRUE),
                  max = max(df$age, na.rm = TRUE),
                  value = c(12, 80)),

      checkboxGroupInput("sex_sel", "Sexo",
                         choices = unique(df$sex),
                         selected = unique(df$sex)),

      checkboxGroupInput("re_sel", "Raza / Etnia",
                         choices = unique(df$re),
                         selected = unique(df$re)),

      checkboxGroupInput("income_sel", "Nivel de ingresos",
                         choices = sort(unique(df$income)),
                         selected = sort(unique(df$income))),

      checkboxGroupInput("dx_sel", "Diagnóstico (dx)",
                         choices = unique(df$dx),
                         selected = unique(df$dx))
    )
  })

  # Dataset filtrado (según los criterios elegidos por el usuario)
  data_filt <- reactive({
    df <- data_raw()

    df %>%
      filter(age >= input$age_rng[1],
             age <= input$age_rng[2],
             sex %in% input$sex_sel,
             re %in% input$re_sel,
             income %in% input$income_sel,
             dx %in% input$dx_sel) %>%
    mutate(dx_label = factor(dx, levels = c(0, 1), labels = c("Sin dx", "Con dx")))
  })

  # Outputs: gráficos y estadísticas
  
  # Scatterplot de HbA1c en función de la edad (a partir del dataframe con datos filtrados)
  output$hba1c_age <- renderPlot({
   df <- data_filt()
# En función de la selección de remover NA o no, quitamos o no los valores NA del gráfico:
   if (input$remove_na)
     df <- df[!is.na(df$gh) & !is.na(df$age) & !is.na(df$dx_label), ]
   
# Gráfico
  ggplot(df, aes(x = age, y = gh, color = dx_label)) +
     geom_point(alpha = 0.35) +
     geom_smooth(method = "lm", se = TRUE) +
     labs(
       title = "HbA1c por edad (según diagnóstico o no de diabetes)",
       x = "Edad (años)",
       y = "HbA1c (%)",
       color = "Dx"
     )
  })


  # Boxplots en función del criterio seleccionado para agrupación:
  output$box_hba1c <- renderPlot({
    df <- data_filt()
    g <- input$group_var

    if (input$remove_na)
      df <- df[!is.na(df$gh) & !is.na(df[[g]]), ]

    ggplot(df, aes(x = as.factor(df[[g]]), y = gh)) +
      geom_boxplot(fill = "lightblue") +
      labs(title = paste("HbA1c por", g),
           x = g,
           y = "HbA1c (%)") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  })

  # Scatterplot HbA1c en función de valores antropométricos
  output$scatter_plot <- renderPlot({
    df <- data_filt()
    x <- input$x_var

    if (input$remove_na)
      df <- df[!is.na(df$gh) & !is.na(df[[x]]), ]

    ggplot(df, aes(x = df[[x]], y = gh)) +
      geom_point(alpha = 0.6) +
      geom_smooth(method = "lm", se = TRUE, color = "red") +
      labs(title = paste("HbA1c vs", x),
           x = x,
           y = "HbA1c (%)")
  })

  # Resumen estadístico
  output$summary_tbl <- renderTable({
    df <- data_filt()

    data.frame(
      Métrica = c("N total",
                  "Media HbA1c",
                  "Mediana HbA1c",
                  "Media IMC",
                  "Media cintura"),
      Valor = c(
        nrow(df),
        round(mean(df$gh, na.rm = TRUE), 3),
        round(median(df$gh, na.rm = TRUE), 3),
        round(mean(df$bmi, na.rm = TRUE), 2),
        round(mean(df$waist, na.rm = TRUE), 2)
      )
    )
  }, bordered = TRUE)
}

# Ejecutamos la aplicación

shinyApp(ui, server)

