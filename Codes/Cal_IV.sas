
******************************************************************************;
*** 7&11逻辑回归                                                           ***;
******************************************************************************;
rsubmit;/*输入变量集可以修改*/
/*%let varlist1=
MAX_ROLL_SEQ
FINISH_PERIODS_RATIO
DELAY_DAYS_RATE
BPTP_RATIO
HIS_DUESEQ
DK_RATIO
;*/
/*%let varlist1=BPTP_RATIO_woe city_woe DELAY_DAYS_RATE_woe DK_RATIO_woe EDUCATION_woe FAMILY_STATE_woe FINISH_PERIODS_RATIO_woe MAX_CPD_woe MAX_OVERDUE_woe OTHER_PERSON_TYPE_woe PERSON_SEX_woe PTP_RATIO_woe PUTOUT_SAGROUP_woe ONTIME_PAY INCM_TIMES DUE_CSTIME_RATIO;*/
%let varlist1=CS_TIMES_woe CSFQ_woe CONTACT_woe LOST_woe PTP_woe HIS_PTP_woe INCM_TIMES_woe BPTP_woe AVG_DAYS_woe DELAY_DAYS_woe DELAY_DAYS_RATE_woe ONTIME_PAY_woe INTIME_PAY_woe CON1_DUE_TIMES_woe MAX_CONDUE10_woe CON10_DUE_TIMES_woe
HIS_DUESEQ_woe SEQ_DUEDAYS_woe MAX_ROLL_SEQ_woe DUE_DELAY_RATIO_woe DUE_CSTIME_RATIO_woe DUE_CONTACT_RATIO_woe DUE_PTP_RATIO_woe FINE10_SEQ_RATIO_woe ROLL_TIME_woe ROLL_SEQ_woe HIS_DELAYDAYS_woe PAY_PRINCIPAL_woe PAY_DELAY_NUM_woe
PAY_DELAY_FEE_woe RAW_SCORE_woe DELAY_TIMES_woe MAX_CPD_woe MAX_OVERDUE_woe PTP_RATIO_woe BPTP_RATIO_woe FINISH_PERIODS_RATIO_woe DK_RATIO_woe

PERSON_SEX_woe FAMILY_STATE_woe EDUCATION_woe COMPANY_TYPE_woe JOBTIME_woe INDUSTRY_woe POSITION_woe HOUSE_TYPE_woe EMAIL_woe F_SAME_REG_woe IS_CERTID_PROVINCE_woe
OTHER_PERSON_TYPE_woe POS_TYPE_woe PROVINCE_woe CITY_woe IS_INSURE_woe IS_HOLIDAYS_woe QQNO_INIT_woe CERT_4_INITAL_woe;
run;
proc logistic data=lf_xy.train_woe outmodel=lf_xy.model1 /*logistic建模文件*/
outest =lf_xy.train_model_params alpha=0.05;           /*logistic参数和协方差阵*/
model target (event='1')=&varlist1/                  /*目标变量、x变量集*/
SELECTION =S  SLE=0.05 SLS=0.05  ;                 /*逐步回归调选变量、0.05条件*/
output out=lf_xy.train_pred_probs p=pred_target lower=pi_l upper=pi_u;   /*建模结果文件 380437*250，增加4个变量：_level_,pred_target,pi_l,pi_u*/
run;
endrsubmit;


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




data train_test;
  set lf_xy.train_woe;
