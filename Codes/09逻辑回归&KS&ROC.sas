/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:53:05
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
/* 无法确定要在“SASApp”上分配逻辑库“LF_XY”的代码 */
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

/*   节点开始: 09逻辑回归&KS&ROC   */
%LET _CLIENTTASKLABEL='09逻辑回归&KS&ROC';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE=;

GOPTIONS ACCESSIBLE;

******************************************************************************;                                                                                                                                
*** 09逻辑回归，计算KS，画KS曲线，计算ROC，画ROC曲线     参照的代码7.28  xgb   
*** 建模月份1610 1611 1612，test是2017年1月到6月                                                                                                                             
******************************************************************************;  

/*每次先删除Matrix_hb1_xgb，以免存入重复内容*/
proc sql;delete * from lf_xy.Matrix_hb1_xgb;run;

******************************************************************************;                                                                                                                                
*** %macro model_many(x1,x2,x3,x4)， author: xgb   
*** x1 ：建模作者；x3：模型名称；x4：模型变量集                                                                                                                           
******************************************************************************;   
%macro model_many(x1,x2,x3,x4);
%let varlist1=&x4;  run;      /*此处填写入模变量集*/

/*logistic建模*/
proc logistic data=lf_xy.train_woe outmodel=lf_xy.model1   /*logistic建模文件 train_woe*/
outest =lf_xy.train_model_params alpha=0.05;                       /*logistic参数和协方差阵*/
model target (event='1')=&varlist1/ stb                                            /*目标变量、x变量集*/
SELECTION =S  SLE=0.05 SLS=0.05  ;                                              /*逐步回归调选变量、0.05条件*/
output out=lf_xy.train_pred_probs p=pred_target lower=pi_l upper=pi_u;   /*建模结果文件 380437*250，增加4个变量：_level_,pred_target,pi_l,pi_u*/
run;

/*对valid文件打分*/
proc logistic inmodel=lf_xy.model1;score data=lf_xy.valid_woe out=lf_xy.valid_pred_probs;run;
proc freq data=lf_xy.valid_pred_probs;tables F_target*I_target ;run;
data lf_xy.valid_pred_probs(rename=(P_1=pred_target));set lf_xy.valid_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
/*对test文件打分*/
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe out=lf_xy.test_pred_probs;run;
proc freq data=lf_xy.test_pred_probs;tables F_target*I_target ;run;
data lf_xy.test_pred_probs(rename=(P_1=pred_target));set lf_xy.test_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
/*对test_1701~1706文件打分*/
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1701 out=lf_xy.test_1701_pred_probs;run;proc freq data=lf_xy.test_1701_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1701_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1701_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1702 out=lf_xy.test_1702_pred_probs;run;proc freq data=lf_xy.test_1702_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1702_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1702_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1703 out=lf_xy.test_1703_pred_probs;run;proc freq data=lf_xy.test_1703_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1703_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1703_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1704 out=lf_xy.test_1704_pred_probs;run;proc freq data=lf_xy.test_1704_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1704_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1704_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1705 out=lf_xy.test_1705_pred_probs;run;proc freq data=lf_xy.test_1705_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1705_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1705_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf_xy.test_woe_1706 out=lf_xy.test_1706_pred_probs;run;proc freq data=lf_xy.test_1706_pred_probs;tables F_target*I_target ;run;data lf_xy.test_1706_pred_probs(rename=(P_1=pred_target));set lf_xy.test_1706_pred_probs;I_target2 = I_target*1;target = F_target*1;run;
proc logistic inmodel=lf_xy.model1;score data=lf.test17_a_woe out=lf_xy.test17a_pred_probs;run;proc freq data=lf_xy.test17a_pred_probs;tables F_target*I_target ;run;data lf_xy.test17a_pred_probs(rename=(P_1=pred_target));set lf_xy.test17a_pred_probs;I_target2 = I_target*1;target = F_target*1;run;

/*计算 confusion Matrix*/
%let dsin=lf_xy.train_pred_probs;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix1;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.valid_pred_probs;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix2;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1701_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1701;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1702_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1702;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1703_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1703;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1704_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1704;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1705_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1705;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test_1706_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_1706;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);
%let dsin=lf_xy.test17a_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let cutoff=0.5;%let dscm=lf_xy.confusionMatrix3_17a;%ConfMat(&DSin, &ProbVar, &DVVar, &Cutoff, &DSCM);

run;

