import numpy as np
import netCDF4 as nc
import sys
import glob
import os
import configparser
import sloth.SanityCheck
import sloth.toolBox
import argparse
import matplotlib as mpl
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
import datetime


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
parser.add_argument('--tmpDataDir', '-t', type=str, required=True,
                    help='provide the dir where to save tmp data for time series')
parser.add_argument('--imgFormat', type=str, default='png',
                    help='provide the format the monitoring plots should be saved (default=png)')
parser.add_argument('--runName', type=str, default='NotSet',
                    help='provide a run name to identify the monitoring plot.')
args = parser.parse_args()

configFile  = args.configFile
dataRootDir = args.dataRootDir
saveDir     = args.saveDir
tmpDataDir  = args.tmpDataDir
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
        prudRegs   = config[configSection]["prudRegs"]
        prudRegs   = prudRegs.strip().split(',')
        print(f'DEBUG: prudRegs {prudRegs}')
        cmapName   = config[configSection]["cmapName"]
        ncFile     = f'{dataRootDir}/{fileName}'
        # To enable usage of patterns in fileName, we are using glob below.
        # This way we can read in multile files or handle varying dates in
        # file names etc. However, handling of multiple files is not yet 
        # implemented, so [0] is used.
        print(f'DEBUG: ncFile is {ncFile}')
        ncFile     = sorted(glob.glob(ncFile))[0]
        print(f'ncFile: {ncFile}')
    
        with nc.Dataset(ncFile, 'r') as nc_file:
            nc_var       = nc_file.variables[varName]
            nc_var_dim   = nc_var.shape
            lat          = nc_file.variables['lat'][...]
            lon          = nc_file.variables['lon'][...]
            nc_time      = nc_file.variables['time']
            srcDates     = nc.num2date(nc_time[:],units=nc_time.units,
                    calendar=nc_time.calendar)
            print(f'DEBUG: srcDates {srcDates}')
            srcTimeUnits = nc_time.units
            print(f'DEBUG: srcTimeUnits {srcTimeUnits}')
            srcCalendar  = nc_time.calendar
            print(f'DEBUG: srcCalendar {srcCalendar}')
            print(f'DEBUG: srcTimeValues {nc_time[...]}')
            # special treatment to flexible pass how to slice
            data   = nc_var.__getitem__(Slices)
            print(f'data.shape: {data.shape}')

        for prudReg in prudRegs:
            print(f'DEBUG: handle prudReg {prudReg}')
            # set filename for tmp .nc files to hold passt monitoring data
            tmpNcData = f'{tmpDataDir}/{varName}_ts_prud-{prudReg}.nc'
            # set filename for monitoring plot
            saveFile   = f'{saveDir}/{varName}_{prudReg}.{imgFormat}'
            print(f'saveFile: {saveFile}')

            prudMask = sloth.toolBox.get_prudenceMask(lat2D=lat, lon2D=lon,
                    prudName=prudReg)
            # Broadcast prudMask
            prudMask_b  = np.broadcast_to(prudMask, data.shape)
            plotData    = np.ma.masked_where(prudMask_b==1, data)

            # mean or sum over domain for time series (ts)
            # assuming 3D data in (t,y,x)
            # mean / sum in 2 steps, to keep only time time
            if SanityKind == "mean":
                plotData = np.ma.mean(plotData, axis=(-2,-1))
                plotData = np.ma.mean(plotData, keepdims=True)
            if SanityKind == "sum":
                plotData = np.ma.sum(plotData, axis=(-2,-1))
                plotData = np.ma.sum(plotData, keepdims=True)
            
            # change units if needed:
            if unitOffset != 'None':
                unitOffset = float(unitOffset)
                plotData       += unitOffset
            if unitCoef != 'None':
                unitCoef = float(unitCoef)
                plotData     *= unitCoef
            print(f'before: data: {data}')
            print(f'before: data.shape: {data.shape}')

            # Convert time units to another reference data, to ensure we are dealing
            # with compareable time values. Further convert to calendar "standard"
            # as python dates (needed for plotting) can not handly special 
            # calendars.
            tgtRefDate    = "1949-12-1 00:00:00" # target ref date / nc-time unit
            tgtTimeUnits  = f"hours since {tgtRefDate}"
            tgtCalendar   = "standard"
            tgtTimeValues = nc.date2num(srcDates,units=tgtTimeUnits,
                    calendar=tgtCalendar)
            # Mean time values as we do handl mean data
            timeMean = np.mean(tgtTimeValues)

            # Append data to tmp data file or create if not exist yet
            if os.path.isfile(tmpNcData):
                with nc.Dataset(tmpNcData, 'a') as nc_file:
                    nc_data  = nc_file.variables[varName]
                    nc_time  = nc_file.variables['time'] 
                    idx_max  = nc_data.shape[0]

                    nc_data[idx_max] = plotData
                    plotData = nc_data[...]
                    nc_time[idx_max] = timeMean
                    time = nc_time[...]

                    # Sort according to time values.
                    # This could be needed, in case tmp time series nc-files was not
                    # filled step by step. Howeverm as we do handle proper time
                    # values this is not a problem.
                    timesortidx = time.argsort()
                    tmp_time = time[timesortidx]
                    time = tmp_time
                    tmp_data = plotData[timesortidx]
                    plotData = tmp_data
            else:
                with nc.Dataset(tmpNcData, 'w', format='NETCDF4') as nc_file:
                    dtime   = nc_file.createDimension('time',None)
                    nc_data = nc_file.createVariable(varName, 'f8', ('time',),
                            zlib=True)
                    nc_time = nc_file.createVariable('time', 'f8', ('time',))
                    idx_max = nc_data.shape[0]

                    nc_data[idx_max] = plotData
                    nc_time[idx_max] = timeMean
                    time = nc_time[...]
            print(f'after: plotData: {plotData}')
            print(f'after: plotData.shape: {plotData.shape}')

            # Convert time values to dates for nice plot. Thereby force to use 
            # python dates and not cftime dates, that matplotlib can handle
            dates = nc.num2date(time,units=tgtTimeUnits, calendar=tgtCalendar,
                    only_use_cftime_datetimes=False,
                    only_use_python_datetimes=True)
            print(f'DEBUG: (plot) dates {dates}')
            print(f'DEBUG: type(dates[0]) {type(dates[0])}')


            fig_title_list  = [
                    f'TS monitoring {configSection} in {unitsPlot}',
                    f'SanityKind: {SanityKind}',
                    f'run: {runName}',
                    f'prudReg: {prudReg}'
                    ]
            fig_title    = '\n'.join(fig_title_list)

            shortMeanPeriod = 12
            data_alltime_mean = np.mean(plotData, keepdims=True)
            # Init data_shorttime_mean with data_alltime_mean to avoid shape / data
            # type missmatch in plot
            data_shorttime_mean = data_alltime_mean
            if plotData.shape[0] >= shortMeanPeriod:
                data_shorttime_mean = np.mean(plotData[-1*shortMeanPeriod:])

            fig = plt.figure()
            ax = fig.add_subplot(1, 1, 1)

            ax.set_title(fig_title)
            ax.axhline(y=0, color='red')
            # plot x-values in days since plot point
            xvalues = (time - np.min(time))/24. #np.arange(plotData.shape[0])
            ax.plot(xvalues, plotData - data_alltime_mean, label='alltime anomaly') 
            ax.plot(xvalues[-1*shortMeanPeriod:], plotData[-1*shortMeanPeriod:] - data_shorttime_mean, label=f'shorttime anomaly (shortMeanPeriod: {shortMeanPeriod})') 

            ax.set_xlabel(f'days since simulation start')
            ax.set_ylabel(f'{configSection} in {unitsPlot}')
            ax.legend()

            fig.savefig(saveFile)


    except FileNotFoundError as e:
        print(e.message, e.args)
        print(f"ERROR: A file was not found for {configSection}--> skip")
        continue
    except:
        e = sys.exc_info()[0]
        print(f"some other error for {configSection}")
        print(e.message, e.args)
        print(' --> skip')
        continue

