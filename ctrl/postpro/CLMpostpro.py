import numpy as np
import netCDF4 as nc
import glob
import argparse
import os
import sys
import ParFlow_IO as pio

""" Converting given ParFlow output to netCDF

This function needs a 'empty' template netCDF file which can be created with
the help of './netCDF_select.py'
"""

parser = argparse.ArgumentParser(description='Tell me what this script can do!.')
parser.add_argument('--variables', '-v', nargs='+', type=str, required=True,
                    help='variable to process (have to fit model convention')
parser.add_argument('--indir', '-i', type=str, required=True,
                    help='absolut path to directory holding Model output')
parser.add_argument('--outdir', '-o', type=str, required=True,
                    help='absolut path to directory output should be placed')
parser.add_argument('--templateFile', '-t', type=str, required=True,
                    help='absolut path to a template file holding the correct (COSMO) grid')
parser.add_argument('--NBOUNDCUT', '-nc', type=int, default=6,
                    help='number of pixels to cut of at each side to fit other grids (related to COSMO)')
args = parser.parse_args()

VARs          = args.variables
inDir         = args.indir
outDir        = args.outdir
templateFile  = args.templateFile
NBOUNDCUT     = args.NBOUNDCUT 

# notic that 'cell_methods' is correct (accoring to NCO) but CLM stores 
# the attribute 'cell_method' which is renamed here (to fit NCO)
tmp_vars = {VAR:{'data':None, 'att':''} for VAR in VARs}
inFiles = sorted(glob.glob(f'{inDir}/*.h0.*.nc'))
for inFile in inFiles:
    with nc.Dataset(inFile, 'r') as nc_file:
        for name, variable in nc_file.variables.items():
            if name in VARs:
                #print(f'name: {name}')
                #print(f'nc_file[name][...]: {nc_file[name][...]}')
                #print(f'nc_file[name].__dict__: {nc_file[name].__dict__}')
                if not tmp_vars[name]['data'] is None:
                    tmp_vars[name]['data'] = np.append(tmp_vars[name]['data'], nc_file[name][...], axis=0)
                    tmp_vars[name]['att'] = nc_file[name].__dict__
                else:
                    tmp_vars[name]['data'] = nc_file[name][...]
                    tmp_vars[name]['att'] = nc_file[name].__dict__

for name in VARs:
    if name in ['time', 'time_bounds']:
        continue

    # manipulating variable attributes
    # keeping below in would lead to:
    # RuntimeError: NetCDF: Can't open HDF5 attribute
    # seems that '_FillValues' is related to old netcdflib
    del(tmp_vars[name]["att"]['_FillValue'])
    # add projection information
    tmp_vars[name]["att"]['grid_mapping'] = 'rotated_pole'
    tmp_vars[name]["att"]['coordinates'] = 'lon lat'
    # 'correct' cell_methods which is named cell_method in CLM output
    tmp_vars[name]["att"]['cell_methods'] = tmp_vars[name]["att"]['cell_method']
    del(tmp_vars[name]["att"]['cell_method'])


    # outFile is created out of a template file
    outFile = f'{outDir}/{name}.nc'
    os.system(f'cp {templateFile} {outFile}')
    with nc.Dataset(outFile, 'r+') as dst:
        a = dst.createVariable('time','f8',('time'))
        tmp_time = np.nanmean(tmp_vars['time_bounds']['data'][...], axis=1)
        dst['time'][...] = tmp_time[...]
        dst['time'].setncatts(tmp_vars['time']['att'])
        
        #x = dst.createVariable('time_orig','f8',('time'))
        #dst['time_orig'][...] = tmp_vars['time']['data'][...]
        #dst['time_orig'].setncatts(tmp_vars['time']['att'])

        y = dst.createVariable('time_bounds','f8',('time', 'bnds'))
        dst['time_bounds'][...] = tmp_vars['time_bounds']['data'][...]
        dst['time_bounds'].setncatts(tmp_vars['time_bounds']['att'])

        z = dst.createVariable(name,'f4',('time','rlat','rlon'), zlib=True)
        dst[name][...] = tmp_vars[name]['data'][...]
        dst[name].setncatts(tmp_vars[name]['att'])

