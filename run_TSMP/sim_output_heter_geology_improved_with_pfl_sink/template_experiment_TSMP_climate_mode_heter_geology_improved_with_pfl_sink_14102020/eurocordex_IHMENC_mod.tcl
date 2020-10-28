# Import the ParFlow TCL package
#
lappend auto_path $env(PARFLOW_DIR)/bin
package require parflow
namespace import Parflow::*
#
#For normal soils, need to fix near saturation CPS
set VG_points 20000
set VG_pmin -50.0
#set VG_interpolation_method "Spline"

#--------------------------------------------------------
pfset FileVersion 4
#-------------------------------------------------------

set NP  [lindex $argv 0]
set NQ  [lindex $argv 1]
pfset Process.Topology.P $NP
pfset Process.Topology.Q $NQ
pfset Process.Topology.R 1
set runname cordexIHME

# THE COMPUTATIONAL GRID IS A (BOX) THT CONTAINS THE MAIN PROBLEM. THIS CAN EITHER BE EXACTLY THE SIZE
# OF THE PROBLEM OR LARGER. A BOX GEOMETRY IN PARFLOW CAN BE ASIGNED BY EITHER SPECIFYING COORDINATES FOR
# TWO CORNERS OF THE BOX OR GRID SIZE AND NUMBER OF CELLS IN X,Y, AND Z.
#------------------------------------------------------------------------
# Computational Grid: It Defines The Grid Resolutions within The Domain
#------------------------------------------------------------------------
pfset ComputationalGrid.Lower.X			 0.0
pfset ComputationalGrid.Lower.Y			 0.0
pfset ComputationalGrid.Lower.Z			 0.0

set DX          3000.0
set DY          3000.0
set DZ          2.0

pfset ComputationalGrid.DX                       $DX
pfset ComputationalGrid.DY                       $DY
pfset ComputationalGrid.DZ                       $DZ

set NX          1592
set NY          1544
set NZ          15

pfset ComputationalGrid.NX               [ expr $NX ]
pfset ComputationalGrid.NY               [ expr $NY ]
pfset ComputationalGrid.NZ               [ expr $NZ ]

# DOMAIN GEOMETRY IS THE (EXACTLY) OUTER DOMAIN OR BOUNDARY OF THE MODEL PROBLEM. IT HAS TO BE CONTAINED WITHIN THE COMPUTATIONAL GRID (i.e.
# OR HAS THE SAME SIZE OF IT). THE DOMAIN GEOMETRY COULD BE A BOX OR IT COULD BE A SOLID-FILE.
# BOUNDARY CONDITIONS ARE ASSIGNED TO THE DOMAIN SIDES WITH SOMETHING CALLED (PATCHES) IN THE TCL-SCRIPT.
# A BOX HAS SIX (6) SIDES AND (6) PATCHES WHILE A SOLID-FILE CAN HAVE ANY NUMBER OF PATCHES.
#-----------------------------------------------------------------------------
# Domain
#-----------------------------------------------------------------------------
pfset Domain.GeomName                            domain

#---------------------------------------------------------
# Domain Geometry Input 
#---------------------------------------------------------

 pfset GeomInput.Names                 "solidinput indi_input"
 pfset GeomInput.solidinput.InputType  SolidFile
 pfset GeomInput.solidinput.GeomNames  domain
 pfset GeomInput.solidinput.FileName   "geom_cordex003_3184x3088.pfsol"
 pfset Geom.domain.Patches             "top bottom perimeter"

#-----------------------------------------------------------------------------
# VARIABLE dz ASSIGNMENTS
#-----------------------------------------------------------------------------
pfset Solver.Nonlinear.VariableDz    True
pfset dzScale.GeomNames              domain
pfset dzScale.Type                   nzList
pfset dzScale.nzListNumber           15
# NOTE each cell depth is dz*dzScale!!!!!!
pfset Cell.0.dzScale.Value           9.0
pfset Cell.1.dzScale.Value           7.50
pfset Cell.2.dzScale.Value           5.0
pfset Cell.3.dzScale.Value           5.0
pfset Cell.4.dzScale.Value           2.0
pfset Cell.5.dzScale.Value           0.50
pfset Cell.6.dzScale.Value           0.35
pfset Cell.7.dzScale.Value           0.25
pfset Cell.8.dzScale.Value           0.15
pfset Cell.9.dzScale.Value           0.10
pfset Cell.10.dzScale.Value          0.065
pfset Cell.11.dzScale.Value          0.035
pfset Cell.12.dzScale.Value          0.025
pfset Cell.13.dzScale.Value          0.015
pfset Cell.14.dzScale.Value          0.01


