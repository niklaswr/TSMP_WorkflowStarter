--- /p/scratch/cjibg35/tsmpforecast/development/tmp/TSMP/parflow3_2/pfsimulator/parflow_lib/solver_richards.c	2021-03-15 11:57:20.815972434 +0100
+++ ./pfsimulator/parflow_lib/solver_richards.c	2021-02-15 11:50:16.885313206 +0100
@@ -4169,12 +4169,15 @@
    }
    public_xtra -> print_lsm_sink = switch_value;
 
-#ifndef HAVE_CLM
-   if(public_xtra -> print_lsm_sink) 
-   {
-      InputError("Error: setting %s to %s but do not have CLM\n", switch_name, key);
-   }
-#endif
+// NWR 2020-11-09
+// This is commented out to compile ParFlow without CLM but print source and sink terms
+// This is needed for the simulaiton with TSMP
+//#ifndef HAVE_CLM
+//   if(public_xtra -> print_lsm_sink) 
+//   {
+//      InputError("Error: setting %s to %s but do not have CLM\n", switch_name, key);
+//   }
+//#endif
 
 
    /* Silo file writing control */
