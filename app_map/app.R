library(shiny)
library(plotly)

ui <- fluidPage(
    titlePanel("Retrofit scenario analysis of residential buildings"),
    sidebarLayout(
        sidebarPanel(
            sliderInput(inputId = "topKpercent",
                        label = "Top k percent:",
                        min = 1,
                        max = 100,
                        value = 100),
            radioButtons(
                inputId = "aggregation",
                label = "aggregation",
                choices = c("annual", "monthly", "diurnal"),
                selected = "annual"
            ),
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
                choices = c("baseline", "envelope", "Lighting70",
                            "infiltration", "CoolingCoilCOP"),
                selected = "envelope"
            ),
            radioButtons(
                inputId = "diffMethod",
                label = "method",
                choices = c("diff", "percent diff", "original value"),
                selected = "original value"
            ),
            width=2

        ),
        ## mainPanel(
        mainPanel(
            fluidRow(plotOutput(outputId = "mapPlot", height = "600px")),
            fluidRow(plotOutput(outputId = "densityPlot", height = "300px"))
        )
    )
)

server <- function(input, output) {

    library("dplyr")
    devtools::load_all("~/Dropbox/workLBNL/packages/AHhelper")
    ## read map
    tract.geo <- sf::st_read("../AH.Analysis/data-raw/geo_data/tract.geojson") %>%
        dplyr::rename(geoid = id.tract) %>%
        {.}
    load("../AH.Analysis/data/res.scenario.tract.ann.rda")
    load("../AH.Analysis/data/res.scenario.diff.tract.ann.rda")
    load("../AH.Analysis/data/res.scenario.percent.diff.tract.ann.rda")
    load("../AH.Analysis/data/la.boundary.valid.rda")
    output$mapPlot <- renderPlot({
        if (input$diffMethod == "diff") {
            to.plot <- res.scenario.diff.tract.ann
        } else if (input$diffMethod == "percent diff") {
            to.plot <- res.scenario.percent.diff.tract.ann
        } else if (input$diffMethod == "original value") {
            to.plot <- res.scenario.tract.ann
        }
        all.scenario <- to.plot %>%
            dplyr::inner_join(tract.geo, by = "geoid") %>%
            {.}
        data.to.view <- all.scenario %>%
            dplyr::filter(scenario == input$scenario) %>%
            dplyr::rename(GJ = input$variable) %>%
            {.}
        if (input$topKpercent < 100) {
            if (input$diffMethod == "original value") {
                data.to.view <- data.to.view %>%
                    dplyr::arrange(desc(GJ)) %>%
                    {.}
            } else {
                ## top means larger negatives, arrange from small (more negative) to large
                data.to.view <- data.to.view %>%
                    dplyr::arrange(GJ) %>%
                    {.}
            }
            data.to.view <- data.to.view %>%
                dplyr::slice(1:as.integer(round(nrow(.) * input$topKpercent / 100, 0)))
        }
        data.to.view <- data.to.view %>%
            sf::st_as_sf()
        data.to.view %>%
            ggplot2::ggplot() +
            ggplot2::geom_sf(ggplot2::aes(fill = GJ), lwd = 0) +
            ggplot2::scale_fill_viridis_c(option = "plasma") +
            ggplot2::coord_sf(ylim = c(33.6, 34.9))
    })
    output$densityPlot <- renderPlot({
        if (input$diffMethod == "diff") {
            to.plot <- res.scenario.diff.tract.ann
        } else if (input$diffMethod == "percent diff") {
            to.plot <- res.scenario.percent.diff.tract.ann
        } else if (input$diffMethod == "original value") {
            to.plot <- res.scenario.tract.ann
        }
        to.plot <- to.plot %>%
            dplyr::filter(scenario == input$scenario) %>%
            dplyr::rename(GJ = input$variable) %>%
            {.}
        if (input$topKpercent < 100) {
            if (input$diffMethod == "original value") {
                to.plot <- to.plot %>%
                    dplyr::arrange(desc(GJ)) %>%
                    {.}
            } else {
                to.plot <- to.plot %>%
                    dplyr::arrange(GJ) %>%
                    {.}
            }
            to.plot <- to.plot %>%
                dplyr::slice(1:as.integer(round(nrow(.) * input$topKpercent / 100, 0)))
        }
        to.plot %>%
            ggplot2::ggplot() +
            ggplot2::geom_histogram(ggplot2::aes(x = GJ)) +
            ggplot2::geom_vline(xintercept = mean(to.plot$GJ)) +
            ggplot2::geom_text(ggplot2::aes(x = mean(to.plot$GJ), y = 50, label = round(mean(to.plot$GJ), 2)))
    })

}

shinyApp(ui = ui, server = server)
