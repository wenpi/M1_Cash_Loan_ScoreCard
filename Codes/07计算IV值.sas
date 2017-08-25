/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:49:40
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

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

/*   节点开始: 07计算IV值   */
%LET _CLIENTTASKLABEL='07计算IV值';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 07计算IV值                                                             ***;                                                                                                                                 
******************************************************************************; 

%macro PowerIV(DSin, DV, IVList, DSout);
/* Decompose the input IVList into tokens and store variable
   names into macro variables */

%local i N condition VarX; 
%let i=1;
%let N=0;
%let condition = 0; 
%do %until (&condition =1);
   %let VarX=%scan(&IVList,&i);
   %if "&VarX" =""  %then %let condition =1;
  	        %else %do;
				%local Var&i;
                %let Var&i =&VarX; 
                %let N=&i;
                %let i=%eval(&i+1); 
                  %end;  
%end;

/* now we have a total of N variables
   Loop on their  names and calculate the Information value
   between the DV and each of the variables */

proc sql noprint;
 create table &DSout (VariableName char(200), 
                      InformationValue  num);
quit;

%do i=1 %to &N;
   %local IV&i;
   %let IV&i=;
	%InfValue(&DSin, &&Var&i, &DV, IV&i);
	proc sql noprint; 
     insert into &DSout  values("&&Var&i",&&IV&i);
    quit; 	 
%end;


proc sort data=&dsout;
 by descending InformationValue; 
 run;

%mend; 


%macro InfValue(DSin, XVar, YVarBin, M_IV);

/* Extract the frequency table using proc freq, 
   and the categories of the X variable */

proc freq data=&DSin noprint;
 table &XVar*&YvarBin /out=Temp_freqs;
 table &XVar /out=Temp_Xcats;
 run;

proc sql noprint;
  /* Count the number of obs and categories of X */
   %local R C; /* rows and columns of freq table */
   select count(*) into : R from temp_Xcats;
   select count(*) into : N from &DSin; 
quit;

  /* extract the categories of X into CatX_i */
data _Null_;
  set temp_XCats;
   call symput("CatX_"||compress(_N_), &Xvar);
run;

proc sql noprint; 
	/* extract n_i_j*/
 %local i j;
   %do i=1 %to &R; 
    %do j=1 %to 2;/* we know that YVar is 1/0 - numeric */
      %local N_&i._&j;
   Select Count into :N_&i._&j from temp_freqs where &Xvar ="&&CatX_&i" and &YVarBin = %eval(&j-1);
    %end;
   %end;
quit;
  
  /* calculate N*1,N*2 */
     %local N_1s N_2s;
      %let N_1s=0;
	  %let N_2s=0;
  %do i=1 %to &r; 
	  %let N_1s=%sysevalf(&N_1s + &&N_&i._1);
	  %let N_2s=%sysevalf(&N_2s + &&N_&i._2);
   %end;

/* substitute in the equation for IV */
     %local IV;
     %let IV=0;
       %do i=1 %to &r;
          %let IV = %sysevalf(&IV + (&&N_&i._1/&N_1s - &&N_&i._2/&N_2s)*%sysfunc(log(%sysevalf(&&N_&i._1*&N_2s/(&&N_&i._2*&N_1s)))) );
       %end;

%let &M_IV=&IV; 

/* clean the workspace */
proc datasets library=work;
delete temp_freqs temp_Xcats;
quit;
%mend;


/*将数值型分组转化为字符型*/
data lf_xy.a0701_train_bin_ch;
set lf_xy.a0601_train_woe;
lost_b_ch = put(lost_b, 8.);
csfq_b_ch = put(csfq_b, 8.);
incm_times_b_ch =put(incm_times_b, 8.);
due_cstime_ratio_b_ch = put(due_cstime_ratio_b, 8.);
due_contact_ratio_b_ch = put(due_contact_ratio_b, 8.);
due_ptp_ratio_b_ch =put(due_ptp_ratio_b, 8.);

