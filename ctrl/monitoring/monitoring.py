import numpy as np
import netCDF4 as nc
import sys
import os
import configparser
import sloth
import argparse

def parseList(args):
    """ convert a comma seperates str to a list 
    
    While converting leading and tailing spaces are removed.
    """
    out = args.split(',')
    out = [item.strip(' ') for item in out]

    return out

def parseSlices(args):
    out = tuple(( int(item) if item != 'None' else slice(None) for item in args))
    if out:
        return out
    else:
        return None

parser = argparse.ArgumentParser(description='Tell me what this script can do!.')
parser.add_argument('--configFile', '-c', type=str, required=True,
                    help='provide the config files holding variables to be monitored')
parser.add_argument('--dataRootDir', '-r', type=str, required=True,
                    help='provide the root dir where the data is located')
parser.add_argument('--saveDir', '-s', type=str, required=True,
                    help='provide the dir where to save the monitoring plots')
parser.add_argument('--imgFormat', type=str, default='png',
                    help='provide the format the monitoring plots should be saved (default=png)')
args = parser.parse_args()

configFile  = args.configFile
dataRootDir = args.dataRootDir
saveDir     = args.saveDir
imgFormat   = args.imgFormat

# get runname aka data 
# split dataRootDir along '/'
DataRootDir_split = dataRootDir.split('/')
# remove empty entries, to catch if /PATH/TO or /PATH/TO/ is passed
DataRootDir_split = [x for x in DataRootDir_split if x] 
# last entry is runname aka date
runName = DataRootDir_split[-1]

config = configparser.ConfigParser()
config.read(configFile)

configSections = config.sections()
print(f'configSections: {configSections}')
# There is a 'template' section with the CONFIGfile to show possible keys. 
# This should be ignored here.
configSections.remove('template')

for configSection in configSections:
    print('######################################################')
    print(f'processing: {configSection}')
    varName    = config[configSection]["varName"]
    fileName   = config[configSection]["fileName"]
    unitsOrig  = config[configSection]["unitsOrig"]
    unitsPlot  = config[configSection]["unitsPlot"]
    unitCoef   = config[configSection]["unitCoef"]
    unitOffset = config[configSection]["unitOffset"]
    Slices     = parseList(config[configSection]["Slices"])
    Slices     = parseSlices(Slices)
    SanityKind = config[configSection]["SanityKind"]
    cmapName   = config[configSection]["cmapName"]
    ncFile     = f'{dataRootDir}/{fileName}'
    print(f'ncFile: {ncFile}')
    saveFile   = f'{saveDir}/{os.path.splitext(fileName)[0]}.{imgFormat}'
    print(f'saveFile: {saveFile}')
    
    with nc.Dataset(ncFile, 'r') as nc_file:
        nc_var = nc_file.variables[varName]
        nc_var_dim = nc_var.shape
        # special treatment to flexible pass how to slice
        data   = nc_var.__getitem__(Slices)
        print(f'data.shape: {data.shape}')

    fig_title_list  = [
            f'Sanity-Check for {configSection} in {unitsPlot}',
            f'original data shape: {nc_var_dim} -- sliced with: {Slices}',
            f'run: {runName}'
            ]
    fig_title    = '\n'.join(fig_title_list)
    minax_title  = f'{varName} min'
    maxax_title  = f'{varName} max'
    kinax_title  = f'{varName} {SanityKind}'
    hisax_title  = f'{varName} {SanityKind} - distribution'


    mask   = np.ma.getmaskarray(data)
    data   = data.filled(fill_value=np.nan)
    # change units if needed:
    if unitOffset != 'None':
        unitOffset = float(unitOffset)
        data       += unitOffset
    if unitCoef != 'None':
        unitCoef = float(unitCoef)
        data     *= unitCoef

    sloth.SanityCheck.plot_SanityCheck_3D(data=data,
            data_mask=mask, kind=SanityKind, figname=saveFile,
            lowerP=5, upperP=95, fig_title=fig_title, 
            minax_title=minax_title, maxax_title=maxax_title, 
            kinax_title=kinax_title, hisax_title=hisax_title,
            cmapName=cmapName)

