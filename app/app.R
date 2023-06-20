library(shiny)
library(plotly)

ui <- fluidPage(
    titlePanel("Energy and heat emission simulation output"),
    sidebarLayout(
        sidebarPanel(
            radioButtons(inputId = "variable", label = "variable",
                         choices = c("Overall AH"="emission.overall", "Surface"="emission.surf", "HVAC rejection"="emission.rej",
                                     "Exhaust"="emission.exhaust", "Infiltration/Exfiltration"="emission.exfiltration",
                                     "Relief air"="emission.rel",
                                     "Electricit + Gas"="energy.overall",
                                     "Electricity"="energy.elec",
                                     "Gas"="energy.gas"),
                         selected = "emission.overall"),
            radioButtons(
                inputId = "scenario",
                label = "scenario",
                choices = c("envelope", "Lighting70",
                            "infiltration", "CoolingCoilCOP"),
                selected = "envelope"
            ),
            radioButtons(
                inputId = "idf",
                label = "idf",
                choices = c(
                    "SingleFamily-pre-1980",
                    "SingleFamily-2004_cz_6",
                    "SingleFamily-2013_cz_6",
                    "MultiFamily-pre-1980",
                    "MultiFamily-2004_cz_6",
                    "MultiFamily-2013_cz_6"),
                selected = "SingleFamily-pre-1980"
            ),
            selectInput(
                inputId = "epw",
                label = "epw",
                choices = as.character(c(9, 10, 11, 23, 24, 25, 27, 30, 34, 35,
                                         36, 37, 38, 39, 40, 41, 48, 49, 50 ,
                                         51, 52, 53, 54, 55, 62, 63, 64, 65, 66,
                                         67, 68, 69, 76, 77, 78, 79, 80, 82 ,
                                         83, 91, 92, 93, 96, 97, 105, 106, 107,
                                         109, 110, 111, 119, 120, 121, 123, 124,
                                         125, 135, 136, 138, 139)),
                selected = "65"
            )

        ),
        mainPanel(
            plotlyOutput(outputId = "dyPlot")

        )
    )
)

server <- function(input, output) {
    library("dplyr")
    devtools::load_all("~/Dropbox/workLBNL/packages/AHhelper")
    output$dyPlot <- renderPlot({

        output$dyPlot <- renderPlotly({
            ## read data files
            dirname = "../AH.Analysis/data-raw/scenario_simulation/scenario_sim_output_cz_6_csv"
            filename = sprintf("%s_%s_cz_6____%s.csv", input$scenario, input$idf, input$epw)
            filename = gsub("cz_6_cz_6", "cz_6", filename)
            print(dirname)
            print(filename)
            sim.result <- AHhelper::read.eplusout(dirname, filename) %>%
                AHhelper::convert.timestamp(year = 2018) %>%
                dplyr::rename(time = `Date/Time`,
                              J = input$variable)
            print(sim.result %>% head())
            plot_ly(sim.result, x = ~time, y = ~J) %>%
                add_lines()
        })

    })

}

shinyApp(ui = ui, server = server)
