--- /p/scratch/cjibg35/tsmpforecast/development/tmp/TSMP/parflow3_2/pfsimulator/parflow_lib/parflow_proto.h	2021-03-15 11:57:20.754055885 +0100
+++ ./pfsimulator/parflow_lib/parflow_proto.h	2021-02-15 11:37:22.344624664 +0100
@@ -1180,6 +1180,7 @@
 		     double stop_time,       /* Stopping time */
 		     PFModule *time_step_control, /* Use this module to control timestep if supplied */
 		     Vector *evap_trans,     /* Flux from land surface model */ 
+		     Vector *irrigation_sk,     /* Irrigation from evap_trans file*/ 
 		     Vector **pressure_out,  /* Output vars */
 		     Vector **porosity_out,
 		     Vector **saturation_out