kptp_b_ch = put(kptp_b, 8.);
max_overdue_b_ch =put(max_overdue_b, 8.);
delay_times_b_ch = put(delay_times_b, 8.);
value_balance_ratio_b_ch = put(value_balance_ratio_b, 8.);
credit_amount_b_ch = put(credit_amount_b, 8.);
apr_credit_amt_b_ch =put(apr_credit_amt_b, 8.);

childrentotal_b_ch =put(childrentotal_b, 8.);
is_ssi_b_ch =put(is_ssi_b, 8.);
is_insure_b_ch = put(is_insure_b, 8.);

person_sex_b_ch = put(person_sex_b, 8.);
family_state_b_ch = put(family_state_b, 8.);
education_b_ch = put(education_b, 8.);
other_person_type_b_ch = put(other_person_type_b, 8.);
city_b_ch = put(city_b, 8.);
person_app_age_b_ch = put(person_app_age_b, 8.);
cs_times_b_ch = put(cs_times_b, 8.);
contact_b_ch = put(contact_b, 8.);
ptp_b_ch = put(ptp_b, 8.);
his_ptp_b_ch = put(his_ptp_b, 8.);
bptp_b_ch = put(bptp_b, 8.);
avg_days_b_ch = put(avg_days_b, 8.);
delay_days_b_ch = put(delay_days_b, 8.);
delay_days_rate_b_ch = put(delay_days_rate_b, 8.);
max_condue10_b_ch = put(max_condue10_b, 8.);
con10_due_times_b_ch = put(con10_due_times_b, 8.);
seq_duedays_b_ch = put(seq_duedays_b, 8.);
max_roll_seq_b_ch = put(max_roll_seq_b, 8.);
avg_rollseq_b_ch = put(avg_rollseq_b, 8.);
roll_time_b_ch = put(roll_time_b, 8.);
roll_seq_b_ch = put(roll_seq_b, 8.);
his_delaydays_b_ch = put(his_delaydays_b, 8.);
pay_delay_num_b_ch = put(pay_delay_num_b, 8.);
pay_delay_fee_b_ch = put(pay_delay_fee_b, 8.);
max_cpd_b_ch = put(max_cpd_b, 8.);
ptp_ratio_b_ch = put(ptp_ratio_b, 8.);
bptp_ratio_b_ch = put(bptp_ratio_b, 8.);
finish_periods_ratio_b_ch = put(finish_periods_ratio_b, 8.);
dk_ratio_b_ch = put(dk_ratio_b, 8.);
run;

%let DSin=lf_xy.a0701_train_bin_ch;
%let DV=target;
%let IVList=
lost_b_ch 
csfq_b_ch 
incm_times_b_ch 
due_cstime_ratio_b_ch 
due_contact_ratio_b_ch
due_ptp_ratio_b_ch
kptp_b_ch 
max_overdue_b_ch
delay_times_b_ch 
value_balance_ratio_b_ch
credit_amount_b_ch
apr_credit_amt_b_ch 
childrentotal_b_ch 
is_ssi_b_ch 
is_insure_b_ch

person_sex_b_ch
family_state_b_ch
education_b_ch
other_person_type_b_ch
city_b_ch
person_app_age_b_ch
cs_times_b_ch
contact_b_ch
ptp_b_ch
his_ptp_b_ch
bptp_b_ch
avg_days_b_ch
delay_days_b_ch
delay_days_rate_b_ch
max_condue10_b_ch
con10_due_times_b_ch
seq_duedays_b_ch
max_roll_seq_b_ch
avg_rollseq_b_ch
roll_time_b_ch
roll_seq_b_ch
his_delaydays_b_ch
pay_delay_num_b_ch
pay_delay_fee_b_ch
max_cpd_b_ch
ptp_ratio_b_ch
bptp_ratio_b_ch
finish_periods_ratio_b_ch
dk_ratio_b_ch
;
%let DSOut=lf_xy.a0702_Cal_IV;
%PowerIV(&DSin, &DV, &IVList, &DSout);




GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
