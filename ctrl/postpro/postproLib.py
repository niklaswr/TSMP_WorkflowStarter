import heat as ht
import numpy as np
import sys
import os
import glob
import argparse
import netCDF4 as nc
import datetime

def calc_netLateralSubSurFlow(flowleft,flowright,flowfront,flowback,dy,dx,dt):
    '''
    return netLateralSubSurFlown in [L]
    '''
    netLateralSubSurFlow = flowleft-flowright+flowfront-flowback
    # convert:
    # '/ (dy * dx)' --> from [L^3/T] to [L/T]
    # '* dt' --> from [L/T] to [L]
    netLateralSubSurFlow = netLateralSubSurFlow / (dy * dx) * dt

    return netLateralSubSurFlow 

def calc_ss(surfPress):
    '''
    return ss in [L]
    '''
    ss = ht.where(surfPress>0., surfPress, 0)

    return ss

def calc_ssss(sss, press_t, poro, gwb_mask, wtd_z_index):
    '''
    return ssss in [L]
    '''
    # mask unsaturated storage (keep saturated storage / groudwater only)
    term1 = ht.where(gwb_mask==1, sss, 0.)
    term1 = ht.sum(term1, axis=0)
    # add fraction of groundwater storage of first cell not 100% saturated
    # Psi * poro  --> fraction waterstorage in [L]
    term = poro * press_t 
    term2 = ht.zeros(press_t.shape[-2:])
    nz = press_t.shape[0]
    for z in range(nz):
        term2 = ht.where(wtd_z_index==z, term[z], term2)

    term2 = ht.where(term2 < 0., 0., term2)
    # add both terms
    ssss = term1 + term2

    return ssss
