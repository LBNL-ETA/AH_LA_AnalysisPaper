setwd("AH.Analysis/data-raw")

files = list.files("scenario_simulation/idf_add_sim_period_output", "*.idf")

head(files)

files = files[which(stringr::str_detect(files, "Family"))]

for (f in files) {
  print(f)
  lines = readLines(sprintf("scenario_simulation/idf_add_sim_period_output/%s", f))
  newlines = sapply(lines, function(line) {
      if (stringr::str_detect(line, "/Users/sky/Sites/CBES/cbes_api/test/files/")) {
          newline = gsub("/Users/sky/Sites/CBES/cbes_api/test/files/",
                         "/Users/yujiex/Dropbox/workLBNL/EESA/AH_LA_AnalysisPaper/AH.Analysis/data-raw/scenario_simulation/res_schedule/", line, fixed = TRUE)
      } else {
          newline = line
      }
      newline
  })
  writeLines(newlines, sprintf("scenario_simulation/idf_change_csv_sche_path/%s", f))
}

## run version updates in idfVersionUpdater

## remove the temporary files
temp.files <- c(list.files("scenario_simulation/idf_version_update", pattern = "*_transition.audit"),
  list.files("scenario_simulation/idf_version_update", pattern = "*_V920.idf"))

for(f in temp.files) {
    file.remove(sprintf("scenario_simulation/idf_version_update/%s", f))
}