#----------------------------------------------------------------
# Indicator Geometry Input
#----------------------------------------------------------------

pfset GeomInput.indi_input.InputType IndicatorField
pfset GeomInput.indi_input.GeomNames "F1 F2 F3 F4 F5 F6 water W1 W2 W3 W4 W6 W7 W8 W9 W11 W12 W13 W15 W16 W14 B40"
pfset Geom.indi_input.FileName "ParFlow_SOIL_INDICATOR3_x1592y1544z15.pfb" 

## Subsurface database 1-6 where 1 is highly productive aquifer and 6 is virtually no groundwater
pfset GeomInput.F1.Value 1
pfset GeomInput.F2.Value 2
pfset GeomInput.F3.Value 3
pfset GeomInput.F4.Value 4
pfset GeomInput.F5.Value 5
pfset GeomInput.F6.Value 6
pfset GeomInput.water.Value 9999

## FAO soil database
# sand
pfset GeomInput.W1.Value 18
# loamy sand
pfset GeomInput.W2.Value 19
# sandy loam
pfset GeomInput.W3.Value 20
# silt loam
pfset GeomInput.W4.Value 21
# silt
#pfset GeomInput.W5.Value 22
# loam
pfset GeomInput.W6.Value 23
# sandy clay loam
pfset GeomInput.W7.Value 24
# silty clay loam
pfset GeomInput.W8.Value 25
# clay loam
pfset GeomInput.W9.Value 26
# sandy clay
#pfset GeomInput.W10.Value 27
# silty clay
pfset GeomInput.W11.Value 28
# clay
pfset GeomInput.W12.Value 29
# organic material
pfset GeomInput.W13.Value 30
# water
pfset GeomInput.W14.Value 31
# bedrock
pfset GeomInput.W15.Value 32
# others
pfset GeomInput.W16.Value 33

## additional layer at the bottom with increased conductivity
pfset GeomInput.B40.Value 40

#TIME SETUP
#-----------------------------------------------------------------------------
# Setup timing info
#-----------------------------------------------------------------------------
pfset TimingInfo.BaseUnit                1.0
pfset TimingInfo.StartCount              0.0
pfset TimingInfo.StartTime               0.0
pfset TimingInfo.StopTime                168.0
pfset TimeStep.Type                      Constant
pfset TimeStep.Value                     1.0
pfset TimingInfo.DumpInterval            1.0


# Time Cycles
#-----------------------------------------------------------------------------
pfset Cycle.Names "constant"
pfset Cycle.constant.Names              "alltime"
pfset Cycle.constant.alltime.Length      1
pfset Cycle.constant.Repeat             -1

#  HYDROLOGICAL PARAMETERS
#Schaap and Leiz (1998), Soil Science
#  SETUP AND VALUES
#-----------------------------------------------------------------------------
# Perm
#-----------------------------------------------------------------------------
pfset Geom.Perm.Names		   "domain F1 F2 F3 F4 F5 F6 water W1 W2 W3 W4 W6 W7 W8 W9 W11 W12 W13 W15 W16 W14 B40"

pfset Geom.domain.Perm.Type        Constant
pfset Geom.domain.Perm.Value       0.1

## IHME plus Rivers as aquifers where permeability ranges are set according to the general ranges of soil permeability (FAO) and T. GLEESON data
pfset Geom.F1.Perm.Type            Constant
pfset Geom.F1.Perm.Value           0.1
pfset Geom.F2.Perm.Type            Constant
pfset Geom.F2.Perm.Value           0.05
pfset Geom.F3.Perm.Type            Constant
pfset Geom.F3.Perm.Value           0.001
pfset Geom.F4.Perm.Type            Constant
pfset Geom.F4.Perm.Value           0.0005
pfset Geom.F5.Perm.Type            Constant
pfset Geom.F5.Perm.Value           0.00001
pfset Geom.F6.Perm.Type            Constant
pfset Geom.F6.Perm.Value           0.000005
pfset Geom.water.Perm.Type         Constant
pfset Geom.water.Perm.Value        0.000000001

