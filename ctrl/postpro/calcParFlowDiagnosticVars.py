import heat as ht
import numpy as np
import sys
import os
import glob
import argparse
import netCDF4 as nc
import datetime

import sloth.diagnostics
import sloth.IO
import sloth.analysis
import postproLib as post

################################################################################
# Handel commandline arguments
################################################################################
parser = argparse.ArgumentParser(description='Tell me what this script can do!.')
parser.add_argument('--pressure', type=str, required=True,
                    help='Full path to ParFlow pressure files (pass pattern)')
parser.add_argument('--pressureVarName', type=str, required=True,
                    help='Name of pressure variable in pressure files')
parser.add_argument('--nFile', type=str, required=True,
                    help='Full path to file holding vanGenuchten n values')
parser.add_argument('--alphaFile', type=str, required=True,
                    help='Full path to file holding vanGenuchten apha values')
parser.add_argument('--sresFile', type=str, required=True,
                    help='Full path to file holding ParFlow sres values')
parser.add_argument('--ssatFile', type=str, required=True,
                    help='Full path to file holding ParFlow ssat values')
parser.add_argument('--maskFile', type=str, required=True,
                    help='Full path to file holding ParFlow mask')
parser.add_argument('--permXFile', type=str, required=True,
                    help='Full path to file holding ParFlow perm_x values')
parser.add_argument('--permYFile', type=str, required=True,
                    help='Full path to file holding ParFlow perm_y values')
parser.add_argument('--permZFile', type=str, required=True,
                    help='Full path to file holding ParFlow perm_z values')
parser.add_argument('--porosityFile', type=str, required=True,
                    help='Full path to file holding ParFlow porosity values')
parser.add_argument('--specificStorageFile', type=str, required=True,
                    help='Full path to file holding ParFlow specific_storage values')
parser.add_argument('--slopexFile', type=str, required=True,
                    help='Full path to file holding ParFlow slopex values')
parser.add_argument('--slopeyFile', type=str, required=True,
                    help='Full path to file holding ParFlow slopy values')
parser.add_argument('--manningsFile', type=str, required=True,
                    help='Full path to file holding ParFlow mannings values')
parser.add_argument('--dzMultFile', type=str, required=True,
                    help='Full path to file holding ParFlow dz_mult values')
parser.add_argument('--dz', type=float, required=True,
                    help='ParFlow dz value in [m] (before applying variable dz)')
parser.add_argument('--dy', type=float, required=True,
                    help='ParFlow dy value [m]')
parser.add_argument('--dx', type=float, required=True,
                    help='ParFlow dx value [m]')
parser.add_argument('--dt', type=float, required=True,
                    help='ParFlow dt value [h]')
parser.add_argument('--outDir', type=str, required=True,
                    help='Full path to dir where to store data')
parser.add_argument('--griddesFile', type=str, required=True,
                    help='Full path to file holding griddefinition for used grid')
parser.add_argument('--LLSMFile', type=str, required=True,
                    help='Full path to file holding domain LLSM')
parser.add_argument('--outPrepandName', type=str, required=True,
                    help='String to prepand to output file names.')


print(f'DEBUG: start defining some paths, names, etc.')
args = parser.parse_args()
pressureFilesPattern = args.pressure
pressureVarName      = args.pressureVarName
nFile                = args.nFile
alphaFile            = args.alphaFile
sresFile             = args.sresFile
ssatFile             = args.ssatFile
maskFile             = args.maskFile
permXFile            = args.permXFile
permYFile            = args.permYFile
permZFile            = args.permZFile
porosityFile         = args.porosityFile
specificStorageFile  = args.specificStorageFile
slopexFile           = args.slopexFile
slopeyFile           = args.slopeyFile
manningsFile         = args.manningsFile
dzMultFile           = args.dzMultFile
dz                   = args.dz
dy                   = args.dy
dx                   = args.dx
dt                   = args.dt
outDir               = args.outDir
griddesFile          = args.griddesFile
LLSMFile             = args.LLSMFile
outPrepandName       = args.outPrepandName

# Need for HeAT
split=None

################################################################################
# Read in data
################################################################################
pressureFiles   = sorted(glob.glob(pressureFilesPattern))
nt = len(pressureFiles)

with nc.Dataset(nFile, 'r') as nc_file:
    n = nc_file.variables['n'][0,...]
    print(f'n.shape: {n.shape}')
with nc.Dataset(alphaFile, 'r') as nc_file:
    alpha = nc_file.variables['alpha'][0,...]
    print(f'alpha.shape: {alpha.shape}')