/*计算train,valid,test的,Accuracy   Precision  Recall   F_value */
data lf_xy.confusionMatrix1;set lf_xy.confusionMatrix1;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall   =TP/(TP+FN); F_value  =2*Precision*Recall/(Precision+Recall);id="train";run;
data lf_xy.confusionMatrix2;set lf_xy.confusionMatrix2;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall   =TP/(TP+FN)    ;F_value  =2*Precision*Recall/(Precision+Recall);id="valid";run;
data lf_xy.confusionMatrix3;set lf_xy.confusionMatrix3;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall   =TP/(TP+FN)    ;F_value  =2*Precision*Recall/(Precision+Recall);id="test";run;
data lf_xy.confusionMatrix3_1701;set lf_xy.confusionMatrix3_1701;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1701";run;
data lf_xy.confusionMatrix3_1702;set lf_xy.confusionMatrix3_1702;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1702";run;
data lf_xy.confusionMatrix3_1703;set lf_xy.confusionMatrix3_1703;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1703";run;
data lf_xy.confusionMatrix3_1704;set lf_xy.confusionMatrix3_1704;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1704";run;
data lf_xy.confusionMatrix3_1705;set lf_xy.confusionMatrix3_1705;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1705";run;
data lf_xy.confusionMatrix3_1706;set lf_xy.confusionMatrix3_1706;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_1706";run;
data lf_xy.confusionMatrix3_17a;set lf_xy.confusionMatrix3_17a;Accuracy =(TN+TP)/Ntotal;Precision=TP/(TP+FP);Recall =TP/(TP+FN);F_value =2*Precision*Recall/(Precision+Recall);id="test_17a";run;

/*计算 KS*/
%let dsin=lf_xy.train_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks1;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.valid_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks2;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1701_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1701;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1702_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1702;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1703_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1703;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1704_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1704;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1705_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1705;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test_1706_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_1706;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);
%let dsin=lf_xy.test17a_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsks=lf_xy.dsks3_17a;%let ks=;%KSStat(&DSin, &ProbVar, &DVVar, &DSKS, KS);

%put &KS;
%PlotKS (&dsks);
proc sql;create table lf_xy.tmp1 as select *,"train" as id from lf_xy.dsks1 where ks in (select max(ks) as ks from lf_xy.dsks1);quit;data lf_xy.confusionMatrix1;merge lf_xy.confusionMatrix1 lf_xy.tmp1;by id;run;
proc sql;create table lf_xy.tmp2 as select *,"valid" as id from lf_xy.dsks2 where ks in (select max(ks) as ks from lf_xy.dsks2);quit;data lf_xy.confusionMatrix2;merge lf_xy.confusionMatrix2 lf_xy.tmp2;by id;run;
proc sql;create table lf_xy.tmp3 as select *,"test"  as id from lf_xy.dsks3 where ks in (select max(ks) as ks from lf_xy.dsks3);quit;data lf_xy.confusionMatrix3;merge lf_xy.confusionMatrix3 lf_xy.tmp3;by id;run;
proc sql;create table lf_xy.tmp3_1701 as select *,"test_1701"  as id from lf_xy.dsks3_1701 where ks in (select max(ks) as ks from lf_xy.dsks3_1701);quit;data lf_xy.confusionMatrix3_1701;merge lf_xy.confusionMatrix3_1701 lf_xy.tmp3_1701;by id;run;
proc sql;create table lf_xy.tmp3_1702 as select *,"test_1702"  as id from lf_xy.dsks3_1702 where ks in (select max(ks) as ks from lf_xy.dsks3_1702);quit;data lf_xy.confusionMatrix3_1702;merge lf_xy.confusionMatrix3_1702 lf_xy.tmp3_1702;by id;run;
proc sql;create table lf_xy.tmp3_1703 as select *,"test_1703"  as id from lf_xy.dsks3_1703 where ks in (select max(ks) as ks from lf_xy.dsks3_1703);quit;data lf_xy.confusionMatrix3_1703;merge lf_xy.confusionMatrix3_1703 lf_xy.tmp3_1703;by id;run;
proc sql;create table lf_xy.tmp3_1704 as select *,"test_1704"  as id from lf_xy.dsks3_1704 where ks in (select max(ks) as ks from lf_xy.dsks3_1704);quit;data lf_xy.confusionMatrix3_1704;merge lf_xy.confusionMatrix3_1704 lf_xy.tmp3_1704;by id;run;
proc sql;create table lf_xy.tmp3_1705 as select *,"test_1705"  as id from lf_xy.dsks3_1705 where ks in (select max(ks) as ks from lf_xy.dsks3_1705);quit;data lf_xy.confusionMatrix3_1705;merge lf_xy.confusionMatrix3_1705 lf_xy.tmp3_1705;by id;run;
proc sql;create table lf_xy.tmp3_1706 as select *,"test_1706"  as id from lf_xy.dsks3_1706 where ks in (select max(ks) as ks from lf_xy.dsks3_1706);quit;data lf_xy.confusionMatrix3_1706;merge lf_xy.confusionMatrix3_1706 lf_xy.tmp3_1706;by id;run;
proc sql;create table lf_xy.tmp3_17a as select *,"test_17a"  as id from lf_xy.dsks3_17a where ks in (select max(ks) as ks from lf_xy.dsks3_17a);quit;data lf_xy.confusionMatrix3_17a;merge lf_xy.confusionMatrix3_17a lf_xy.tmp3_17a;by id;run;

