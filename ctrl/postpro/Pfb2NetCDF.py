import numpy as np
import netCDF4 as nc
import glob
import argparse
import sys
import datetime as dt
import 	ParFlow_IO as pio

""" Converting given ParFlow output to netCDF

This function needs a 'empty' template netCDF file which can be created with
the help of './netCDF_select.py'
"""

parser = argparse.ArgumentParser(description='Tell me what this script can do!.')
parser.add_argument('--variable', '-v', type=str, required=True,
                    help='variable to process (have to fit ParFlow convention (like press, satu, etc)')
parser.add_argument('--indir', '-i', type=str, required=True,
                    help='absolut path to directory holding ParFLow output')
parser.add_argument('--outdir', '-o', type=str, required=True,
                    help='absolut path to directory output should be placed')
parser.add_argument('--model', '-m', type=str, required=True,
                    help='Model the output var is taken from (ParFlow or CLM). This is importent for the time-dimension. CLM starts at 1 and ParFlo at 0')
parser.add_argument('--YearMonth', type=str, required=True,
                    help='YYYY_MM of the model output')
parser.add_argument('--NBOUNDCUT', '-nc', type=int, default=6,
                    help='number of pixels to cut of at each side to fit other grids (related to COSMO)')
parser.add_argument('--dumpinterval', '-di', type=int, default=3,
                    help='The dump-intervall from ParFlow-Model in hours')
parser.add_argument('--standard_name', '-sn', type=str, default='',
                    help='standard_name to be passed to netCDF atribute')
parser.add_argument('--long_name', '-ln', type=str, default='',
                    help='long_name to be passed to netCDF atribute')
parser.add_argument('--units', '-u', type=str, default='',
                    help='units to be passed to netCDF atribute')
parser.add_argument('--level', '-l', type=int, default=None,
                    help='which level to store in netCDF default is None (all levels) surface is -1')
args = parser.parse_args()

VAR           = args.variable
inDir         = args.indir
outDir        = args.outdir
model         = args.model
YearMonth     = args.YearMonth
NBOUNDCUT     = args.NBOUNDCUT
dumpinterval  = args.dumpinterval
standard_name = args.standard_name
long_name     = args.long_name
units         = args.units
level         = args.level

year, month   = YearMonth.split('_')
year = int(year)
month = int(month)

# below file nee to be provided
outFile = f'{outDir}/{VAR}.nc'

pfbFiles = sorted(glob.glob(f'{inDir}/*.out.{VAR}*.pfb'))
testFile = pio.read_pfb(pfbFiles[0])
nz, ny ,nx = testFile.shape

nt = len(pfbFiles)
# CLM and ParFlow writes the first output differently
# ParFlow 00000 (init step)
# CLM     00001 (first time-step)
# therefore CLM output starts 1xdumpinterval later
offset_hour = 0
if model == 'CLM':
    offset_hour += dumpinterval
start_date = dt.datetime(year,month,1) 
time_array = np.array([start_date + dt.timedelta(hours=offset_hour) + ii*dt.timedelta(hours=dumpinterval) for ii in range(nt)])
seconds_since = np.array([abs(entry - start_date).total_seconds() for entry in time_array])

ncfile = nc.Dataset(outFile,'r+')
#time = ncfile.variables['time'][...]
#nt = time.shape[0]

tmp_out = []
for idx, pfbFile in enumerate(pfbFiles):
    data = pio.read_pfb(pfbFile)
    if NBOUNDCUT != 0:
        data = data[:,NBOUNDCUT:-NBOUNDCUT, NBOUNDCUT:-NBOUNDCUT]
    tmp_out.append(data)

out = np.asarray(tmp_out)
print(f'shape of collected ParFlow output: {out.shape}')
# mask values
# -3.40282346638529e+38 should be missing values in orig files...
out = np.ma.masked_less(out, -3.40282346638529e+30)

ncTime = ncfile.createVariable('time','i4',('time',))
ncTime.standard_name = 'time'
ncTime.long_name = 'time'
ncTime.units = f'seconds since {start_date.strftime("%Y-%m-%d %H:%M:%S")}'
ncTime.calendar = 'noleap'
ncTime[...] = seconds_since

# check if whole z-level to store or only singel level
# This (currently) does not support slicing, but level extraction only. 
if level is None:
    ncfile.createDimension('lev',nz)
    ncData = ncfile.createVariable(VAR,'f8',('time','lev','rlat','rlon'), 
            fill_value=-9999, zlib=True)
    ncData[...] = out
    #data[:] = np.transpose(var)
elif not level is None:
    ncData = ncfile.createVariable(VAR,'f8',('time','rlat','rlon'), 
            fill_value=-9999, zlib=True)
    ncData[...] = out[:,level,...]
    #data[:] = np.transpose(var)

ncData.standard_name = f'{standard_name}'
ncData.long_name = f'{long_name}'
ncData.units = f'{units}'
ncData.grid_mapping = f'rotated_pole'
ncData.coordinates = f'lon lat'
ncData.cell_methods = f'time: point'
#ncData.missing_value = -3.40282346638529e+38

ncfile.close()
