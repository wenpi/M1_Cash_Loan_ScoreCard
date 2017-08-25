libname sasmacro 'E:\项目整理\4.工具学习\SAS\分析宏';
options mstored sasmstore=sasmacro mstored mautosource;

/*****************************************************************************************************
宏说明：
		该宏用测试集验证模型及变量的稳定性，分别采用PSI及SSI两个指标
依赖的宏：		1、无
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
%macro totalpsi(train_data,test_data,model_coef,P,Nb)/store;
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
		 %let Bin_L&i=%sysevalf(&Bin_U&i-&Bs);
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
       IF &P. > &Bin_L10 THEN P1=10; 
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

/*2、SSI计算*/
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
	create table &train_data._var_pSI as 
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
	
	data &train_data._var_pSI;
	set &train_data._var_pSI;
	by column;
	if first.column then ssi=0;
	ssi+Stability_Index;
	run;

proc delete data=temp_train temp_blimits &train_data._range temp_test &train_data._clus_total &test_data._clus_total &train_data._clus &test_data._clus;
run;
%mend;


