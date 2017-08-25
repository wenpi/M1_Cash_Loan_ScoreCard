/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:53:16
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */

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

/*   节点开始: 12变量稳定性PSI   */
%LET _CLIENTTASKLABEL='12变量稳定性PSI';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 10变量稳定性计算                                                       ***;                                                                                                                                 
******************************************************************************; 

****SSI Calculation**********************************************************;
/*Test分月数据*/
/*生成即可,不需重复运行
data lf_xy.a1001_test_1701 lf_xy.a1001_test_1702 lf_xy.a1001_test_1703 lf_xy.a1001_test_1704 lf_xy.a1001_test_1705 lf_xy.a1001_test_1706;
  set lf_xy.test_pred_probs;
  if substr(state_date,1,7) = '2017-01' then output lf_xy.a1001_test_1701;
  if substr(state_date,1,7) = '2017-02' then output lf_xy.a1001_test_1702;
  if substr(state_date,1,7) = '2017-03' then output lf_xy.a1001_test_1703;
  if substr(state_date,1,7) = '2017-04' then output lf_xy.a1001_test_1704;
  if substr(state_date,1,7) = '2017-05' then output lf_xy.a1001_test_1705;
  if substr(state_date,1,7) = '2017-06' then output lf_xy.a1001_test_1706;
run;*/

/*变量表*/
proc transpose data= lf_xy.train_model_params out=lf_xy.para_in;
run;

data lf_xy.a1002_vardic;
  set lf_xy.para_in(keep= _NAME_);
  if _NAME_ not in ('Intercept','_LNLIKE_');
  format variable $32.;
  variable = tranwrd(_NAME_,'_woe','_b');
  drop _NAME_;
run;

data lf_xy.a1001_train_probs;
  set lf_xy.train_pred_probs;
run;

*%include "&folder./xy/M1_Cash_ScoreCard_v1/00_Macro_PSI_SSI_Calculation.sas";

/*SSI计算*/
%let train_data = lf_xy.a1001_train_probs;
%let model_coef = lf_xy.a1002_vardic;

%let test_data = lf_xy.test_1611_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

%let test_data = lf_xy.test_1612_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

%let test_data = lf_xy.test_1701_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

%let test_data = lf_xy.test_1702_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

%let test_data = lf_xy.test_1705_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

%let test_data = lf_xy.test_1706_pred_probs;
%totalssi(&train_data.,&test_data.,&model_coef.);

proc delete data= para_in lf_xy.a1001_train_probs; run;



****PSI Calculation**********************************************************;
/*等最后确定模型再做*/
/*入模变量表
proc transpose data= lf_xy.TRAIN_MODEL_PARAMS out=para_in;
run;

data lf_xy.vardic;
  set lf_xy.para_in(keep= _NAME_);
  if _NAME_ not in ('Intercept','_LNLIKE_');
  format variable $32.;
  variable = tranwrd(_NAME_,'_woe','_b');
  drop _NAME_;
run;
*/
/*validation数据集分月
data lf_xy.valid_1610 lf_xy.valid_1611 lf_xy.valid_1612;
  set lf_xy.valid_pred_probs(rename=(p_1=pred_target));
  state_month = put(datepart(state_date),yymmn6.);
  if state_month = '201610' then output lf_xy.valid_1610;
  if state_month = '201611' then output lf_xy.valid_1611;
  if state_month = '201612' then output lf_xy.valid_1612;
run;*/

*%totalpsi(lf_xy.train_pred_probs,lf_xy.valid_1610,lf_xy.vardic,pred_target,10);



GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
