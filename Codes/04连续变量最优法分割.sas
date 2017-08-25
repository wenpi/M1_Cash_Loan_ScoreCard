/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:47:33
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF”的代码 */
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

/*   节点开始: 04连续变量最优法分割   */
%LET _CLIENTTASKLABEL='04连续变量最优法分割';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 4连续变量最优法分割                                                    ***;                                                                                                                                 
******************************************************************************; 
/*调用宏程序*/
%let DSin   = lf.a0203_train;
%let DVVar  = target;
%let Method = 4;
%let MMax   = 5;
%let Acc    = 0.05;

%let IVVar=person_app_age; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=cs_times; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=csfq; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=contact; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=lost; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=ptp; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=his_ptp; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=incm_times; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=kptp; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=bptp; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=avg_days; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=delay_days; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=delay_days_rate; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=max_condue10; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=con10_due_times; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=seq_duedays; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=max_roll_seq; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=value_balance_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=due_cstime_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=due_contact_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=due_ptp_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=avg_rollseq; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=roll_time; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=roll_seq; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=his_delaydays; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=pay_delay_num; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=pay_delay_fee; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=apr_credit_amt; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=credit_amount; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=delay_times; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=max_cpd; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=max_overdue; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=ptp_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=bptp_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=finish_periods_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);
%let IVVar=dk_ratio; %let DSVarMap=lf.a0401_&IVVar._map; %BinContVar(&DSin,&IVVar,&DVVar,&Method,&MMax,&Acc,&DSVarMap);

/*查看连续变量分组结果*/
data var_list_cont;
  input Var_Name $32.;
  cards;
person_app_age
cs_times
csfq
contact
lost
ptp
his_ptp
incm_times
kptp
bptp
avg_days
delay_days
delay_days_rate
max_condue10
con10_due_times
seq_duedays
max_roll_seq
value_balance_ratio
due_cstime_ratio
due_contact_ratio
due_ptp_ratio
avg_rollseq
roll_time
roll_seq
his_delaydays
pay_delay_num
pay_delay_fee
apr_credit_amt
credit_amount
delay_times
max_cpd
max_overdue
ptp_ratio
bptp_ratio
finish_periods_ratio
dk_ratio

  ;
run;

data _null_;                                          
  set var_list_cont;                                          
  call symput('varn'||left(put(_n_,4.)),compress(_n_));                                                   
  call symput('name'||left(put(_n_,4.)),trim(Var_Name));                                                           
run;  
%put &=varn1 &=name1; 
%put &=varn2 &=name2; 

proc sql; 
select count(Var_Name) into: varnum_count from var_list_cont; 
quit;   

%macro var_num_group;
proc sql;  
create table lf.a0402_var_num_group
(
  Var_Name  CHAR(32),
  LL        DECIMAL(8,4),
  UL        DECIMAL(8,4),
  BinTotal  INTEGER,
  Bin       INTEGER
);

%do i= 1 %to &varnum_count.;
insert into lf.a0402_var_num_group
select distinct "&&name&i." as VAR_NAME, *
from  lf.a0401_&&name&i.._map
;
%end;
quit;

%mend;
%var_num_group;


/*连续变量映射上下界修改:使上下界连续*/
%macro Bound_Replace(BinDS);
proc sql;
select max(bin) into: Bmax from &BinDS;
quit;

%do i=1 %to &Bmax;
  %local temp_ll&i temp_ul&i;
%end;

data _null_;
  set &BinDS;
  call symput ("temp_ll"||left(_N_),LL);
  call symput ("temp_ul"||left(_N_),UL);
run;
%put &=Bmax &=temp_ll1 &=temp_ul2;

data &BinDS._b;
  set &BinDS;
run;

data &BinDS;
  set &BinDS;
  n=_N_;
  %do i=1 %to (&Bmax-1);
    if n=(&i.+1) then LL = &&temp_ul&i;
  %end;
  drop n;
run;
%mend;


%let var_name_map = csfq; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = con10_due_times; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = max_roll_seq; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = value_balance_ratio; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = avg_rollseq; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = roll_time; %Bound_Replace(lf.a0401_&var_name_map._map);
%let var_name_map = roll_seq; %Bound_Replace(lf.a0401_&var_name_map._map);







GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