/*ROC曲线*/
%let dsin=lf_xy.train_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat1=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat1);
%let dsin=lf_xy.valid_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat2=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat2);
%let dsin=lf_xy.test_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3);
%let dsin=lf_xy.test_1701_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1701=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1701);
%let dsin=lf_xy.test_1702_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1702=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1702);
%let dsin=lf_xy.test_1703_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1703=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1703);
%let dsin=lf_xy.test_1704_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1704=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1704);
%let dsin=lf_xy.test_1705_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1705=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1705);
%let dsin=lf_xy.test_1706_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_1706=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_1706);
%let dsin=lf_xy.test17a_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dsroc=lf_xy.dsroc;%let cStat3_17a=;%ROC(&DSin, &ProbVar, &DVVar, &DSROC, cStat3_17a);

%put >>>>>>>>>>>>>>  train_c_Stat=&cStat1   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>>  valid_c_Stat=&cStat2   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>>  test_c_Stat=&cStat3   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>>  test_1701_c_Stat=&cStat3_1701   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>>  test_1702_c_Stat=&cStat3_1702   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>>  test_1703_c_Stat=&cStat3_1703   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>>  test_1704_c_Stat=&cStat3_1704   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>>  test_1705_c_Stat=&cStat3_1705   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>>  test_1706_c_Stat=&cStat3_1706   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>>  test_1706_c_Stat=&cStat3_17a   <<<<<<<<<<<<<;

data lf_xy.confusionMatrix1;set lf_xy.confusionMatrix1;ROC_c_Stat=&cStat1;run;
data lf_xy.confusionMatrix2;set lf_xy.confusionMatrix2;ROC_c_Stat=&cStat2;run;
data lf_xy.confusionMatrix3;set lf_xy.confusionMatrix3;ROC_c_Stat=&cStat3;run;
data lf_xy.confusionMatrix3_1701;set lf_xy.confusionMatrix3_1701;ROC_c_Stat=&cStat3_1701;run;
data lf_xy.confusionMatrix3_1702;set lf_xy.confusionMatrix3_1702;ROC_c_Stat=&cStat3_1702;run;
data lf_xy.confusionMatrix3_1703;set lf_xy.confusionMatrix3_1703;ROC_c_Stat=&cStat3_1703;run;
data lf_xy.confusionMatrix3_1704;set lf_xy.confusionMatrix3_1704;ROC_c_Stat=&cStat3_1704;run;
data lf_xy.confusionMatrix3_1705;set lf_xy.confusionMatrix3_1705;ROC_c_Stat=&cStat3_1705;run;
data lf_xy.confusionMatrix3_1706;set lf_xy.confusionMatrix3_1706;ROC_c_Stat=&cStat3_1706;run;
data lf_xy.confusionMatrix3_17a;set lf_xy.confusionMatrix3_17a;ROC_c_Stat=&cStat3_17a;run;