PERSON_SEX_ch=put(PERSON_SEX_b,8.);
FAMILY_STATE_ch=put(FAMILY_STATE_b,8.);
EDUCATION_ch=put(EDUCATION_b,8.);
IS_SSI_ch=put(IS_SSI_b,8.);
COMPANY_TYPE_ch=put(COMPANY_TYPE_b,8.);
JOBTIME_ch=put(JOBTIME_b,8.);
INDUSTRY_ch=put(INDUSTRY_b,8.);
POSITION_ch=put(POSITION_b,8.);
TOTAL_WK_EXP_ch=put(TOTAL_WK_EXP_b,8.);
HOUSE_TYPE_ch=put(HOUSE_TYPE_b,8.);
EMAIL_ch=put(EMAIL_b,8.);
F_SAME_REG_ch=put(F_SAME_REG_b,8.);
IS_CERTID_PROVINCE_ch=put(IS_CERTID_PROVINCE_b,8.);
OTHER_PERSON_TYPE_ch=put(OTHER_PERSON_TYPE_b,8.);
POS_TYPE_ch=put(POS_TYPE_b,8.);
PROVINCE_ch=put(PROVINCE_b,8.);
CITY_ch=put(CITY_b,8.);
IS_INSURE_ch=put(IS_INSURE_b,8.);
IS_HOLIDAYS_ch=put(IS_HOLIDAYS_b,8.);
F_SAME_COM_ch=put(F_SAME_COM_b,8.);
PUTOUT_SAGROUP_ch=put(PUTOUT_SAGROUP_b,8.);
STATE_SAGROUP_ch=put(STATE_SAGROUP_b,8.);
PERIODS_ch=put(PERIODS_b,8.);
PERSON_APP_AGE_ch=put(PERSON_APP_AGE_b,8.);
CERTF_INTERVAL_YEARS_ch=put(CERTF_INTERVAL_YEARS_b,8.);
EXPENSE_MONTH_ch=put(EXPENSE_MONTH_b,8.);
FAMILY_INCOME_ch=put(FAMILY_INCOME_b,8.);
CHILDRENTOTAL_ch=put(CHILDRENTOTAL_b,8.);
QQ_LENGTH_ch=put(QQ_LENGTH_b,8.);
MANAGEMENTFEESRATE_ch=put(MANAGEMENTFEESRATE_b,8.);
CUSTOMERSERVICERATES_ch=put(CUSTOMERSERVICERATES_b,8.);
EFFECTIVEANNUALRATE_ch=put(EFFECTIVEANNUALRATE_b,8.);
CS_TIMES_ch=put(CS_TIMES_b,8.);
CSFQ_ch=put(CSFQ_b,8.);
CONTACT_ch=put(CONTACT_b,8.);
LOST_ch=put(LOST_b,8.);
PTP_ch=put(PTP_b,8.);
HIS_PTP_ch=put(HIS_PTP_b,8.);
INCM_TIMES_ch=put(INCM_TIMES_b,8.);
KPTP_ch=put(KPTP_b,8.);
BPTP_ch=put(BPTP_b,8.);
AVG_DAYS_ch=put(AVG_DAYS_b,8.);
DELAY_DAYS_ch=put(DELAY_DAYS_b,8.);
DELAY_DAYS_RATE_ch=put(DELAY_DAYS_RATE_b,8.);
ONTIME_PAY_ch=put(ONTIME_PAY_b,8.);
INTIME_PAY_ch=put(INTIME_PAY_b,8.);
CON1_DUE_TIMES_ch=put(CON1_DUE_TIMES_b,8.);
MAX_CONDUE10_ch=put(MAX_CONDUE10_b,8.);
CON10_DUE_TIMES_ch=put(CON10_DUE_TIMES_b,8.);
HIS_DUESEQ_ch=put(HIS_DUESEQ_b,8.);
IS10FINE_ch=put(IS10FINE_b,8.);
SEQ_DUEDAYS_ch=put(SEQ_DUEDAYS_b,8.);
MAX_ROLL_SEQ_ch=put(MAX_ROLL_SEQ_b,8.);
ROLL_TIME_ch=put(ROLL_TIME_b,8.);
ROLL_SEQ_ch=put(ROLL_SEQ_b,8.);
HIS_DELAYDAYS_ch=put(HIS_DELAYDAYS_b,8.);
PAY_PRINCIPAL_ch=put(PAY_PRINCIPAL_b,8.);
PAY_INTEREST_ch=put(PAY_INTEREST_b,8.);
PAY_SERVICE_FEE_ch=put(PAY_SERVICE_FEE_b,8.);
PAY_FINANCE_FEE_ch=put(PAY_FINANCE_FEE_b,8.);
PAY_DELAY_NUM_ch=put(PAY_DELAY_NUM_b,8.);
PAY_DELAY_FEE_ch=put(PAY_DELAY_FEE_b,8.);
PAY_TOTAL_FEE_ch=put(PAY_TOTAL_FEE_b,8.);
FINISH_SEQ_ch=put(FINISH_SEQ_b,8.);
RAW_SCORE_ch=put(RAW_SCORE_b,8.);
APR_CREDIT_AMT_ch=put(APR_CREDIT_AMT_b,8.);
CREDIT_AMOUNT_ch=put(CREDIT_AMOUNT_b,8.);
OVER_DUE_VALUE_ch=put(OVER_DUE_VALUE_b,8.);
DELAY_TIMES_ch=put(DELAY_TIMES_b,8.);
MAX_CPD_ch=put(MAX_CPD_b,8.);
MAX_OVERDUE_ch=put(MAX_OVERDUE_b,8.);
PTP_RATIO_ch=put(PTP_RATIO_b,8.);
BPTP_RATIO_ch=put(BPTP_RATIO_b,8.);
DK_RATIO_ch=put(DK_RATIO_b,8.);
VALUE_INCOME_RATIO_ch=put(VALUE_INCOME_RATIO_b,8.);
VALUE_BALANCE_RATIO_ch=put(VALUE_BALANCE_RATIO_b,8.);
DUE_PERIODS_RATIO_ch=put(DUE_PERIODS_RATIO_b,8.);
OVERDUE_PERIODS_RATIO_ch=put(OVERDUE_PERIODS_RATIO_b,8.);
DUE_DELAY_RATIO_ch=put(DUE_DELAY_RATIO_b,8.);
DUE_CSTIME_RATIO_ch=put(DUE_CSTIME_RATIO_b,8.);
DUE_CONTACT_RATIO_ch=put(DUE_CONTACT_RATIO_b,8.);
DUE_PTP_RATIO_ch=put(DUE_PTP_RATIO_b,8.);
AVG_ROLLSEQ_ch=put(AVG_ROLLSEQ_b,8.);
FINE10_SEQ_RATIO_ch=put(FINE10_SEQ_RATIO_b,8.);
FINISH_PERIODS_RATIO_ch=put(FINISH_PERIODS_RATIO_b,8.);
QQNO_INIT_ch=put(QQNO_INIT_b,8.);
CERT_4_INITAL_ch=put(CERT_4_INITAL_b,8.);