## FAO
pfset Geom.W1.Perm.Type           Constant
pfset Geom.W1.Perm.Value          0.269022595
pfset Geom.W2.Perm.Type           Constant
pfset Geom.W2.Perm.Value          0.043630356
pfset Geom.W3.Perm.Type           Constant
pfset Geom.W3.Perm.Value          0.015841225
pfset Geom.W4.Perm.Type           Constant
pfset Geom.W4.Perm.Value          0.007582087
pfset Geom.W6.Perm.Type           Constant
pfset Geom.W6.Perm.Value          0.026289889
pfset Geom.W7.Perm.Type           Constant
pfset Geom.W7.Perm.Value          0.005492736
pfset Geom.W8.Perm.Type           Constant
pfset Geom.W8.Perm.Value          0.004675077
pfset Geom.W9.Perm.Type           Constant
pfset Geom.W9.Perm.Value          0.003386794
pfset Geom.W11.Perm.Type          Constant
pfset Geom.W11.Perm.Value         0.003979136
pfset Geom.W12.Perm.Type          Constant
pfset Geom.W12.Perm.Value         0.006162952
pfset Geom.W13.Perm.Type          Constant
pfset Geom.W13.Perm.Value         0.01
pfset Geom.W15.Perm.Type          Constant
pfset Geom.W15.Perm.Value         0.5
pfset Geom.W16.Perm.Type          Constant
pfset Geom.W16.Perm.Value         0.1
pfset Geom.W14.Perm.Type          Constant
pfset Geom.W14.Perm.Value         0.1

## Additional highly conductive layer at the bottom
pfset Geom.B40.Perm.Type	  Constant
pfset Geom.B40.Perm.Value	  0.1

pfset Perm.TensorType			 TensorByGeom
pfset Geom.Perm.TensorByGeom.Names	 "domain"
pfset Geom.domain.Perm.TensorValX	 1.0
pfset Geom.domain.Perm.TensorValY	 1.0
pfset Geom.domain.Perm.TensorValZ	 1.0

#-----------------------------------------------------------------------------
# Specific Storage
#-----------------------------------------------------------------------------
pfset SpecificStorage.Type			 Constant
pfset SpecificStorage.GeomNames			 "domain"
pfset Geom.domain.SpecificStorage.Value		 1.0e-7

#-----------------------------------------------------------------------------
# Phases
#-----------------------------------------------------------------------------
pfset Phase.Names			 "water"
pfset Phase.water.Density.Type		 Constant
pfset Phase.water.Density.Value		 1.0
pfset Phase.water.Viscosity.Type	 Constant
pfset Phase.water.Viscosity.Value	 1.0

#-----------------------------------------------------------------------------
# Gravity
#-----------------------------------------------------------------------------
pfset Gravity				 1.0

#-----------------------------------------------------------------------------
# Contaminants
#-----------------------------------------------------------------------------
pfset Contaminants.Names		 ""

#-----------------------------------------------------------------------------
# Retardation
#-----------------------------------------------------------------------------
pfset Geom.Retardation.GeomNames	 ""

#-----------------------------------------------------------------------------
# Porosity
#-----------------------------------------------------------------------------
pfset Geom.Porosity.GeomNames          "domain W1 W2 W3 W4 W6 W7 W8 W9 W11 W12 W13 W15 W16 W14"

pfset Geom.domain.Porosity.Type        Constant
pfset Geom.domain.Porosity.Value       0.4

pfset Geom.W1.Porosity.Type            Constant
pfset Geom.W1.Porosity.Value           0.3693
pfset Geom.W2.Porosity.Type            Constant
pfset Geom.W2.Porosity.Value           0.3819
pfset Geom.W3.Porosity.Type            Constant
pfset Geom.W3.Porosity.Value           0.4071
pfset Geom.W4.Porosity.Type            Constant
pfset Geom.W4.Porosity.Value           0.4760
pfset Geom.W6.Porosity.Type            Constant
pfset Geom.W6.Porosity.Value           0.4390
pfset Geom.W7.Porosity.Type            Constant
pfset Geom.W7.Porosity.Value           0.4040
pfset Geom.W8.Porosity.Type            Constant
pfset Geom.W8.Porosity.Value           0.4640
pfset Geom.W9.Porosity.Type            Constant
pfset Geom.W9.Porosity.Value           0.4386
pfset Geom.W11.Porosity.Type           Constant
pfset Geom.W11.Porosity.Value          0.4789
pfset Geom.W12.Porosity.Type           Constant
pfset Geom.W12.Porosity.Value          0.4680
pfset Geom.W13.Porosity.Type           Constant
pfset Geom.W13.Porosity.Value          0.4
pfset Geom.W15.Porosity.Type           Constant
pfset Geom.W15.Porosity.Value          0.1
pfset Geom.W16.Porosity.Type           Constant
pfset Geom.W16.Porosity.Value          0.1
pfset Geom.W14.Porosity.Type           Constant
pfset Geom.W14.Porosity.Value          0.1

