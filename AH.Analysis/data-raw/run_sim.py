import os
import shutil
import sys
import pandas as pd
import glob
from threading import Thread
from time import sleep

from joblib import Parallel, delayed

ProductsDir = '/Applications/EnergyPlus-22-1-0'
RepoRoot = '/Applications/EnergyPlus-22-1-0'

sys.path.insert(0, str(ProductsDir))
from pyenergyplus.api import EnergyPlusAPI

# working_dir = os.path.join(os.getcwd(), "scenario_simulation/{}".format(year))

def run_one(idfs, idf_folder, output_folder, test_epw, api):
    for idf in idfs:
        idf_name = idf.replace(".idf", "")
        idf_name = idf_name.replace(idf_folder + "/", "")
        idf_kw = idf_name.replace(".", "_")
        print(idf_kw)
        output_dir = os.path.join(os.getcwd(), "{}/{}".format(output_folder, idf_kw))
        if (not os.path.isdir(output_dir)):
            os.mkdir(output_dir)
            state = api.state_manager.new_state()
            return_value = api.runtime.run_energyplus(
                state, [
                    '-d',
                    output_dir,
                    '-w',
                    test_epw,
                    '-r',
                    idf
                ]
            )
            api.state_manager.delete_state(state)

def run_one_no_arg(idfs):
    api = EnergyPlusAPI()
    run_one(idfs, "scenario_simulation/idf_version_update",
            "scenario_simulation/testrun",
            os.path.join(os.getcwd(), "scenario_simulation/test_epw/USA_CA_Los.Angeles.Intl.AP.722950_TMY3.epw"), api)

def test_run_all_model(epw_path, idf_folder, output_folder, n_thread=1, filter_substring=""):
    idfs = glob.glob("{}/*.idf".format(idf_folder))
    idfs = [f for f in idfs if filter_substring in f]
    test_epw = os.path.join(os.getcwd(), epw_path)
    if (n_thread == 1):
        for idf in idfs:
            run_one(idf, idf_folder, output_folder, test_epw, api)
    else:
        print("no")
        k = len(idfs) // n_thread
        dfs = [idfs[k*i:k*(i+1)] for i in range(n_thread - 1)]
        dfs.append(idfs[k*(n_thread - 1):max(k*n_thread, len(idfs))])
        Parallel(n_jobs=n_thread)(delayed(run_one_no_arg)(dfs[i]) for i in range(n_thread))

test_run_all_model(epw_path="scenario_simulation/test_epw/USA_CA_Los.Angeles.Intl.AP.722950_TMY3.epw",
                   idf_folder="scenario_simulation/idf_version_update",
                   output_folder="scenario_simulation/testrun", n_thread=4)
