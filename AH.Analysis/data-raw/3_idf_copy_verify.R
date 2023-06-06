library("dplyr")

input.path = "scenario_simulation/idf_version_update"
output.path = "scenario_simulation/to_simulate_cz_6"

files = list.files(input.path, pattern = "*_cz_6.idf")


with.scenario = files[which(!(stringr::str_detect(files, "^Single") | stringr::str_detect(files, "^Multi")))]

with.scenario

for (f in with.scenario) {
    file.copy(sprintf("%s/%s", input.path, f),
              sprintf("%s/%s", output.path, f))
}