#-----------------------------------------------------------------------------
# Relative Permeability
#-----------------------------------------------------------------------------

pfset Phase.RelPerm.Type               VanGenuchten
pfset Phase.RelPerm.GeomNames          "domain W1 W2 W3 W4 W6 W7 W8 W9 W11 W12 W13 W15 W16 W14"

pfset Geom.domain.RelPerm.Alpha        2.0
pfset Geom.domain.RelPerm.N            3.

pfset Geom.W1.RelPerm.Alpha            3.548134
pfset Geom.W1.RelPerm.N                3.162278 
pfset Geom.W2.RelPerm.Alpha            3.467369
pfset Geom.W2.RelPerm.N                2.01
pfset Geom.W3.RelPerm.Alpha            2.691535
pfset Geom.W3.RelPerm.N                2.01
pfset Geom.W4.RelPerm.Alpha            0.501187
pfset Geom.W4.RelPerm.N                2.01
pfset Geom.W6.RelPerm.Alpha            1.122018
pfset Geom.W6.RelPerm.N                2.01
pfset Geom.W7.RelPerm.Alpha            2.089296
pfset Geom.W7.RelPerm.N                2.01
pfset Geom.W8.RelPerm.Alpha            0.831764
pfset Geom.W8.RelPerm.N                2.01
pfset Geom.W9.RelPerm.Alpha            1.584893
pfset Geom.W9.RelPerm.N                2.01
pfset Geom.W11.RelPerm.Alpha           1.621810
pfset Geom.W11.RelPerm.N               2.01
pfset Geom.W12.RelPerm.Alpha            1.513561
pfset Geom.W12.RelPerm.N                2.01
pfset Geom.W13.RelPerm.Alpha            2.0
pfset Geom.W13.RelPerm.N                3. 
pfset Geom.W15.RelPerm.Alpha            2.0
pfset Geom.W15.RelPerm.N                3.
pfset Geom.W16.RelPerm.Alpha            2.0
pfset Geom.W16.RelPerm.N                3. 
pfset Geom.W14.RelPerm.Alpha            2.0
pfset Geom.W14.RelPerm.N                3. 

#---------------------------------------------------------
# Saturation
#---------------------------------------------------------

pfset Phase.Saturation.Type              VanGenuchten
pfset Phase.Saturation.GeomNames          "domain W1 W2 W3 W4 W6 W7 W8 W9 W11 W12 W13 W15 W16 W14"

pfset Geom.domain.Saturation.Alpha        2.0
pfset Geom.domain.Saturation.N            3.
pfset Geom.domain.Saturation.SRes         0.1
pfset Geom.domain.Saturation.SSat         1.0

