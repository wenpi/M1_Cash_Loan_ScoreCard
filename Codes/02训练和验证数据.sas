/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:46:17
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
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

/*   节点开始: 02训练和验证数据   */
%LET _CLIENTTASKLABEL='02训练和验证数据';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 02随机抽样                                                             ***;                                                                                                                                 
******************************************************************************; 

/*DBeaver代码
select substr(state_date,1,7) as month, count(*)
from tmp_dcc.lf_xj_base_m1_dcc
group by substr(state_date,1,7);
*/

/*Train & Validation: 1610-1612*/
/*Test: 1701-1706*/
data lf.a0201_Train_Valid lf.a0202_Test;
  set lf.a0101_mst_ds_process2;
  if state_date > '2016-12-31' then output lf.a0202_Test;
  else output lf.a0201_Train_Valid;
run;

/*验证数据集是否分对*/
proc sql;
select distinct substr(state_date,1,7) as month,count(1) as n from lf.a0201_Train_Valid group by month;
quit;
proc sql;
select distinct substr(state_date,1,7) as month,count(1) as n from lf.a0202_Test group by month;
quit;


****随机抽样******************************************************************;
/*Train*/
proc sort data=lf.a0201_Train_Valid; by target;run;

proc surveyselect data=lf.a0201_Train_Valid
     method=srs rate=0.7 out=lf.a0203_train(drop=SelectionProb SamplingWeight) seed= 12345;
	 strata target;
run;
proc sort data =lf.a0201_Train_Valid; by CONTRACT_NO STATE_DATE; run;
proc sort data =lf.a0203_train out=lf.a0204_tag(keep= CONTRACT_NO STATE_DATE); by CONTRACT_NO STATE_DATE; run;

/*Validation*/
data lf.a0205_valid;
	merge lf.a0201_Train_Valid lf.a0204_tag(in=a);
	by CONTRACT_NO STATE_DATE;
	if ^a then output;
run;


****Bad Rate Consistency Check************************************************;
proc sql;
select sum(target)/count(1) as bad_rate into : train_bad_rate from lf.a0203_train;
select sum(target)/count(1) as bad_rate into : valid_bad_rate from lf.a0205_valid;
select sum(target)/count(1) as bad_rate into : test_bad_rate  from lf.a0202_Test;
quit;
%put &=train_bad_rate &=valid_bad_rate &=test_bad_rate;
/*TRAIN_BAD_RATE=0.112443 VALID_BAD_RATE=0.112436 TEST_BAD_RATE=0.110961*/

/*发现test的数据集不大稳定,尤其5月以后*/
proc sql;
select substr(state_date,1,7) as month, sum(target)/count(1) as bad_rate
from lf.a0202_Test
group by month;
quit;

proc sql;
select sum(target)/count(1) as bad_rate from lf.a0202_Test where state_date < '2017-06-01';
quit;

/*test数据集只取1701-1705*/
/*data lf.a0202_Test_part;*/
/*  set lf.a0202_Test;*/
/*  if state_date < '2017-06-01';*/
/*run;*/

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
