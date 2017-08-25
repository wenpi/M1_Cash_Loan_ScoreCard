/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:46:11
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

/*   节点开始: 01导入数据&数据预处理   */
%LET _CLIENTTASKLABEL='01导入数据&数据预处理';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;
******************************************************************************;                                                                                                                                
*** 01导入数据&数据预处理                                                  ***;                                                                                                                                 
******************************************************************************; 

****导入数据******************************************************************;
proc sql;                                                                                                                               
create table f15.lf_xj_base_m1_dcc_cn_4 as                                                                                                              
select *
from tmp_dcc.tm1m3_lf_xj_base_m1_dcc
       (dbsastype=(
contract_no          ='char(30)'
putout_date          ='char(10)' 
state_date           ='char(10)'     
customerid           ='char(20)'     
acct_loan_no         ='char(30)'
person_sex           ='char(2)' 
family_state         ='char(20)'     
education            ='char(20)' 
other_person_type    ='char(20)'     
city                 ='char(60)'
is_ssi               ='char(2)'
is_insure            ='char(2)'
childrentotal        ='char(8)'  
        ));
quit; 


data f15.lf_xj_base_m1_dcc_cn_4;
set f15.lf_xj_base_m1_dcc_cn_4;
label DELAY_DAYS_RATE      ='历史延滞天数/账龄天数     '; 
label BPTP_RATIO           ='BPTP比率                  ';
label PAY_DELAY_NUM        ='累积还滞纳金次数          ';
label MAX_CONDUE10         ='历史最大连续逾期10天的期数';
label DK_RATIO             ='代扣失败比率              ';
label CS_TIMES             ='历史总催收次数            ';
label CONTACT              ='历史可联次数              ';
label PAY_DELAY_FEE        ='累积还滞纳金金额          ';
label DELAY_DAYS           ='处于逾期状态的天数        ';
label HIS_DELAYDAYS        ='所有期次的逾期停留天数之和';
label MAX_ROLL_SEQ         ='最大回退期数              ';
label CON10_DUE_TIMES      ='历史连续逾期10天的次数    ';
label AVG_DAYS             ='平均每次逾期停留天数      ';
label PTP_RATIO            ='PTP比率                   ';
label AVG_ROLLSEQ          ='历史回退平均期数          ';
label MAX_CPD              ='历史最大逾期cs_cpd        ';
label BPTP                 ='BPTP次数                  ';
label SEQ_DUEDAYS          ='延滞天数                  ';
label PTP                  ='PTP次数                   ';
label HIS_PTP              ='历史PTP复核总天数         ';
label ROLL_SEQ             ='累计回退期数              ';
label ROLL_TIME            ='回退次数                  ';
label FINISH_PERIODS_RATIO ='实还期数比                ';
label PERSON_SEX           ='性别                      ';
label EDUCATION            ='教育程度                  ';
label PERSON_APP_AGE       ='年龄                      ';
label CITY                 ='城市                      ';
label FAMILY_STATE         ='婚姻状态                  ';
label OTHER_PERSON_TYPE    ='其他联系人类型            ';
label CONTRACT_NO          ='合同号                    ';
label PUTOUT_DATE          ='放款日                    ';
label STATE_DATE           ='观察日                    ';
label CUSTOMERID           ='客户ID                    ';
label ACCT_LOAN_NO         ='放款号                    ';
label CPD                  ='CPD                       ';
label TARGET               ='Y值                       ';
label LOST= '历史完全失联次数';
label CSFQ= '历史催收频次';
label INCM_TIMES= '来电次数';
label DUE_CSTIME_RATIO= '当前欠款金额/总催收天数';
label DUE_CONTACT_RATIO= '当前欠款金额/可联次数';
label DUE_PTP_RATIO= '当前欠款金额/PTP次数';
label KPTP= 'KPTP次数';
label MAX_OVERDUE= '历史最大逾期金额          ';
label DELAY_TIMES= '进入逾期状态的次数（cpd1天起算）';
label VALUE_BALANCE_RATIO= '应还金额比贷款余额';
label CREDIT_AMOUNT= '贷款金额';
label APR_CREDIT_AMT= '通过总贷款金额';
label CHILDRENTOTAL= '子女个数';
label IS_SSI= '是否社保';
label IS_INSURE= '是否购买保险';
run;



proc sql;/*导入oracle数据表*/
create table lf.a0100_mst_ds as select * from f15.lf_xj_base_m1_dcc_cn_4 where target>=0 ;
quit;
/*有 2304367 行，36 列*/