with nc.Dataset(sresFile, 'r') as nc_file:
    sres = nc_file.variables['sres'][0,...]
    print(f'sres.shape: {sres.shape}')
with nc.Dataset(ssatFile, 'r') as nc_file:
    ssat = nc_file.variables['ssat'][0,...]
    print(f'ssat.shape: {ssat.shape}')
with nc.Dataset(maskFile, 'r') as nc_file:
    mask = nc_file.variables['mask'][0,...]
    print(f'mask.shape: {mask.shape}')
with nc.Dataset(permXFile, 'r') as nc_file:
    perm_x = nc_file.variables['perm_x'][0,...]
    print(f'perm_x.shape: {perm_x.shape}')
with nc.Dataset(permYFile, 'r') as nc_file:
    perm_y = nc_file.variables['perm_y'][0,...]
    print(f'perm_y.shape: {perm_y.shape}')
with nc.Dataset(permZFile, 'r') as nc_file:
    perm_z = nc_file.variables['perm_z'][0,...]
    print(f'perm_z.shape: {perm_z.shape}')
with nc.Dataset(porosityFile, 'r') as nc_file:
    porosity = nc_file.variables['porosity'][0,...]
    print(f'porosity.shape: {porosity.shape}')
with nc.Dataset(specificStorageFile, 'r') as nc_file:
    specific_storage = nc_file.variables['specific_storage'][0,...]
    print(f'specific_storage.shape: {specific_storage.shape}')
with nc.Dataset(slopexFile, 'r') as nc_file:
    slopex = nc_file.variables['slopex'][...]
    print(f'slopex.shape: {slopex.shape}')
with nc.Dataset(slopeyFile, 'r') as nc_file:
    slopey = nc_file.variables['slopey'][...]
    print(f'slopey.shape: {slopey.shape}')
with nc.Dataset(manningsFile, 'r') as nc_file:
    mannings = nc_file.variables['mannings'][...]
    print(f'mannings.shape: {mannings.shape}')
with nc.Dataset(dzMultFile, 'r') as nc_file:
    DZ_Multiplier = nc_file.variables['DZ_Multiplier'][0,...]
    print(f'DU_Multiplier.shape: {DZ_Multiplier.shape}')
with nc.Dataset(LLSMFile, 'r') as nc_file:
    LLSM = nc_file.variables['LLSM'][0,...]
    print(f'LLSM.shape: {LLSM.shape}')

# Use porosity to get nx, ny, nz. Could be any 3D field.
nz, ny, nx = porosity.shape
# Convert 3 individual perm fields to one field and convert to ht.array
perm     = ht.zeros((3,nz,ny,nx),split=split)
perm[0]  = perm_z
perm[1]  = perm_y
perm[2]  = perm_x
del perm_z, perm_y, perm_x
# Convert to ht-array 
mask             = ht.array(mask, split=split)
porosity         = ht.array(porosity, split=split)
specific_storage = ht.array(specific_storage, split=split)
ssat             = ht.array(ssat, split=split) 
sres             = ht.array(sres, split=split)
n                = ht.array(n, split=split)
alpha            = ht.array(alpha, split=split)
mannings         = ht.array(mannings, split=split)
slopex           = ht.array(slopex, split=split)
slopey           = ht.array(slopey, split=split)
# Diagnostic.py does expect Dzmult to be 1D, so cut out 1D column from 3D field.
Dzmult           = ht.array(DZ_Multiplier[:,0,0], split=split)

# add some global attributes to the created netCDF file
globAttrs = dict(author=os.getenv('AUTHOR_NAME', 'unset'),
             email=os.getenv('AUTHOR_MAIL', 'unset'),
             institute=os.getenv('AUTHOR_INSTITUTE', 'unset'),
             EXPID=os.getenv('EXPID', 'unset'),
             ENSMname=os.getenv('ENSMname', 'unset'))

print(f'DEBUG: init Diagnoctics class')
diag = sloth.diagnostics.Diagnostics.Diagnostics(Mask=mask, 
        Perm=perm, Poro=porosity, Sstorage=specific_storage,
        Ssat=ssat, Sres=sres, Nvg=n, Alpha=alpha,
        Mannings=mannings, Slopex=slopex, Slopey=slopey,
        Dx=dx, Dy=dy, Dz=dz, Dzmult=Dzmult, 
        Nx=nx, Ny=ny, Nz=nz,
        Terrainfollowing=True, Split=split)

