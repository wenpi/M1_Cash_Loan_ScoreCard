/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:49:12
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HtmlBlue
    STYLESHEET=(URL="file:///D:/SASHome/SASEnterpriseGuide/7.1/Styles/HtmlBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   节点开始: 05分组映射   */
%LET _CLIENTTASKLABEL='05分组映射';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 05分组映射                                                             ***;                                                                                                                                 
******************************************************************************; 

****Train********************************************************************;
/*名义变量分组映射*/
data lf_xy.a0501_train_group; set lf_zdy.a0203_train; run;

%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=person_sex; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=family_state; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=education; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=is_ssi; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=childrentotal; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=other_person_type; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=city; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=is_insure; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);

/*data lf_xy.a0501_train_group;*/
/*  set lf_xy.a0501_train_group_temp;*/
/*run;*/

/*连续变量分组映射*/
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=person_app_age; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=cs_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=csfq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=contact; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=lost; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=his_ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=incm_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=kptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=bptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=avg_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=delay_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=delay_days_rate; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=max_condue10; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=con10_due_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=seq_duedays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=max_roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=value_balance_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=due_cstime_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=due_contact_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=due_ptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=avg_rollseq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=roll_time; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=his_delaydays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=pay_delay_num; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=pay_delay_fee; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=apr_credit_amt; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=credit_amount; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=delay_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=max_cpd; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=max_overdue; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=ptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=bptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group     ; %let DSout=lf_xy.a0501_train_group_temp; %let VarX=finish_periods_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0501_train_group_temp; %let DSout=lf_xy.a0501_train_group     ; %let VarX=dk_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);

/*Dounble check if all the vars generate _b*/
proc sql;
select a.varnum, a.name, a.type, a.length, a.label, a.format, a.npos, b.nobs                                                                                                     
from dictionary.columns as a , dictionary.tables as b                                                                                                                            
where a.libname=%upcase("lf_xy") and 
      b.libname=%upcase("lf_xy") and                                                                                                        
      a.memname=%upcase("a0501_train_group") and  
      b.memname=%upcase("a0501_train_group") and 
      substr(a.name,length(a.name)-1,2)="_b" order by varnum;                                                                                   
quit; 



****Validation***************************************************************;
/*名义变量分组映射*/
data lf_xy.a0502_valid_group; set lf_zdy.a0205_valid; run;

%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=person_sex; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=family_state; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=education; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=other_person_type; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=city; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);

data lf_xy.a0502_valid_group;
  set lf_xy.a0502_valid_group_temp;
run;

/*连续变量分组映射*/
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=person_app_age; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=cs_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=contact; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=his_ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=bptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=avg_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=delay_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=delay_days_rate; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=max_condue10; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=con10_due_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=seq_duedays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=max_roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=avg_rollseq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=roll_time; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=his_delaydays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=pay_delay_num; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=pay_delay_fee; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=max_cpd; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=ptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=bptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group     ; %let DSout=lf_xy.a0502_valid_group_temp; %let VarX=finish_periods_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0502_valid_group_temp; %let DSout=lf_xy.a0502_valid_group     ; %let VarX=dk_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);





****Test*********************************************************************;
/*名义变量分组映射*/
data lf_xy.a0503_test_group; set lf_xy.a0202_Test; run;

%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=person_sex; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=family_state; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=education; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=other_person_type; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=city; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0301_&VarX._map; %ApplyMap1(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);

data lf_xy.a0503_test_group;
  set lf_xy.a0503_test_group_temp;
run;

/*连续变量分组映射*/
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=person_app_age; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=cs_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=contact; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=his_ptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=bptp; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=avg_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=delay_days; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=delay_days_rate; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=max_condue10; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=con10_due_times; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=seq_duedays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=max_roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=avg_rollseq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=roll_time; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=roll_seq; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=his_delaydays; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=pay_delay_num; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=pay_delay_fee; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=max_cpd; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=ptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=bptp_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group     ; %let DSout=lf_xy.a0503_test_group_temp; %let VarX=finish_periods_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);
%let DSin=lf_xy.a0503_test_group_temp; %let DSout=lf_xy.a0503_test_group     ; %let VarX=dk_ratio; %let NewVarX=&VarX._b; %let DSVarMap=lf_xy.a0401_&VarX._map; %ApplyMap2(&DSin,&VarX,&NewVarX,&DSVarMap,&DSout);



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