;
run;


%let DSin=train_test;
%let DV=target;
%let IVList=
PERSON_SEX_ch
FAMILY_STATE_ch
EDUCATION_ch
IS_SSI_ch
COMPANY_TYPE_ch
JOBTIME_ch
INDUSTRY_ch
POSITION_ch
TOTAL_WK_EXP_ch
HOUSE_TYPE_ch
EMAIL_ch
F_SAME_REG_ch
IS_CERTID_PROVINCE_ch
OTHER_PERSON_TYPE_ch
POS_TYPE_ch
PROVINCE_ch
CITY_ch
IS_INSURE_ch
IS_HOLIDAYS_ch
F_SAME_COM_ch
PUTOUT_SAGROUP_ch
STATE_SAGROUP_ch
PERIODS_ch
PERSON_APP_AGE_ch
CERTF_INTERVAL_YEARS_ch
EXPENSE_MONTH_ch
FAMILY_INCOME_ch
CHILDRENTOTAL_ch
QQ_LENGTH_ch
MANAGEMENTFEESRATE_ch
CUSTOMERSERVICERATES_ch
EFFECTIVEANNUALRATE_ch
CS_TIMES_ch
CSFQ_ch
CONTACT_ch
LOST_ch
PTP_ch
HIS_PTP_ch
INCM_TIMES_ch
KPTP_ch
BPTP_ch
AVG_DAYS_ch
DELAY_DAYS_ch
DELAY_DAYS_RATE_ch
ONTIME_PAY_ch
INTIME_PAY_ch
CON1_DUE_TIMES_ch
MAX_CONDUE10_ch
CON10_DUE_TIMES_ch
HIS_DUESEQ_ch
IS10FINE_ch
SEQ_DUEDAYS_ch
MAX_ROLL_SEQ_ch
ROLL_TIME_ch
ROLL_SEQ_ch
HIS_DELAYDAYS_ch
PAY_PRINCIPAL_ch
PAY_INTEREST_ch
PAY_SERVICE_FEE_ch
PAY_FINANCE_FEE_ch
PAY_DELAY_NUM_ch
PAY_DELAY_FEE_ch
PAY_TOTAL_FEE_ch
FINISH_SEQ_ch
RAW_SCORE_ch
APR_CREDIT_AMT_ch
CREDIT_AMOUNT_ch
OVER_DUE_VALUE_ch
DELAY_TIMES_ch
MAX_CPD_ch
MAX_OVERDUE_ch
PTP_RATIO_ch
BPTP_RATIO_ch
DK_RATIO_ch
VALUE_INCOME_RATIO_ch
VALUE_BALANCE_RATIO_ch
DUE_PERIODS_RATIO_ch
OVERDUE_PERIODS_RATIO_ch
DUE_DELAY_RATIO_ch
DUE_CSTIME_RATIO_ch
DUE_CONTACT_RATIO_ch
DUE_PTP_RATIO_ch
AVG_ROLLSEQ_ch
FINE10_SEQ_RATIO_ch
FINISH_PERIODS_RATIO_ch
QQNO_INIT_ch
CERT_4_INITAL_ch
;
%let DSOut=Cal_IV;
%PowerIV(&DSin, &DV, &IVList, &DSout);