/*Gini*/
%let dsin=lf_xy.train_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini1=;%GiniStat(&DSin, &ProbVar, &dvvar, &dslorenz, Gini1);
%let dsin=lf_xy.valid_pred_probs;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini2=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini2);
%let dsin=lf_xy.test_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3);
%let dsin=lf_xy.test_1701_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1701=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1701);
%let dsin=lf_xy.test_1702_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1702=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1702);
%let dsin=lf_xy.test_1703_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1703=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1703);
%let dsin=lf_xy.test_1704_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1704=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1704);
%let dsin=lf_xy.test_1705_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1705=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1705);
%let dsin=lf_xy.test_1706_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_1706=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_1706);
%let dsin=lf_xy.test17a_pred_probs ;%let probvar=pred_target;%let dvvar=target;%let dslorenz=lf_xy.lorenzds;%let Gini3_17a=;%GiniStat(&DSin, &ProbVar, &DVVar, &dslorenz, Gini3_17a);
%put >>>>>>>>>>>>>> Gini1=&Gini1   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini2   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini3   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>> Gini1=&Gini3_1701   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini3_1702   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini3_1703   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>> Gini1=&Gini3_1704   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini3_1705   <<<<<<<<<<<<<;%put >>>>>>>>>>>>>> Gini1=&Gini3_1706   <<<<<<<<<<<<<;
%put >>>>>>>>>>>>>> Gini1=&Gini3_17a   <<<<<<<<<<<<<;

data lf_xy.confusionMatrix1;set lf_xy.confusionMatrix1;Gini=&Gini1;run;
data lf_xy.confusionMatrix2;set lf_xy.confusionMatrix2;Gini=&Gini2;run;
data lf_xy.confusionMatrix3;set lf_xy.confusionMatrix3;Gini=&Gini3;run;
data lf_xy.confusionMatrix3_1701;set lf_xy.confusionMatrix3_1701;Gini=&Gini3_1701;run;
data lf_xy.confusionMatrix3_1702;set lf_xy.confusionMatrix3_1702;Gini=&Gini3_1702;run;
data lf_xy.confusionMatrix3_1703;set lf_xy.confusionMatrix3_1703;Gini=&Gini3_1703;run;
data lf_xy.confusionMatrix3_1704;set lf_xy.confusionMatrix3_1704;Gini=&Gini3_1704;run;
data lf_xy.confusionMatrix3_1705;set lf_xy.confusionMatrix3_1705;Gini=&Gini3_1705;run;
data lf_xy.confusionMatrix3_1706;set lf_xy.confusionMatrix3_1706;Gini=&Gini3_1706;run;
data lf_xy.confusionMatrix3_17a;set lf_xy.confusionMatrix3_17a;Gini=&Gini3_17a;run;

%PlotROC(&DSROC);
data lf_xy.Matrix_hb1_&x2;format id $9.;
set lf_xy.confusionMatrix1 lf_xy.confusionMatrix2 lf_xy.confusionMatrix3 
	  lf_xy.confusionMatrix3_1701 lf_xy.confusionMatrix3_1702 lf_xy.confusionMatrix3_1703 
	  lf_xy.confusionMatrix3_1704 lf_xy.confusionMatrix3_1705 lf_xy.confusionMatrix3_1706  lf_xy.confusionMatrix3_17a;run;
proc print data=lf_xy.Matrix_hb1_&x2;var  id  N Accuracy Precision Recall F_value KS ROC_c_Stat Gini;run;



data lf_xy.Matrix_hb1_&x2;set lf_xy.Matrix_hb1_&x2;
format Accuracy percent8.2;
format Precision percent8.2;
format Recall percent8.2;
format F_value percent8.2;
format KS percent8.2;
format ROC_c_Stat percent8.2;
format modeler    $5.;
format model_name $100.;
format note    $100.;
format varlist $500.;
modeler=&x1 ;model_name="&x2" ;note=&x3 ;varlist="&x4" ;
run;

data lf_xy.Matrix_hb1_xgb;set lf_xy.Matrix_hb1_xgb lf_xy.Matrix_hb1_&x2;run;
%mend;

/*没有负系数
%model_many('xgb',mod_var7_001,  'model001',
bptp_ratio_woe  delay_days_rate_woe max_cpd_woe person_sex_woe  ptp_ratio_woe roll_seq_woe education_woe);

%model_many('xgb',mod_var8_001,  'model002',   
bptp_ratio_woe  delay_days_rate_woe max_cpd_woe person_sex_woe  ptp_ratio_woe roll_seq_woe  education_woe  city_woe);*/

%model_many('xgb',mod_var9_001,  'model003',   
delay_days_rate_woe bptp_ratio_woe roll_seq_woe ptp_ratio_woe person_sex_woe max_cpd_woe city_woe education_woe family_state_woe);


proc print data=lf_xy.Matrix_hb1_xgb;run;


GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
