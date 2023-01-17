--- /p/scratch/cjibg35/tsmpforecast/development/tmp/TSMP/parflow3_2/pfsimulator/parflow_lib/solver_richards.c	2021-03-15 11:57:20.815972434 +0100
+++ ./pfsimulator/parflow_lib/solver_richards.c	2021-02-15 11:37:22.108629332 +0100
@@ -307,10 +307,15 @@
    VectorUpdateCommHandle   *handle;
 
    int           any_file_dumped;
+   // NWR 20210213
+   // move this from within HAVE_CLM outside to be available for EvapTranTransien
+   char          filename[128];         
 
 #ifdef HAVE_CLM
    /* IMF: for CLM met forcings (local to SetupRichards)*/
-   char          filename[128];         
+   // NWR 20210213
+   // move filename outside HAVE_CLM see above
+   //char          filename[128];         
    int           n,nc,c;				                           /*Added c BH*/
    int           ch;
    double        sw,lw,prcp,tas,u,v,patm,qatm,lai,sai,z0m,displa;  // forcing vars added vegetation BH
@@ -1090,6 +1095,7 @@
 		     double stop_time,       /* Stopping time */
 		     PFModule *time_step_control, /* Use this module to control timestep if supplied */
 		     Vector *evap_trans,     /* Flux from land surface model */ 
+		     Vector *irrigation_sk,     /* Irrigation from evap_trans file*/ 
 		     Vector **pressure_out,  /* Output vars */
 		     Vector **porosity_out,
 		     Vector **saturation_out
@@ -1119,6 +1125,9 @@
    Vector       *porosity            = ProblemDataPorosity(problem_data);
    Vector       *evap_trans_sum      = instance_xtra -> evap_trans_sum;
    Vector       *overland_sum        = instance_xtra -> overland_sum;     /* sk: Vector of outflow at the boundary*/
+   // NWR 20210213
+   // move to outside HAVE_CLM to test EvapTrans without CLM 
+   char          filename[2048];                     // IMF: 1D input file name *or* 2D/3D input file base name
 
 #ifdef HAVE_OAS3
    Grid         *grid                = (instance_xtra -> grid);
@@ -1164,7 +1173,9 @@
    double	*z0m_data = NULL;				                      /*BH*/
    double	*displa_data = NULL;				                  /*BH*/
    double	*veg_map_data = NULL;				                  /*BH*/ /*will fail if veg_map_data is declared as int*/   
-   char          filename[2048];                                   // IMF: 1D input file name *or* 2D/3D input file base name
+   // NWR 20210213
+   // move to outside HAVE_CLM to test EvapTrans without CLM
+   //char          filename[2048];                                   // IMF: 1D input file name *or* 2D/3D input file base name
    Subvector    *sw_forc_sub, *lw_forc_sub, *prcp_forc_sub, *tas_forc_sub, 
                 *u_forc_sub, *v_forc_sub, *patm_forc_sub, *qatm_forc_sub, 
 				*lai_forc_sub, *sai_forc_sub, *z0m_forc_sub, *displa_forc_sub,
@@ -1827,13 +1838,22 @@
         
 
 
-//#endif   //End of call to CLM
+// NWR 20210212
+// comment this in tring to use EvapTrans without CLM compiled	    
+#endif   //End of call to CLM
 
           /******************************************/
           /*    read transient evap trans flux file */
           /******************************************/
           if (public_xtra -> evap_trans_file_transient) {
-              sprintf(filename, "%s.%05d.pfb", public_xtra -> evap_trans_filename, (istep-1) );
+	      // NWR 20210213
+	      // use file_number instead of istep as long as running without CLM
+              sprintf(filename, "%s.%05d.pfb", public_xtra -> evap_trans_filename, instance_xtra -> file_number );
+              //sprintf(filename, "%s.%05d.pfb", public_xtra -> evap_trans_filename, (istep-1) );
+	      // NWR 20210212
+	      // TEST WHAT IS INSIDE filename
+	      // EvapTrans is not read...
+              printf("ANDTHEFILENAMEIS: %s %s \n",filename, public_xtra -> evap_trans_filename);
               //printf("%s %s \n",filename, public_xtra -> evap_trans_filename);
               
               /* Added flag to give the option to loop back over the flux files 
@@ -1855,15 +1875,24 @@
               }
               } // NBE
               
-              ReadPFBinary( filename, evap_trans );
+              ReadPFBinary( filename, irrigation_sk );
+	      // NRW 20210212
+	      // Test EvapTransFile
+	      printf("VECTORMAXMIN: %e %e \n",PFVMax(irrigation_sk),PFVMin(irrigation_sk));
               
               //printf("Checking time step logging, steps = %i\n",Stepcount);
               
-              handle = InitVectorUpdate(evap_trans, VectorUpdateAll);
+              handle = InitVectorUpdate(irrigation_sk, VectorUpdateAll);
               FinalizeVectorUpdate(handle);
           }
+	  
+	  PFVSum(evap_trans,irrigation_sk,evap_trans);
+
+// NWR 20210212
+// add this in tring to use EvapTrans without CLM compiled	    
+// /* IMF: The following are only used w/ CLM */
+#ifdef HAVE_CLM
          
-          
           /* NBE counter for reusing CLM input files */
           clm_next += 1;
           if (clm_next > clm_skip)
@@ -1885,8 +1914,10 @@
 	  It is using the different time step counter BUT then it
 	  isn't scaling the inputs properly.
 	  ============================================================= */
-	    
-#endif          
+// NWR 20210212
+// tring to use EvapTrans without CLM compiled	    
+#endif    //End of call to CLM
+        
       } //Endif to check whether an entire dt is complete
 
       converged = 1;
@@ -4665,19 +4699,22 @@
     * sk: Vector that contains the sink terms from the land surface model 
     */ 
    Vector       *evap_trans;
+   Vector       *irrigation_sk;
    
    SetupRichards(this_module);
 
    /*sk Initialize LSM terms*/
    evap_trans = NewVectorType( grid, 1, 1, vector_cell_centered );
     InitVectorAll(evap_trans, 0.0);
+   irrigation_sk = NewVectorType( grid, 1, 1, vector_cell_centered );
+    InitVectorAll(irrigation_sk, 0.0);
     
     if (public_xtra -> evap_trans_file) {
         sprintf(filename, "%s", public_xtra -> evap_trans_filename );
         //printf("%s %s \n",filename, public_xtra -> evap_trans_filename);
-        ReadPFBinary( filename, evap_trans );
+        ReadPFBinary( filename, irrigation_sk );
         
-        handle = InitVectorUpdate(evap_trans, VectorUpdateAll);
+        handle = InitVectorUpdate(irrigation_sk, VectorUpdateAll);
         FinalizeVectorUpdate(handle);
     }
     
@@ -4686,6 +4723,7 @@
 		   stop_time, 
 		   NULL,
 		   evap_trans,
+		   irrigation_sk,
 		   &pressure_out, 
                    &porosity_out,
                    &saturation_out);
@@ -4698,6 +4736,7 @@
    TeardownRichards(this_module);
 
    FreeVector(evap_trans );
+   FreeVector(irrigation_sk );
 }
 
  /* 