pfset Geom.W1.Saturation.Alpha            3.548134
pfset Geom.W1.Saturation.N                3.162278
pfset Geom.W1.Saturation.SRes             0.076
pfset Geom.W1.Saturation.SSat             1.0
pfset Geom.W2.Saturation.Alpha            3.467369
pfset Geom.W2.Saturation.SRes             0.0628
pfset Geom.W2.Saturation.SSat             1.0
pfset Geom.W2.Saturation.N                2.01
pfset Geom.W3.Saturation.Alpha            2.691535
pfset Geom.W3.Saturation.SRes             0.05037
pfset Geom.W3.Saturation.SSat             1.0
pfset Geom.W3.Saturation.N                2.01
pfset Geom.W4.Saturation.Alpha            0.501187
pfset Geom.W4.Saturation.SRes             0.074032
pfset Geom.W4.Saturation.SSat             1.0
pfset Geom.W4.Saturation.N                2.01
pfset Geom.W6.Saturation.Alpha            1.122018
pfset Geom.W6.Saturation.SRes             0.076441
pfset Geom.W6.Saturation.SSat             1.0
pfset Geom.W6.Saturation.N                2.01
pfset Geom.W7.Saturation.Alpha            2.089296
pfset Geom.W7.Saturation.SRes             0.082031
pfset Geom.W7.Saturation.SSat             1.0
pfset Geom.W7.Saturation.N                2.01
pfset Geom.W8.Saturation.Alpha            0.831764
pfset Geom.W8.Saturation.SRes             0.093361
pfset Geom.W8.Saturation.SSat             1.0
pfset Geom.W8.Saturation.N                2.01
pfset Geom.W9.Saturation.Alpha            1.584893
pfset Geom.W9.Saturation.SRes             0.084361
pfset Geom.W9.Saturation.SSat             1.0
pfset Geom.W9.Saturation.N                2.01
pfset Geom.W11.Saturation.Alpha           1.621810
pfset Geom.W11.Saturation.SRes            0.125384
pfset Geom.W11.Saturation.SSat            1.0
pfset Geom.W11.Saturation.N               2.01
pfset Geom.W12.Saturation.Alpha           1.513561
pfset Geom.W12.Saturation.SRes            0.106704
pfset Geom.W12.Saturation.SSat            1.0
pfset Geom.W12.Saturation.N               2.01
pfset Geom.W13.Saturation.Alpha           2.0
pfset Geom.W13.Saturation.N               3.
pfset Geom.W13.Saturation.SRes            0.1
pfset Geom.W13.Saturation.SSat            1.0
pfset Geom.W15.Saturation.Alpha           2.0
pfset Geom.W15.Saturation.N               3.
pfset Geom.W15.Saturation.SRes            0.1
pfset Geom.W15.Saturation.SSat            1.0
pfset Geom.W16.Saturation.Alpha           2.0
pfset Geom.W16.Saturation.N               3.
pfset Geom.W16.Saturation.SRes            0.2
pfset Geom.W16.Saturation.SSat            1.0
pfset Geom.W14.Saturation.Alpha           2.0
pfset Geom.W14.Saturation.N               3.
pfset Geom.W14.Saturation.SRes            0.1
pfset Geom.W14.Saturation.SSat            1.0



#-----------------------------------------------------------------------------
# Wells
#-----------------------------------------------------------------------------
pfset Wells.Names				 ""

#-----------------------------------------------------------------------------
# Boundary Conditions: Pressure
#-----------------------------------------------------------------------------

pfset BCPressure.PatchNames                   [pfget Geom.domain.Patches]

pfset Patch.top.BCPressure.Type                     OverlandFlow
pfset Patch.top.BCPressure.Cycle                    "constant"
pfset Patch.top.BCPressure.alltime.Value            0.0

pfset Patch.bottom.BCPressure.Type                  FluxConst
pfset Patch.bottom.BCPressure.Cycle                 "constant"
pfset Patch.bottom.BCPressure.alltime.Value         0.0

# Dirichlet BC
pfset Patch.perimeter.BCPressure.Type 		    DirEquilRefPatch
pfset Patch.perimeter.BCPressure.Cycle		    "constant"
pfset Patch.perimeter.BCPressure.RefGeom     	    domain
pfset Patch.perimeter.BCPressure.RefPatch    	    top
pfset Patch.perimeter.BCPressure.alltime.Value      -0.05

#pfset Patch.perimeter.BCPressure.Type                  FluxConst
#pfset Patch.perimeter.BCPressure.Cycle                 "constant"
#pfset Patch.perimeter.BCPressure.alltime.Value         0.0


#  TOPOGRAPHY & SLOPES IN
#  BOTH X- & Y- DIRECTIONS
#---------------------------------------------------------
# Topo slopes in x-direction
#---------------------------------------------------------
pfset TopoSlopesX.Type			 "PFBFile"
pfset TopoSlopesX.GeomNames		 "domain"
pfset TopoSlopesX.FileName		 "ParFlow_MB3km_SLPX_x1592y1544.pfb"

#---------------------------------------------------------
# Topo slopes in y-direction
#---------------------------------------------------------
pfset TopoSlopesY.Type                   "PFBFile"
pfset TopoSlopesY.GeomNames              "domain"
pfset TopoSlopesY.FileName               "ParFlow_MB3km_SLPY_x1592y1544.pfb"

#---------------------------------------------------------
# Manning's coefficient
#---------------------------------------------------------
pfset Mannings.Type			 "Constant"
pfset Mannings.GeomNames		 "domain"
pfset Mannings.Geom.domain.Value	 5.5e-5