print(f'DEBUG: start calculating lvl-1')
times            = []
wtd              = []
overlandFlow     = []
surfStor         = []
subSurfStor      = []
saturSubSurfStor = []
subSurfRunoff    = []
for count, pressureFile in enumerate(pressureFiles):
    with nc.Dataset(pressureFile, 'r') as nc_file:
        press        = nc_file.variables[pressureVarName][0,...]
        nc_time      = nc_file.variables['time']
        nc_times     = nc_time[...]
        times.append(nc_times)
        nc_calendar  = nc_time.calendar
        #dates        = nc.num2date(nc_time[:],units=nc_time.units,calendar=nc_time.calendar)
        nc_timeUnits = nc_time.units

        print(f'-- count: {count}; press.shape: {press.shape}')
    # convert press to ht-array as we deal with DIagnostcs.py
    press = ht.array(press)
    # Calculate relative saturation and relative hydraulic conductivity
    tmp_satur,krel = diag.VanGenuchten(press)
    # Calculate subsurface flow in all 6 directions for each grid cell (L^3/T)
    flowleft,flowright,flowfront,flowback,flowbottom,flowtop = diag.SubsurfaceFlow(press,krel)
    # Calculate a ground water body mask (gwb_mask)
    gwb_mask, wtd_z_index = sloth.analysis.get_3Dgroundwaterbody_mask(tmp_satur)
    # Get surface pressure
    surfPress = diag.TopLayerPressure(press)
    # Calculate overlandFlow in [L^2/T]
    tmp_qx, tmp_qy = diag.OverlandFlow(surfPress)
    # [L^2/T] --> [L^3/T]
    tmp_overlandFlow = ht.absolute(tmp_qx*dx) + ht.absolute(tmp_qy*dy)
    # Calculate subsurface storage and convert to units of [L] 
    tmp_subSurfStor = diag.SubsurfaceStorage(press, tmp_satur)
    tmp_subSurfStor = tmp_subSurfStor / (dx*dy)

    wtd.append(sloth.analysis.calc_wtd(press=press, cellDepths=dz*Dzmult))
    overlandFlow.append(tmp_overlandFlow)
    subSurfStor.append(tmp_subSurfStor)
    saturSubSurfStor.append(post.calc_ssss(sss=tmp_subSurfStor, 
        press_t=press, poro=porosity, gwb_mask=gwb_mask, 
        wtd_z_index=wtd_z_index))
    surfStor.append(post.calc_ss(surfPress))
    subSurfRunoff.append(post.calc_netLateralSubSurFlow(
        flowleft=flowleft, flowright=flowright,
        flowfront=flowfront, flowback=flowback,
        dy=dy, dx=dx, dt=dt))

print(f'DEBUG: stack arrays inside list to one whole array')
print(f'DEBUG: convert from HeAT array to ndarray')
wtd_ht              = ht.stack(wtd, axis=0)
wtd                 = wtd_ht.numpy()
print(f'Now Np: wtd.shape: {wtd.shape}')
del wtd_ht
overlandFlow_ht     = ht.stack(overlandFlow, axis=0)
overlandFlow        = overlandFlow_ht.numpy()
print(f'Now Np: overlandFlow.shape: {overlandFlow.shape}')
del overlandFlow_ht
surfStor_ht         = ht.stack(surfStor, axis=0)
surfStor            = surfStor_ht.numpy()
print(f'Now Np: surfStor.shape: {surfStor.shape}')
del surfStor_ht
subSurfStor_ht      = ht.stack(subSurfStor, axis=0)
subSurfStor         = subSurfStor_ht.numpy()
print(f'Now Np: subSurfStor.shape: {subSurfStor.shape}')
del subSurfStor_ht
saturSubSurfStor_ht = ht.stack(saturSubSurfStor, axis=0)
saturSubSurfStor    = saturSubSurfStor_ht.numpy()
print(f'Now Np: saturSubSurfStor.shape: {saturSubSurfStor.shape}')
del saturSubSurfStor_ht
subSurfRunoff_ht    = ht.stack(subSurfRunoff, axis=0)
subSurfRunoff       = subSurfRunoff_ht.numpy()
print(f'Now Np: subSurfRunoff.shape: {subSurfRunoff.shape}')
del subSurfRunoff_ht


print(f'DEBUG: reduze dim -- e.g. summ over entire column')
subSurfStor   = np.sum(subSurfStor, axis=1)
subSurfRunoff = np.sum(subSurfRunoff, axis=1)

