# Import the ParFlow TCL package
lappend auto_path /p/project/cesmtst/poshyvailo1/terrsysmp_current_pfl_sink/bin/JUWELS_3.1.0MCT_clm-cos-pfl/bin

package require parflow
namespace import Parflow::*

pfset FileVersion 4

pfset Process.Topology.P 12
pfset Process.Topology.Q 12
pfset Process.Topology.R 1
# THE COMPUTATIONAL GRID IS A (BOX) THT CONTAINS THE MAIN PROBLEM. THIS CAN EITHER BE EXACTLY THE SIZE
# OF THE PROBLEM OR LARGER. A BOX GEOMETRY IN PARFLOW CAN BE ASIGNED BY EITHER SPECIFYING COORDINATES FOR
# TWO CORNERS OF THE BOX OR GRID SIZE AND NUMBER OF CELLS IN X,Y, AND Z.
#------------------------------------------------------------------------
# Computational Grid: It Defines The Grid Resolutions within The Domain
#------------------------------------------------------------------------
pfset ComputationalGrid.Lower.X                  0.0
pfset ComputationalGrid.Lower.Y                  0.0
pfset ComputationalGrid.Lower.Z                  0.0

pfset ComputationalGrid.DX                       12500.0
pfset ComputationalGrid.DY                       12500.0
pfset ComputationalGrid.DZ                       2.0

pfset ComputationalGrid.NX                       436
pfset ComputationalGrid.NY                       424
pfset ComputationalGrid.NZ                       15

#-----------------------------------------------------------------------------
# Domain
#-----------------------------------------------------------------------------
pfset Domain.GeomName                            domain

#---------------------------------------------------------
# Domain Geometry Input 
#---------------------------------------------------------
#pfset GeomInput.Names                 "solidinput"
#pfset GeomInput.solidinput.InputType  SolidFile
#pfset GeomInput.solidinput.GeomNames  domain
#pfset GeomInput.solidinput.FileName   /homea/jicg43/jicg4301/jkeune/tsmp_cordex/data/input/cordex_pfl/geom_cordex_glacier.pfsol
#pfset Geom.domain.Patches             "top bottom perimeter"

#--------------------------------------------------------
# Distribute Files 
#--------------------------------------------------------
set data [pfload -sa ParFlow_SOIL_INDICATOR3_from_EUR03_x1592y1544z15_on_EUR11_x436y424z15.sa]
pfsave $data -pfb ParFlow_SOIL_INDICATOR3_from_EUR03_x1592y1544z15_on_EUR11_x436y424z15.pfb
pfdist ParFlow_SOIL_INDICATOR3_from_EUR03_x1592y1544z15_on_EUR11_x436y424z15.pfb
