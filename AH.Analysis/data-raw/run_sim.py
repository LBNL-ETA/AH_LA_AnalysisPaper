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
    run_one(idfs, "scenario_simulation/to_simulate_cz_6",
            "scenario_simulation/testrun_cz_6",
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
                   idf_folder="scenario_simulation/to_simulate_cz_6",
                   output_folder="scenario_simulation/testrun", n_thread=4)

# simulate retrofit scenario start
# df = pd.read_csv("epw_idf_to_simulate_scenario_cz6.csv")
df = pd.read_csv("epw_idf_to_simulate_scenario_cz6_no_HP_multi.csv")

idfs = df['idf.name'].unique()

def run_sim_with_idf_epw_df(df_idf_epw, dirname, idf_path, epw_path):
    api = EnergyPlusAPI()
    df_idf_epw = df_idf_epw.reset_index()
    for index,row in df_idf_epw.iterrows():
        epw_id = row['id']
        idf_name = row['idf.name'].replace(".idf", "")
        print("{} epw: {}, idf: {}".format(index, epw_id, idf_name))
        idf_kw = idf_name.replace(".", "_")
        # output dir for annual simulation
        output_dir = os.path.join(os.getcwd(), "{}/{}____{:d}".format(dirname, idf_kw, epw_id))
        # output_dir = os.path.join(os.getcwd(), working_dir, "{}____{:d}".format(idf_kw, epw_id))
        # annual simulation for 2018
        if (os.path.isfile(os.path.join(output_dir, "eplusout.csv"))):
            continue
        if (not os.path.isdir(output_dir)):
            os.mkdir(output_dir)
            # indent to not run when folder exists
        state = api.state_manager.new_state()
        return_value = api.runtime.run_energyplus(
            state, [
                '-d',
                output_dir,
                # annual simulation comparing with EnergyAtlas
                '-a',
                '-w',
                os.path.join(os.getcwd(), epw_path, '{:d}.epw'.format(epw_id)),
                '-r',
                os.path.join(os.getcwd(), idf_path, "{}.idf".format(idf_name))
            ]
        )
        api.state_manager.delete_state(state)

def run_sim_wrapper(df_idf_epw):
    run_sim_with_idf_epw_df(df_idf_epw, "scenario_simulation/scenario_sim_output_cz_6", "scenario_simulation/to_simulate_cz_6", "wrf_epw_2018")

def run_multi_thread(n_thread):
    sim_to_run = df[df['idf.name'].isin(idfs)]
    k = len(sim_to_run) // n_thread
    dfs = [sim_to_run.iloc[k*i:k*(i+1), :] for i in range(n_thread - 1)]
    dfs.append(sim_to_run.iloc[k*(n_thread - 1):max(k*n_thread, len(sim_to_run)), :])

    Parallel(n_jobs=n_thread)(delayed(run_sim_wrapper)(dfs[i]) for i in range(n_thread))

run_multi_thread(5)

# simulate retrofit scenario end
