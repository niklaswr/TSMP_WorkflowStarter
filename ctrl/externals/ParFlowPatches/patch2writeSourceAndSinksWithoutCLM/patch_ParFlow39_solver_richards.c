diff --git a/pfsimulator/parflow_lib/solver_richards.c b/pfsimulator/parflow_lib/solver_richards.c
index e5be0597..29caa293 100644
--- a/pfsimulator/parflow_lib/solver_richards.c
+++ b/pfsimulator/parflow_lib/solver_richards.c
@@ -5236,13 +5236,16 @@ SolverRichardsNewPublicXtra(char *name)
   }
   public_xtra->print_lsm_sink = switch_value;
 
-#ifndef HAVE_CLM
-  if (public_xtra->print_lsm_sink)
-  {
-    InputError("Error: setting %s to %s but do not have CLM\n",
-               switch_name, key);
-  }
-#endif
++// NWR 2022-05-31
++// This is commented out to compile ParFlow without CLM but print source and sink terms
++// This is needed for the simulaiton with TSMP
+//#ifndef HAVE_CLM
+//  if (public_xtra->print_lsm_sink)
+//  {
+//    InputError("Error: setting %s to %s but do not have CLM\n",
+//               switch_name, key);
+//  }
+//#endif
 
 
   /* Silo file writing control */
