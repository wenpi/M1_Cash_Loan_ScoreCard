/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:49:35
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

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

/*   节点开始: 06变量woe计算与映射   */
%LET _CLIENTTASKLABEL='06变量woe计算与映射';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 06变量woe计算与映射                                                    ***;                                                                                                                                 
******************************************************************************;   

****WOE Calculation on Train*************************************************;

data lf_xy.a0601_train_woe; set lf_xy.a0501_train_group; run;

/*调用宏程序*/
%let dvvar=target;
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=person_sex; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=family_state; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=education; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=is_ssi; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=childrentotal; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=other_person_type; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=city; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=is_insure; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=person_app_age; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=cs_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=csfq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=contact; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=lost; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=his_ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=incm_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=kptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=bptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=avg_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=delay_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=delay_days_rate; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=max_condue10; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=con10_due_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=seq_duedays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=max_roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=value_balance_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=due_cstime_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=due_contact_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=due_ptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=avg_rollseq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=roll_time; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=his_delaydays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=pay_delay_num; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=pay_delay_fee; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=apr_credit_amt; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=credit_amount; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=delay_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=max_cpd; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=max_overdue; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=ptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=bptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe     ; %let DSout=lf_xy.a0601_train_woe_temp; %let var=finish_periods_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a0601_train_woe_temp; %let DSout=lf_xy.a0601_train_woe     ; %let var=dk_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);

/*data lf_xy.a0601_train_woe;*/
/*  set lf_xy.a0601_train_woe_temp;*/
/*run;*/


/*WOE结果汇总*/
proc sql;
create table varlist as
select a.varnum, a.name, a.type, a.length, a.label, a.format, a.npos, b.nobs
from dictionary.columns as a , dictionary.tables as b
where a.libname=%upcase("lf_xy") and 
      b.libname=%upcase("lf_xy") and                                                                                                        
      a.memname=%upcase("a0601_train_woe") and  
      b.memname=%upcase("a0601_train_woe") and 
      substr(a.name,length(a.name)-3,4)="_woe" order by varnum;                                                                                   
quit;                                                                                                                                                                            

data _null_;                                          
  set varlist;                                          
  call symput('varn'||left(put(_n_,4.)),compress(varnum));                                                   
  call symput('name'||left(put(_n_,4.)),substr(trim(name),1,length(trim(name))-4));                                                           
run;  
%put &=varn1 &=name1; 
%put &=varn2 &=name2; 

proc sql; 
select count(varnum) into: varnum_count from varlist; 
quit;   

%macro woe_summary;
proc sql;  
create table lf_xy.a0602_woe_summary
(
  VAR_NAME  CHAR(32),
  bin       INTEGER,
  WOE       num
);

%do i= 1 %to &varnum_count.;
insert into lf_xy.a0602_woe_summary
select distinct "&&name&i." as VAR_NAME
       ,&&name&i.._b as bin
       ,WOE
from  lf_xy.a0601_&&name&i.._woe;
%end;
quit;
%mend;
%woe_summary;


****WOE Application on Validation & Test*************************************;
/*Validation*/
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=person_sex; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=family_state; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=education; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=other_person_type; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=city; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=person_app_age; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=cs_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=contact; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=his_ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=bptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=avg_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=delay_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=delay_days_rate; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=max_condue10; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=con10_due_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=seq_duedays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=max_roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=avg_rollseq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=roll_time; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=his_delaydays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=pay_delay_num; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=pay_delay_fee; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=max_cpd; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=ptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=bptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe_temp; %let DSout=lf_xy.a602_valid_woe     ; %let var=finish_periods_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a602_valid_woe     ; %let DSout=lf_xy.a602_valid_woe_temp; %let var=dk_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);


/*Test*/
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=person_sex; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=family_state; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=education; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=other_person_type; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=city; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=person_app_age; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=cs_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=contact; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=his_ptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=bptp; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=avg_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=delay_days; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=delay_days_rate; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=max_condue10; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=con10_due_times; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=seq_duedays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=max_roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=avg_rollseq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=roll_time; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=roll_seq; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=his_delaydays; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=pay_delay_num; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=pay_delay_fee; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=max_cpd; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=ptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=bptp_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe_temp; %let DSout=lf_xy.a603_test_woe     ; %let var=finish_periods_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);
%let DSin=lf_xy.a603_test_woe     ; %let DSout=lf_xy.a603_test_woe_temp; %let var=dk_ratio; %let ivvar=&var._b; %let woeds=lf_xy.a0601_&var._woe; %let WOEVar=&var._woe; %CalcWOE2(&DsIn,&IVVar,&DVVar,&WOEDS,&WOEVar,&DSout);


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