#print(f'DEBUG: reduze to monthly data')
## monthly means
#wtdarray   = wtdarray.mean(axis=0, keepdims=True)  
##saturarray = saturarray.mean(axis=0, keepdims=True)  
##ssarray    = ssarray.mean(axis=0, keepdims=True)  
#sssarray   = sssarray.mean(axis=0, keepdims=True)  
#ssssarray  = ssssarray.mean(axis=0, keepdims=True)  
## monthly sums
#srarray    = np.sum(srarray, axis=0, keepdims=True) 
#ssrarray   = np.sum(ssrarray, axis=0, keepdims=True)

print(f'DEBUG: convert units')
# [m] --> [mm]
wtd              *= 1000
surfStor         *= 1000  
subSurfStor      *= 1000  
saturSubSurfStor *= 1000  
subSurfRunoff    *= 1000


print(f'DEBUG: get (mean) time value for netCDF output')
times        = np.array(times)
#time_mean    = np.mean(times)
timeUnit     = nc_timeUnits
timeCalendar = nc_calendar

print(f'DEBUG: mask lakes and sea')
# It seems np.ma.masked_where() cannot brodcast arrays by itself...
# So we have to do this manually.
# Assuming all variables does have the same dim (t,y,x) (t=1, but anyway)
llsm_b           = np.broadcast_to(LLSM, wtd.shape )
wtd              = np.ma.masked_where((llsm_b < 2), wtd)
overlandFlow     = np.ma.masked_where((llsm_b < 2), overlandFlow)
surfStor         = np.ma.masked_where((llsm_b < 2), surfStor)
subSurfStor      = np.ma.masked_where((llsm_b < 2), subSurfStor)
saturSubSurfStor = np.ma.masked_where((llsm_b < 2), saturSubSurfStor)
subSurfRunoff    = np.ma.masked_where((llsm_b < 2), subSurfRunoff)

print(f'DEBUG: writing to netCDF')
###############################################################################
#### WTD
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_wtd.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'Water table depth (simple algorithm) based on ParFlow',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar,
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('wtd', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'wtd'
    ncVar.long_name = 'water table depth'
    ncVar.units ='mm'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = wtd[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]

###############################################################################
#### overlandFlow
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_overlandFlow.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'overlandFlow based on ParFlow output (post-processed variable)',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar,
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('overlandFlow', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'overlandFlow'
    ncVar.long_name = 'overlandFlow'
    ncVar.units ='m^3/h'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = overlandFlow[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]

###############################################################################
#### Surface Storage
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_surfStor.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'Surface Storage based on ParFlow (post-processed variable)',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar, 
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('surfStor', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'surfStor'
    ncVar.long_name = 'surface storage'
    ncVar.units ='mm'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = surfStor[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]

###############################################################################
#### Subsurface Storage
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_subSurfStor.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'Subsurface Storage based on ParFlow (post-processed variable)',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar,
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('subSurfStor', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'subSurfStor'
    ncVar.long_name = 'subsurface storage'
    ncVar.units ='mm'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = subSurfStor[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]

###############################################################################
#### Saturated Subsurface Storage
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_saturSubSurfStor.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'Saturated Subsurface Storage based on ParFlow (post-processed variable)',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar,
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('saturSubSurfStor', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'saturSubSurfStor'
    ncVar.long_name = 'saturated subsurface storage'
    ncVar.units ='mm'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = saturSubSurfStor[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]

###############################################################################
#### Subsurface Runoff
###############################################################################
saveFile = f'{outDir}/{outPrepandName}_subSurfRunoff.nc'
if not os.path.exists(f'{outDir}'):
    os.makedirs(f'{outDir}')

description_str = [f'Subsurface Runoff based on ParFlow (post-processed variable)',
                ]
description_str = ' '.join(description_str)
netCDFFileName = sloth.IO.createNetCDF(saveFile, domain=griddesFile,
        calcLatLon=True, timeUnit=timeUnit, timeCalendar=timeCalendar,
        author='Niklas WAGNER', contact='n.wagner@fz-juelich.de',
        institution='FZJ - IBG-3', 
        history=f'Created: {datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}',
        description=description_str)

with nc.Dataset(netCDFFileName, 'a') as nc_file:
    # add some global attributes to the created netCDF file
    for name, value in globAttrs.items():
        setattr(nc_file, name, value)

    ncVar = nc_file.createVariable('subSurfRunoff', 'f8', ('time', 'rlat', 'rlon',),
                                        fill_value=-9999, zlib=True)
    ncVar.standard_name = 'subSurfRunoff'
    ncVar.long_name = 'subsurface runoff'
    ncVar.units ='mm'
    ncVar.grid_mapping = 'rotated_pole'
    ncVar[...] = subSurfRunoff[...]

    ncTime = nc_file.variables['time']
    ncTime[...] = times[...]
