/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:53:34
PROJECT: M1现金贷催收评分卡_DCC_FP0818
PROJECT PATH: E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp
---------------------------------------- */

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

/*   节点开始: 00_Macro_PSI_SSI_Calculation   */
%LET _CLIENTTASKLABEL='00_Macro_PSI_SSI_Calculation';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE='C:\Users\yang.xiao\Desktop\00_Macro_PSI_SSI_Calculation.sas';

GOPTIONS ACCESSIBLE;

/*****************************************************************************************************
宏说明：
		该宏用测试集验证模型及变量的稳定性，分别采用PSI及SSI两个指标
依赖的宏：
		1、无
参数说明：
		train_data:
				训练集的woe值及P值
		test_data
				测试集的woe值及P值
		model_coef
				模型入选变量表
        P
                P值的取名
        Nb
                分数分段数
输出结果表：
		输出PSI及SSI结果表
作者：丁露涛
日期：2017.5.12
说明:
        %Preselection(训练集的woe值及P值,测试集的woe值及P值,模型入选变量表,P值的取名,分数分段数);		 
*****************************************************************************************************/
%macro totalpsi(train_data,test_data,P,Nb);
/*1、PSI计算*/
/* 找出训练集分数的最大值、最小值及总单量*/
	proc sql  noprint; 
		 select  max(&P.),min(&P.),count(1) into : Pmax, : Pmin ,:nobs1
          from   &train_data.;/*最高分、最低分*/
	quit;

	 /*计算出每个分数段的宽度*/
	%let Bs =%sysevalf((&Pmax-&Pmin)/&Nb);/*sysevalf 计算算术和逻辑表达式，浮点格式*/

	/*计算训练集每个分段的上界及下界*/
	data temp_train;
	 set &train_data.;
	  %do i=1 %to &Nb;
		 %let Bin_U&i=%sysevalf(&Pmin+&i*&Bs);
		 %let Bin_L&i=%sysevalf(&&Bin_U&i-&Bs);
		 IF &P. > &&Bin_L&i and &P. <=&&Bin_U&i THEN P1=&i.; 
	  %end;
	  if p1=. then p1=1;
	run;
	/* 生成一个包含每个分段的上下界的表 */
	data temp_blimits;
        %do i=1 %to &Nb;
         Bin_LowerLimit=&&Bin_L&i;
         Bin_UpperLimit=&&Bin_U&i;
          Bin=&i;
		  output;
     %end;
    run;

	/*训练集的分段范围及各分段的单量及占比*/
	proc sql noprint;
	create table &train_data._range as
	(select A.bin,A.Bin_LowerLimit,A.Bin_UpperLimit,b.n as train_n,b.percent as train_pct
            from temp_blimits as A,
	(select p1,count(1) as n,count(1)/&nobs1. as percent from temp_train group by p1) AS B
     where A.Bin=B.p1);
	run;

	/*训练集的上下界进行调整并整合分数分段范围*/
	data &train_data._range;
	set &train_data._range;
	if _n_=10 then Bin_UpperLimit=999999;
    if _n_=1 then Bin_LowerLimit=-999999;
	range=compress(cats("(",Bin_LowerLimit,",",Bin_UpperLimit,"]"),'');
	run;

	/* 找出测试集的总单量*/
	proc sql  noprint; 
		 select count(1) into :nobs2
          from   &test_data.;/*总单量*/
	quit;

	/*按照训练集的上下界对测试集的P值进行划段*/
	data temp_test;
	 set &test_data.;
	  %do i=1 %to &Nb-1;
		 IF &P. > &&Bin_L&i and &P. <=&&Bin_U&i THEN P1=&i.; 
	  %end;
       IF &P. > &&Bin_L&Nb THEN P1=&Nb; 
	   if P1=. then p1=1;
	run;

   /*计算PSI*/
	proc sql noprint;
	create table &train_data._psi as
	select * ,test_pct-train_pct as difference,test_pct/train_pct as variance,log(ifn(test_pct=.,0.001,test_pct/train_pct)) as ln,
          (test_pct-train_pct)*log(ifn(test_pct=.,0.001,test_pct/train_pct)) as Stability_Index
        from
	((select A.*,b.n as test_n,ifn(b.percent=.,0.001,b.percent) as test_pct
            from &train_data._range as A
	left join 
	(select p1,count(1) as n,count(1)/&nobs2. as percent from temp_test group by p1) AS B
     on A.Bin=B.p1));
	run;

	data &train_data._psi;
	set &train_data._psi;
	sum+Stability_Index;
	run;

proc delete data=temp_train temp_blimits &train_data._range temp_test;
run;
%mend;



%macro totalssi(train_data,test_data,model_coef);
/*2、SSI计算*/
	proc sql  noprint; 
		 select count(1) into :nobs1
          from   &train_data.;
	quit;

	proc sql  noprint; 
		 select count(1) into :nobs2
          from   &test_data.;/*总单量*/
	quit;

	proc sql  noprint; 
	select variable into : varlist separated by ' ' from  &model_coef. where variable<>"Intercept";/*找出模型中需要计算SSI的各变量*/
       %LET nvar=&SQLOBS;
      QUIT;
     %put &varlist.;

	 proc sql  noprint; 
	 create table &train_data._clus_total
	 (column varchar(100)
	 ,woe numeric
	 ,n numeric
	 ,percent numeric);
	 run;

	  proc sql  noprint; 
	 create table &test_data._clus_total
	 (column varchar(100)
	 ,woe numeric
	 ,n numeric
	 ,percent numeric);
	 run;

  %do i=1 %to &nvar;
       %LET var = %SCAN(&varlist, &i);

	/*训练集各个变量分组的占比情况*/
	proc sql noprint;
	create table &train_data._clus as
	(select "&var." as column,&var. as woe,count(1) as n,count(1)/&nobs1. as percent from &train_data. group by &var.);
	run;

	data &train_data._clus_total;
	set  &train_data._clus_total &train_data._clus;
	run;
   /*测试集各个变量分组的占比情况*/
    proc sql noprint;
	create table &test_data._clus as
	(select "&var." as column,&var. as woe,count(1) as n,count(1)/&nobs2. as percent from &test_data. group by &var.);
	run;

	data &test_data._clus_total;
	set  &test_data._clus_total &test_data._clus ;
	run;
 %end;


   /*计算SSI*/
	proc sql noprint;
	create table &test_data._var_pSI as 
	(select *,test_pct-train_pct as difference,test_pct/train_pct as variance,log(ifn(test_pct=0,0.001,test_pct/train_pct)) as ln,
          (test_pct-train_pct)*log(ifn(test_pct=0,0.001,test_pct/train_pct)) as Stability_Index
		  from
	(select A.column,A.woe as clus,A.n as train_n,A.percent as train_pct,B.n as test_n,ifn(b.percent=.,0.001,b.percent) as test_pct
	from &train_data._clus_total as A
	left join &test_data._clus_total as B
	on A.column=B.column
	and A.woe=B.woe)
      );
	run;
	
	data &test_data._var_pSI;
	set &test_data._var_pSI;
	by column;
	if first.column then ssi=0;
	ssi+Stability_Index;
	run;
	
proc delete data= &train_data._clus_total &test_data._clus_total &train_data._clus &test_data._clus;
run;

%mend;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
