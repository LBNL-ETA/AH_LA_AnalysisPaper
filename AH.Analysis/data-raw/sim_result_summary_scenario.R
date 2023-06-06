library("dplyr")

setwd("AH.Analysis/data-raw")

df = readr::read_csv("epw_idf_to_simulate_scenario_cz6.csv")

## heat pump has issue, skip for now
df <- df %>%
    dplyr::filter(scenario != "HeatPump") %>%
    {.}

## df %>%
##   distinct(idf.name) %>%
##   dplyr::arrange(idf.name) %>%
##   readr::write_csv("prototype_bldg_area.csv")

df.area.prototype = readr::read_csv("prototype_bldg_area.csv") %>%
  dplyr::mutate(idf.kw = gsub(".idf", "", idf.name, fixed=TRUE)) %>%
  dplyr::mutate(idf.kw = gsub(".", "_", idf.kw, fixed=TRUE)) %>%
  dplyr::select(-idf.name) %>%
  {.}

dirs <- df %>%
  dplyr::mutate(dirname = paste0(idf.name, "____", id)) %>%
  dplyr::mutate(dirname = gsub(".idf", "", dirname, fixed = TRUE)) %>%
  dplyr::mutate(dirname = gsub(".", "_", dirname, fixed = TRUE)) %>%
  .$dirname

dirs %>% head()

suf = "_ann"
pref = "annual"

result.dir = "scenario_simulation/scenario_sim_output_cz_6"
result.csv.dir = "scenario_simulation/scenario_sim_output_cz_6_csv"

length(dirs)

file.exists(sprintf("%s/%s/eplusout.csv", result.dir, dirs[[1]]))

for (dirname in dirs) {
  print(dirname)
  output.name = sprintf("%s/%s/eplusout.csv", result.dir, dirname)
  ## output.name = sprintf("result_ann/%s/eplusout.csv", dirname)
  if (file.exists(output.name)) {
    print(sprintf("copy to %s/%s.csv",  result.csv.dir, dirname))
    print(file.copy(output.name, sprintf("%s/%s.csv", result.csv.dir, dirname)))
  }
}

files = list.files(path=result.csv.dir, pattern = "*.csv")

files.kw = gsub(".csv", "", files)

files.kw %>% head()

setdiff(dirs, files.kw)
## all files are processed

check.missing.var = FALSE
## check.missing.var = TRUE
if (check.missing.var) {
  ## colname = "Environment:Site Total Zone Exhaust Air Heat Loss [J](Hourly)"
  colname = "Environment:Site Total Surface Heat Emission to Air [J](Hourly)"
  with.missing.var <- lapply(seq_along(files), function(i) {
      f = files[i]
      ## print(i)
      df = readr::read_csv(sprintf("%s/%s", result.csv.dir, f), col_types = readr::cols()) %>%
          {.}
      if (!(colname %in% names(df))) {
          return(f)
      }
  })
}

unlist(with.missing.var)

devtools::load_all("~/Dropbox/workLBNL/packages/AHhelper")

## read simulation results for annual
result.ann <- lapply(files, function(f) {
  tokens = unlist(stringr::str_split(f, pattern = "____"))
  idf.kw = tokens[[1]]
  epw.id = gsub(".csv", "", tokens[[2]])
  df = AHhelper::read.eplusout(result.csv.dir, f)
  if (nrow(df) != 8760) {
    print(sprintf("%s: %d", f, nrow(df)))
  }
  df %>%
      dplyr::mutate(idf.kw = idf.kw, epw.id = epw.id)
}) %>%
  dplyr::bind_rows()

result.ann %>%
    names()

## maybe make to separate data files?
dfs <- result.ann %>%
    dplyr::mutate(filename = gsub("Family-", "Family_", idf.kw)) %>%
    tidyr::separate(filename, c("scenario", "building.type", "vintage", "temp", "cz"), sep="_") %>%
    dplyr::select(-temp, -cz, -building.type, -vintage) %>%
    dplyr::group_by(scenario) %>%
    dplyr::group_split()

for (df in dfs) {
    scenario.i = df$scenario[[1]]
    df %>%
        dplyr::mutate(idf.kw = gsub(paste0(scenario.i, "_"), "", idf.kw)) %>%
        dplyr::mutate(idf.kw = gsub("_cz_6", "", idf.kw)) %>%
        readr::write_csv(sprintf("%s_sim_result_by_idf_epw_%s.csv", pref, scenario.i))
}

## compile baseline residential no retrofit
## read simulation results for annual
result.csv.dir = "EP_output_csv/sim_result_ann_WRF_2018_csv"

files = list.files(path=result.csv.dir, pattern = "*.csv")
files = files[which(stringr::str_detect(files, "Family"))]

result.ann <- lapply(files, function(f) {
    tokens = unlist(stringr::str_split(f, pattern = "____"))
    idf.kw = tokens[[1]]
    epw.id = gsub(".csv", "", tokens[[2]])
    df = AHhelper::read.eplusout(result.csv.dir, f)
    if (nrow(df) != 8760) {
        print(sprintf("%s: %d", f, nrow(df)))
    }
    df %>%
        dplyr::mutate(idf.kw = idf.kw, epw.id = epw.id)
}) %>%
    dplyr::bind_rows()

result.ann

result.ann %>%
    dplyr::mutate(scenario = "baseline") %>%
    readr::write_csv(sprintf("%s_sim_result_by_idf_epw_baseline.csv", pref))
