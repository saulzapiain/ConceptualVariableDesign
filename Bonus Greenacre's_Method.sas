options symbolgen mprint mlogic;

%macro M_Greeacres_Method;

%let target=%EM_BINARY_TARGET;
%let inputs=%EM_NOMINAL_INPUT;
%let act=;
%LET ii=1;
%do %WHILE(%SCAN(&inputs,&ii,' ') NE );
	%let input=%upcase(%scan(&inputs,&ii));

	/*-----------------------------------------------------------------------------------------------------------------------------------------
	*********************************************************************************************************************************

		CLUSTERING MULTI-LEVEL CATEGORICAL VARIABLES

	*********************************************************************************************************************************
	------------------------------------------------------------------------------------------------------------------------------------------*/

	/*------------------------------------------------------------------------------
	  --- 	Step 5: Cluster multilevel categorical variables,
			Create table with proportions of the target variable per category level
	------------------------------------------------------------------------------*/
	OPTIONS NOMLOGIC NOMPRINT NOSYMBOLGEN;
	PROC SQL THREADS BUFFERSIZE=500M;
	CREATE TABLE &em_lib..DS_TGT_PROPORTIONS
	AS
	SELECT
	&input
	,COUNT(1) AS FREQ
	,AVG(&target) AS PROP
	FROM &em_import_data
	GROUP BY
	&input
	ORDER BY
	 &input
	;
	QUIT;
	/*------------------------------------------------------------------------------
	  --- 	Step 5': Run the cluster Procedure over the Level Table
			using the Freq statement and the Ward Method in order to get
			the Greenacre's Method
	------------------------------------------------------------------------------*/
	PROC CLUSTER 	DATA=&em_lib..DS_TGT_PROPORTIONS
					METHOD=WARD
					OUTTREE=&em_lib..DS_OutTree;
		FREQ FREQ;
		VAR PROP;
		ID &input;
	ODS OUTPUT
		CLUSTERHISTORY=&em_lib..DS_ClusterHist;
	RUN;
	/*------------------------------------------------------------------------------
	  --- 	Step 6: Compute the Chi-Square Statistic to meassure the global
			association between the target vatiable and the categorical variable
	------------------------------------------------------------------------------*/
	PROC FREQ DATA=&em_import_data;
		TABLES &input*&target /CHISQ;
		OUTPUT
			OUT=&em_lib..ds_SquaredChi(KEEP=_PCHI_)
			CHISQ;
	RUN;
	/*------------------------------------------------------------------------------
	  --- 	Step 7: Compute the p-value for each cluster level
	------------------------------------------------------------------------------*/
	DATA &em_lib..ds_P_Values_PerCluster;
		IF _N_ = 1 THEN SET &em_lib..ds_SquaredChi;
		SET &em_lib..DS_ClusterHist;
		CHISQR=_PCHI_*RSQUARED;
		DF=NUMBEROFCLUSTERS-1;
		P_VALUE=LOGSDF('CHISQ',CHISQR,DF);
	RUN;
	/*------------------------------------------------------------------------------
	  --- 	Step 8: Grpah and select the cutoff value for the number of clusters
	------------------------------------------------------------------------------*/
	PROC SQL;
	SELECT
	NUMBEROFCLUSTERS INTO :NCL
	FROM &em_lib..ds_P_Values_PerCluster
	HAVING MIN(P_VALUE)=P_VALUE;
	QUIT;
	/*------------------------------------------------------------------------------
	  --- 	Step 9: Create a dendogram and the final output table
	------------------------------------------------------------------------------*/
	PROC TREE
			DATA=&em_lib..DS_OutTree
			OUT=&em_lib..DS_Final_Cluster
			H=RSQ
			VAXIS=AXIS1
			NCLUSTERS=&NCL
			;
		ID &input;
		AXIS1 LABEL=("Proportion of Chi-Squared Statistic");
	RUN;
	/*------------------------------------------------------------------------------
	  --- 	Step 10: Utiliza Hash para adicionar el nuevo campo con el valor del
			cluster del c�digo postal en la partici�n de entrenamiento
	------------------------------------------------------------------------------*/
	/*-----------------------------------------------------------------------------------------------------------------------------------------
	  --- 	*********************************************************************************************************************************
	------------------------------------------------------------------------------------------------------------------------------------------*/
	data &em_export_train (DROP=_F _RC);* (drop=_:);/* use this form of drop= if desired */

		dcl hash hh (ordered: 'a');
		dcl hiter hi ('hh');/* hash iterator object */
		hh.definekey ("&input") ; *key HH by unique composite (kn kc _n_) ;
		hh.definedata ("&input","CLUS_&input",'_f') ; *SAT as data tied to unique enumerated key ;
		hh.definedone () ; *finish instantiating HH ;

		do until (eof2);
			set
				&em_lib..DS_Final_Cluster (KEEP=
											&input
											CLUSTER
													RENAME=(
															CLUSTER=CLUS_&input
																)
													)
			end = eof2;
			_f = .;/* initialize flag _f in hash table */
			hh.add();
		end;
		* Output all rows in driver *;
		do until(eof);
			set
				&em_import_data
			end = eof;
			CALL MISSING(CLUS_&input);/* initialize group_id for each new record in Mbr_plan*/

			if hh.find() = 0 then do;
				_f = 1;
				hh.replace();/* overwrite record in hash table with new value of _f */
				output;
				_f = .;/* initialize _f back to missing to prepare for next */
			end;
			else output;
		end;/* at this point all Mbr_plan records have been read */
		do _rc = hi.first() by 0 while (_rc = 0);
			if _f ne 1 then do;
			end;
			_rc = hi.next();/* move to next row in hash table */
		end;
	stop;
	run;


	data &em_export_validate (DROP=_F _RC);* (drop=_:);/* use this form of drop= if desired */

		dcl hash hh (ordered: 'a');
		dcl hiter hi ('hh');/* hash iterator object */
		hh.definekey ("&input") ; *key HH by unique composite (kn kc _n_) ;
		hh.definedata ("&input","CLUS_&input",'_f') ; *SAT as data tied to unique enumerated key ;
		hh.definedone () ; *finish instantiating HH ;

		do until (eof2);
			set
				&em_lib..DS_Final_Cluster (KEEP=
											&input
											CLUSTER
													RENAME=(
															CLUSTER=CLUS_&input
																)
													)
			end = eof2;
			_f = .;/* initialize flag _f in hash table */
			hh.add();
		end;
		* Output all rows in driver *;
		do until(eof);
			set
				&em_import_validate
			end = eof;
			CALL MISSING(CLUS_&input);/* initialize group_id for each new record in Mbr_plan*/

			if hh.find() = 0 then do;
				_f = 1;
				hh.replace();/* overwrite record in hash table with new value of _f */
				output;
				_f = .;/* initialize _f back to missing to prepare for next */
			end;
			else output;
		end;/* at this point all Mbr_plan records have been read */
		do _rc = hi.first() by 0 while (_rc = 0);
			if _f ne 1 then do;
			end;
			_rc = hi.next();/* move to next row in hash table */
		end;
	stop;
	run;

	data &em_export_test (DROP=_F _RC);* (drop=_:);/* use this form of drop= if desired */

		dcl hash hh (ordered: 'a');
		dcl hiter hi ('hh');/* hash iterator object */
		hh.definekey ("&input") ; *key HH by unique composite (kn kc _n_) ;
		hh.definedata ("&input","CLUS_&input",'_f') ; *SAT as data tied to unique enumerated key ;
		hh.definedone () ; *finish instantiating HH ;

		do until (eof2);
			set
				&em_lib..DS_Final_Cluster (KEEP=
											&input
											CLUSTER
													RENAME=(
															CLUSTER=CLUS_&input
																)
													)
			end = eof2;
			_f = .;/* initialize flag _f in hash table */
			hh.add();
		end;
		* Output all rows in driver *;
		do until(eof);
			set
				&em_import_test
			end = eof;
			CALL MISSING(CLUS_&input);/* initialize group_id for each new record in Mbr_plan*/

			if hh.find() = 0 then do;
				_f = 1;
				hh.replace();/* overwrite record in hash table with new value of _f */
				output;
				_f = .;/* initialize _f back to missing to prepare for next */
			end;
			else output;
		end;/* at this point all Mbr_plan records have been read */
		do _rc = hi.first() by 0 while (_rc = 0);
			if _f ne 1 then do;
			end;
			_rc = hi.next();/* move to next row in hash table */
		end;
	stop;
	run;

	%LET ii=%EVAL(&ii+1);

%END;
%mend M_Greeacres_Method;


%M_Greeacres_Method;
%metadata();
%metadata(newrole=Rejected,APPEND=Y,where=(UPCASE(NAME) in ("&input.") and upcase(ROLE)='INPUT'));
%metadata(newlevel=Nominal,newrole=Input,APPEND=Y,where=(UPCASE(NAME)="CLUS_&input."));