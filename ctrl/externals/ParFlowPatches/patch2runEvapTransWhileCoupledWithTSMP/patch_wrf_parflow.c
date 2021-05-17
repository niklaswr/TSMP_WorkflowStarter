--- /p/scratch/cjibg35/tsmpforecast/development/tmp/TSMP/parflow3_2/pfsimulator/parflow_lib/wrf_parflow.c	2021-03-15 11:57:20.968366000 +0100
+++ ./pfsimulator/parflow_lib/wrf_parflow.c	2021-03-15 12:21:52.551033204 +0100
@@ -172,14 +172,30 @@
 
    PFModule *time_step_control_instance = PFModuleNewInstance(time_step_control, ());
 
+/*
+ * 20210212 NWR START
+ * below changes are according to get EvapTrans working
+ * while ParFlow is coupled with CLM within TSMP.
+*/
    AdvanceRichards(amps_ThreadLocal(solver),
 		   *current_time, 
 		   stop_time, 
 		   time_step_control_instance,
 		   amps_ThreadLocal(evap_trans),
+		   NULL,
 		   &pressure_out, 
 		   &porosity_out,
 		   &saturation_out);
+/*   AdvanceRichards(amps_ThreadLocal(solver),
+ *		   *current_time, 
+ *		   stop_time, 
+ *		   time_step_control_instance,
+ *		   amps_ThreadLocal(evap_trans),
+ *		   &pressure_out, 
+ *		   &porosity_out,
+ *		   &saturation_out);
+ * DNE RWN 21201202
+*/
 
    PFModuleFreeInstance(time_step_control_instance);
    PFModuleFreeModule(time_step_control);
