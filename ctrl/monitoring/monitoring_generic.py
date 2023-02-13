import numpy as np
import netCDF4 as nc
import sys
import glob
import os
import configparser
import sloth.SanityCheck
import argparse
import traceback

def parseList(args):
    """ convert a comma seperated str to a list 
    
    Convert a coma seperated string to a list and remove leading and tailing 
    spaces on the fly.
    """
    out = args.split(',')
    out = [item.strip(' ') for item in out]

    return out

def parseSlices(args):
    """ Convert literal strings to proper slices for numpy

    Slicing a numpy array is prity much straight forward with slices. This 
    function is creating a proper slice() object out of a string.
    Examples:
    i)  'None,8' --> (slice(None), 8) --> array[:,8]
    """
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
parser.add_argument('--runName', type=str, default='NotSet',
                    help='provide a run name to identify the monitoring plot.')
args = parser.parse_args()

configFile  = args.configFile
dataRootDir = args.dataRootDir
saveDir     = args.saveDir
imgFormat   = args.imgFormat
runName     = args.runName

config = configparser.ConfigParser()
config.read(configFile)

configSections = config.sections()
print(f'configSections: {configSections}')
# There is a 'template' section with the CONFIGfile to show possible keys. 
# This should be ignored here.
configSections.remove('template')

for configSection in configSections:
    try:
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
        maskBelow  = config[configSection]["maskBelow"]
        maskAbove  = config[configSection]["maskAbove"]
        ncFile     = f'{dataRootDir}/{fileName}'
        # To enable usage of patterns in fileName, we are using glob below.
        # This way we can read in multile files or handle varying dates in
        # file names etc. However, handling of multiple files is not yet 
        # implemented, so [0] is used.
        print(f'DEBUG: ncFile is {ncFile}')
        ncFiles    = sorted(glob.glob(ncFile))
        print(f'DEBUG: ncFiles: {ncFiles}')
        saveFile   = f'{saveDir}/{varName}.{imgFormat}'
        print(f'saveFile: {saveFile}')
    
        data = []
        for ncFile in ncFiles:
            with nc.Dataset(ncFile, 'r') as nc_file:
                nc_var = nc_file.variables[varName]
                nc_var_dim = nc_var.shape
                # special treatment to flexible pass how to slice
                tmp_data   = nc_var.__getitem__(Slices)
                print(f'tmp_data.shape: {tmp_data.shape}')
                data.append(tmp_data)
        # if elements in data are 3D:
        #   assuming (t,y,x) and concatanate
        if len(data[0].shape) == 3:
            print(f'found: len(data[0].shape) = {len(data[0].shape)}')
            data = np.concatenate(data, axis=0)
        else:
            print(f'found: len(data[0].shape) = {len(data[0].shape)}')
            data = np.stack(data, axis=0)
        print(f'data.shape {data.shape}')
        print(f'DEBUG: np.max(data) {np.max(data)}')

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

        if maskBelow != 'None':
            thresBelow = float(maskBelow)
            data = np.ma.masked_where(data<thresBelow, data)
        if maskAbove != 'None':
            thresAbove = float(maskAbove)
            data = np.ma.masked_where(data>thresAbove, data)
        # change units if needed:
        if unitOffset != 'None':
            unitOffset = float(unitOffset)
            data       += unitOffset
        if unitCoef != 'None':
            unitCoef = float(unitCoef)
            data     *= unitCoef
        print(f'DEBUG: np.max(data) {np.max(data)}')

        sloth.SanityCheck.plot_SanityCheck(data=data,
                kind=SanityKind, figname=saveFile,
                lowerP=5, upperP=95, fig_title=fig_title, 
                minax_title=minax_title, maxax_title=maxax_title, 
                kinax_title=kinax_title, hisax_title=hisax_title,
                cmapName=cmapName)

    except FileNotFoundError as e:
        print(e.message, e.args)
        print(f"ERROR: A file was not found for {configSection}--> skip")
        continue
    except Exception:
        print(f"some other error for {configSection}:")
        traceback.print_exc()
        print(' --> skip')
        continue
