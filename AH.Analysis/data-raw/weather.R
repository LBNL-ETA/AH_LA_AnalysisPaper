## code to export weather data for the 62 12x12km grid cells

library("dplyr")

files = list.files("wrf_epw_2018", pattern = "*.epw")

head(files)

source("read_epw.R")

result <- lapply(files, function(f) {
  print(f)
  ## skip 8 non-data rows
  df = read.epw(sprintf("wrf_epw_2018/%s", f)) %>%
    dplyr::mutate(filename = f) %>%
    {.}
})

df.all.weather <- result %>%
  dplyr::bind_rows() %>%
  dplyr::mutate(cell.id = as.numeric(gsub(".epw", "", filename))) %>%
  {.}

df.weather.2018 <- df.all.weather %>%
    dplyr::select(cell.id, everything())

usethis::use_data(df.weather.2018)