#-----------------------------------------------------------------------------
# Phase sources:
#-----------------------------------------------------------------------------
pfset PhaseSources.water.Type			 Constant
pfset PhaseSources.water.GeomNames		 domain
pfset PhaseSources.water.Geom.domain.Value	 0.0

#-----------------------------------------------------------------------------
# Exact solution specification for error calculations
#-----------------------------------------------------------------------------
pfset KnownSolution				 NoKnownSolution


#----------------------------------------------------------------
# CLM Settings:
#------------------------------------------------------------
pfset Solver.LSM                                      CLM
pfset Solver.CLM.CLMFileDir                           "clm_output/"
pfset Solver.CLM.Print1dOut                           False
pfset Solver.BinaryOutDir                             False
pfset Solver.CLM.CLMDumpInterval                      1
pfset Solver.CLM.DailyRST                             True

pfset Solver.CLM.MetForcing                           NC
pfset Solver.CLM.MetFileName                          /p/home/jusers/naz1/jureca/SCRATCH_jibg3103/parflow_3km/runs_2007_2017/parFlow_EoCoE/ParFlow_ProductionRuns/eucordex_2007/000001/000001_setup_submit_run/work/output_27/clm_forcing_year2007_27/clm_forcing_year2007_27.nc
pfset Solver.CLM.MetFileNT                            168
pfset Solver.CLM.IstepStart                           0

pfset Solver.CLM.EvapBeta                             Linear
pfset Solver.CLM.ResSat                               0.5
pfset Solver.CLM.VegWaterStress                       Pressure
pfset Solver.CLM.WiltingPoint                         -150.0
pfset Solver.CLM.FieldCapacity                        0.0
pfset Solver.CLM.IrrigationType                       none

#----------------------------------------------------------------------------
# Set solver parameters
#-----------------------------------------------------------------------------
pfset Solver					 Richards
pfset Solver.MaxIter				 25000000

pfset Solver.TerrainFollowingGrid                True

pfset Solver.Nonlinear.MaxIter			 400
pfset Solver.Nonlinear.ResidualTol		 1.0e-4
pfset Solver.Nonlinear.EtaChoice		 EtaConstant
pfset Solver.Nonlinear.EtaValue			 0.001
pfset Solver.Nonlinear.UseJacobian		 True
pfset Solver.Nonlinear.DerivativeEpsilon	 1e-8
pfset Solver.Nonlinear.StepTol			 1e-20
pfset Solver.Nonlinear.Globalization		 LineSearch
pfset Solver.Linear.KrylovDimension		 20
pfset Solver.Linear.MaxRestart			 8
pfset Solver.MaxConvergenceFailures              8

pfset Solver.Linear.Preconditioner               PFMGOctree

pfset Solver.WriteCLMBinary False
pfset Solver.PrintCLM True
pfset Solver.PrintLSMSink True



pfset Solver.WriteSiloSubsurfData False
pfset Solver.WriteSiloMask False
pfset Solver.WriteSiloPressure False
pfset Solver.WriteSiloSaturation False
pfset Solver.WriteSiloConcentration False
pfset Solver.WriteSiloSlopes False
pfset Solver.WriteSiloEvapTrans False

pfset Solver.PrintSubsurf True
pfset Solver.PrintMask  True
pfset Solver.PrintPressure True
pfset Solver.PrintSaturation True
pfset Solver.PrintSpecificStorage True
#pfset Solver.PrintVelocities True



#pfset Solver.WriteSiloMannings True
#---------------------------------------------------------
# Initial conditions: water pressure
# HydroStaticPatch > PFBFile
#---------------------------------------------------------

#pfset ICPressure.Type                    PFBFile
#pfset ICPressure.GeomNames               domain
#pfset Geom.domain.ICPressure.FileName    "pfl_ic.pfb"
#pfset Geom.domain.ICPressure.RefGeom     domain
#pfset Geom.domain.ICPressure.RefPatch    top

pfset ICPressure.Type                                   HydroStaticPatch
pfset ICPressure.GeomNames                              domain
pfset Geom.domain.ICPressure.Value                      -0.05

pfset Geom.domain.ICPressure.RefGeom                    domain
pfset Geom.domain.ICPressure.RefPatch                   top
#-----------------------------------------------------------------------------
# Run and Unload the ParFlow output files
#-----------------------------------------------------------------------------
pfwritedb $runname