/*得到数据字典*/
proc contents data=lf.a0100_mst_ds out=lf.a0100_mst_dict; run;
proc sort data=lf.a0100_mst_dict;by VARNUM; run;


****变量探测******************************************************************;
%let var_cont_list = TARGET
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

%let var_disc_list = TARGET
person_sex
family_state
education
is_ssi
childrentotal
other_person_type
city
is_insure

;


/*1.1 对于连续数据变量进行一般的分布统计----means过程*/
/*DZ:后期可看分布稳定性*/
ods HTML file="&output_file./01_1_EDA_mean.xls";/*2模型变量均值过程--1_2_EDA_mean.xls*/
proc means data =  lf.a0100_mst_ds   /*QMETHOD=P2*/  n nmiss mean median min max p5 p10 p25 p50 p75 p90 p95;
var &var_cont_list.;   
run;
ods html close;

/*1.2、对于离散变量进行一般的分布统计----freq过程*/
ods HTML file="&output_file./01_2_EDA_freq.xls";/*3模型分类变量频数过程--1_3_EDA_freq.xls*/
proc freq data =  lf.a0100_mst_ds;
tables &var_disc_list.; /*离散变量才行*/
run;
ods html close;

/*1.5 对于所有数值型连续变量进行一般的分布统计----univariate过程*/
ods HTML file="&output_file./01_5_EDA_univ.xls";/*1模型单变量分析--1_1_EDA_univ.xlsx*/
proc univariate data =  lf.a0100_mst_ds;
var &var_cont_list;   
run;
ods html close; 


****缺失值处理****************************************************************;
data lf.a0101_mst_ds_process;
  set lf.a0100_mst_ds;
  month_diff = (substr(state_date,1,4) - substr(putout_date,1,4))*12 + (substr(state_date,6,2) - substr(putout_date,6,2));
  if month_diff >= 2;
  drop month_diff;
  /*异常值处理*/
  if childrentotal <0 then childrentotal="0";
  if state_date < '2017-07-01';
run;

/*名义变量缺失值处理*/
/*原则:离散变量缺失值处理：缺失值超过1%，考虑单独分组。缺失值低于1%，用众数替代。*/

/*频数缺失用众数替代（缺失率<=1%)*/
%let Dsin=lf.a0101_mst_ds_process     ; %let DSout=lf.a0101_mst_ds_process_temp; %let Xvar=family_state; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process_temp; %let DSout=lf.a0101_mst_ds_process     ; %let Xvar=education; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process     ; %let DSout=lf.a0101_mst_ds_process_temp; %let Xvar=is_ssi; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process_temp; %let DSout=lf.a0101_mst_ds_process     ; %let Xvar=childrentotal; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process     ; %let DSout=lf.a0101_mst_ds_process_temp; %let Xvar=other_person_type; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process_temp; %let DSout=lf.a0101_mst_ds_process     ; %let Xvar=is_insure; %let Value=; %let Method=1; %SubCat(&DSin,&Xvar,&Method,&Value,&DSout);


ods HTML file="&output_file./01_3_EDA_freq_process.xls";
proc freq data =  lf.a0101_mst_ds_process;
tables &var_disc_list.; /*离散变量才行*/
run;
ods html close;


/*连续变量缺失值处理*/
/*用中位数替代，如果缺失值超过5%，建议标注一下 不进入模型。*/
data lf.a0101_mst_ds_process2;
  set lf.a0101_mst_ds_process;
run;

%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=cs_times; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=csfq; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=contact; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=lost; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=ptp; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=his_ptp; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=incm_times; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=kptp; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=bptp; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=value_balance_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=due_cstime_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=due_contact_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=due_ptp_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=avg_rollseq; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=ptp_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2_temp; %let DSout=lf.a0101_mst_ds_process2     ; %let Xvar=bptp_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);
%let Dsin=lf.a0101_mst_ds_process2     ; %let DSout=lf.a0101_mst_ds_process2_temp; %let Xvar=dk_ratio; %let Value=0; %let Method=value; %SubCont(&DSin,&Xvar,&Method,&Value,&DSout);

data lf.a0101_mst_ds_process2;
  set lf.a0101_mst_ds_process2_temp;
run;


ods HTML file="&output_file./01_4_EDA_mean_process.xls";
proc means data =  lf.a0101_mst_ds_process2  n nmiss mean median min max p5 p10 p25 p50 p75 p90 p95;
var &var_cont_list.;   
run;
ods html close;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
