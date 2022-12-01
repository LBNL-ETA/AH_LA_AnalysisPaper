#' read a .epw file into a data frame
#'
#' @param filepath path to the epw file
#' @return A data frame
#' @export
#' @examples
#' read.epw()
read.epw <- function(filepath) {
  col.names = c("year","month","day","hour","minute",
                "Datasource","DryBulb.C","DewPoint.C",
                "RelHum.percent","AtmosPressure.Pa","ExtHorzRad.Wh/m2",
                "ExtDirRad.Wh/m2","HorzIRSky.Wh/m2","GloHorzRad.Wh/m2",
                "DirNormRad.Wh/m2","DifHorzRad.Wh/m2","GloHorzIllum.lux",
                "DirNormIllum.lux","DifHorzIllum.lux", "ZenLum.Cd/m2",
                "WindDir.deg","WindSpd.m/s","TotSkyCvr.0.1","OpaqSkyCvr.0.1",
                "Visibility.km","CeilingHgt.m","PresWeathObs","PresWeathCodes",
                "PrecipWtr.mm","AerosolOptDepth.0.001","SnowDepth.cm",
                "DaysLastSnow","Albedo.0.01","Rain.mm","RainQuantity.hr")

  df = readr::read_csv(filepath, skip=8,
                      col_names=col.names,
                      col_types=readr::cols(year=readr::col_integer(),
                                            month=readr::col_integer(),
                                            day=readr::col_integer(),
                                            hour=readr::col_integer(),
                                            minute=readr::col_integer())) %>%
      tibble::as_tibble() %>%
      {.}
  df
}

## get.spatial.path.suf <- function(spatial.level) {
##   if (spatial.level == "coarse") {
##     spatial.path = "M02_EnergyPlus_Forcing_Historical_LowRes/meta"
##     spatial.suf = ""
##     spatial.label = "Coarse Grids"
##   } else if (spatial.level == "finer") {
##     spatial.path = "high res grid for reporting"
##     spatial.suf = "_finer"
##     spatial.label = "Finer Grids"
##   } else if (spatial.level == "tract") {
##     spatial.path = "domain/tl_2018_06_tract"
##     ## spatial.path = "domain"
##     spatial.suf = "_tract"
##     spatial.label = "Census Tract"
##   }
##   list(spatial.path, spatial.suf, spatial.label)
## }

## get.annual.data <- function(time.pref, spatial.suf, df.area=NULL) {
##   heat.by.grid.monthly = readr::read_csv(sprintf("aggregated_heat/%s%s_monthly.csv", time.pref, spatial.suf))
##   heat.by.grid.annual.comp = heat.by.grid.monthly %>%
##     dplyr::group_by(id, variable) %>%
##     dplyr::summarise(value = sum(value)) %>%
##     dplyr::ungroup() %>%
##     dplyr::mutate(emission.GJ = value * 1e-9) %>%
##     dplyr::mutate(emission.mwh = emission.GJ * 0.277778) %>%
##     {.}
##   if (!is.null(df.area)) {
##     heat.by.grid.annual.comp <- heat.by.grid.annual.comp %>%
##       dplyr::left_join(df.area, by="id") %>%
##       dplyr::mutate(emission.wperm2 = value * 0.000277778 / 8760 / area.m2) %>%
##       {.}
##   }
##   heat.by.grid.annual.comp
## }

## get.monthly.data <- function(time.pref, spatial.suf, df.area=NULL) {
##   heat.by.grid.monthly = readr::read_csv(sprintf("aggregated_heat/%s%s_monthly.csv", time.pref, spatial.suf))
##   heat.by.grid.monthly.comp = heat.by.grid.monthly %>%
##     dplyr::mutate(emission.GJ = value * 1e-9) %>%
##     dplyr::mutate(emission.mwh = emission.GJ * 0.277778) %>%
##     {.}
##   if (!is.null(df.area)) {
##     hours.in.month = tibble::tibble(month=sprintf("%02d", 1:12), hours=c(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31) * 24)
##     heat.by.grid.monthly.comp <- heat.by.grid.monthly.comp %>%
##       dplyr::left_join(df.area, by="id") %>%
##       dplyr::left_join(hours.in.month, by="month") %>%
##       dplyr::mutate(emission.wperm2 = value * 0.000277778 / hours / area.m2) %>%
##       {.}
##   }
##   heat.by.grid.monthly.comp
## }

## get.df.to.plot <- function(heat.by.grid.annual.comp, grid.geo=NULL, res="annual") {
##   if (res == "annual") {
##     heat.by.grid.annual = heat.by.grid.annual.comp %>%
##       dplyr::group_by(id) %>%
##       dplyr::summarise_if(is.numeric, sum) %>%
##       dplyr::ungroup()
##   } else if (res == "monthly") {
##     heat.by.grid.annual = heat.by.grid.annual.comp %>%
##       dplyr::group_by(id, month) %>%
##       dplyr::summarise_if(is.numeric, sum) %>%
##       dplyr::ungroup()
##   }
##   if (is.null(grid.geo)) {
##     to.plot.ann.total <- heat.by.grid.annual
##     to.plot.ann.component <- heat.by.grid.annual.comp
##   } else {
##     to.plot.ann.total <- heat.by.grid.annual %>%
##       dplyr::left_join(grid.geo, by="id") %>%
##       sf::st_as_sf() %>%
##       {.}
##     to.plot.ann.component <- heat.by.grid.annual.comp %>%
##       dplyr::left_join(grid.geo, by="id") %>%
##       sf::st_as_sf() %>%
##       {.}
##   }
##   list(to.plot.ann.total, to.plot.ann.component)
## }

## get.grid.size.m2 <- function(spatial.level) {
##   if (spatial.level == "finer") {
##     return(500^2)
##   } else {
##     return(12000^2)
##   }
## }

## get.grid.size.from.geometry <- function(grid.geo) {
##   grid.geo$area.m2 <- sf::st_area(grid.geo)
##   grid.no.geo <- grid.geo
##   sf::st_geometry(grid.no.geo) <- NULL
##   grid.no.geo <- grid.no.geo %>%
##     tibble::as_tibble() %>%
##     dplyr::mutate(area.m2 = as.numeric(area.m2)) %>%
##     dplyr::select(id, area.m2)
##   grid.no.geo
## }

## get.top.k.percent.emission <- function(df, k) {
##   df.high.emit <- df %>%
##     dplyr::filter(emission.wperm2 > quantile(df$emission.wperm2, probs = 1 - k / 100.0)) %>%
##     {.}
##   id.high.emit <- df.high.emit %>%
##     tibble::as_tibble() %>%
##     dplyr::distinct(id) %>%
##     {.}
##   list(df.high.emit, id.high.emit)
## }
