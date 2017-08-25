/* ----------------------------------------
从 SAS Enterprise Guide 导出的代码
DATE: 2017年8月25日     TIME: 14:53:21
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

/*   节点开始: 00_Macro_F01   */
%LET _CLIENTTASKLABEL='00_Macro_F01';
%LET _CLIENTPROCESSFLOWNAME='过程流';
%LET _CLIENTPROJECTPATH='E:\git_space\M1_Cash_Loan_ScoreCard\Codes\M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _CLIENTPROJECTNAME='M1现金贷催收评分卡_DCC_FP0818.egp';
%LET _SASPROGRAMFILE='C:\Users\yang.xiao\Desktop\00_Macro_F01.sas';

GOPTIONS ACCESSIBLE;

******************************************************************************;                                                                                                                                
*** 2名义变量最优法降基                                                    ***;                                                                                                                                 
******************************************************************************;   

/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat  Ch 5.1/5.2
********/



/* The macros:
   These are FIVE macros used to find the rules to reduce
   the cardinality of a nominal variable with string 
   values. They are:
   GValue, CalcMErit, BestSplit, CandSplits, ReduceCats.
   Only ReduceCats is to be called to obain the mappings
   for the reduction of cardinality. 

   Applying the maps requires the final macro: ApplyMap1. */

/*******************************************************/
/* Macro GValue */
/*******************************************************/
%macro GValue(BinDS, Method, M_Value);
/* Calculation of the value of current split  */

/* Extract the frequency table values */
proc sql noprint;
  /* Count the number of obs and categories of X and Y */
   %local i j R N; /* C=2, R=Bmax+1 */
   select max(bin) into : R from &BinDS;
   select sum(total) into : N from &BinDS; 

   /* extract n_i_j , Ni_star*/
   %do i=1 %to &R; 
      %local N_&i._1 N_&i._2 N_&i._s N_s_1 N_s_2;
   Select sum(Ni1) into :N_&i._1 from &BinDS where Bin =&i ;
   Select sum(Ni2) into :N_&i._2 from &BinDS where Bin =&i ;
   Select sum(Total) into :N_&i._s from &BinDS where Bin =&i ;
   Select sum(Ni1) into :N_s_1 from &BinDS ;
   Select sum(Ni2) into :N_s_2 from &BinDS ;
%end;
quit;

%if (&method=1) %then %do; /* Gini */

	/* substitute in the equations for Gi, G */
	  %do i=1 %to &r;
	     %local G_&i;
	     %let G_&i=0;
	       %do j=1 %to 2;
	          %let G_&i = %sysevalf(&&G_&i + &&N_&i._&j * &&N_&i._&j);
	       %end;
	      %let G_&i = %sysevalf(1-&&G_&i/(&&N_&i._s * &&N_&i._s));
	   %end;

	   %local G; 
	    %let G=0;
	    %do j=1 %to 2;
	       %let G=%sysevalf(&G + &&N_s_&j * &&N_s_&j);
	    %end;
	    %let G=%sysevalf(1 - &G / (&N * &N));

	/* finally, the Gini ratio Gr */
	%local Gr;
	%let Gr=0; 
	 %do i=1 %to &r;
	   %let Gr=%sysevalf(&Gr+ &&N_&i._s * &&G_&i / &N);
	 %end;

	%let &M_Value=%sysevalf(1 - &Gr/&G); 
    %return;
					%end;

%if (&Method=2) %then %do; /* Entropy */

/* Check on zero counts or missings */
   %do i=1 %to &R; 
    %do j=1 %to 2;
	      %local N_&i._&j;
	      %if (&&N_&i._&j=.) or (&&N_&i._&j=0) %then %do ; /* return a missing value */ 
	         %let &M_Value=.;
	      %return; 
		                          %end;
     %end;
   %end;
  
/* substitute in the equations for Ei, E */
  %do i=1 %to &r;
     %local E_&i;
     %let E_&i=0;
       %do j=1 %to 2;
          %let E_&i = %sysevalf(&&E_&i - (&&N_&i._&j/&&N_&i._s)*%sysfunc(log(%sysevalf(&&N_&i._&j/&&N_&i._s))) );
       %end;
      %let E_&i = %sysevalf(&&E_&i/%sysfunc(log(2)));
   %end;
   %local E; 
    %let E=0;
    %do j=1 %to 2;
       %let E=%sysevalf(&E - (&&N_s_&j/&N)*%sysfunc(log(&&N_s_&j/&N)) );
    %end;
    %let E=%sysevalf(&E / %sysfunc(log(2)));

/* finally, the Entropy ratio Er */
	%local Er;
	%let Er=0; 
	 %do i=1 %to &r;
	   %let Er=%sysevalf(&Er+ &&N_&i._s * &&E_&i / &N);
	 %end;
	%let &M_Value=%sysevalf(1 - &Er/&E); 
	 %return;
					   %end;

%if (&Method=3)%then %do; /* The Pearson's X2 statistic */
 %local X2;
	%let N=%eval(&n_s_1+&n_s_2);
	%let X2=0;
	%do i=1 %to &r;
	  %do j=1 %to 2;
		%local m_&i._&j;
		%let m_&i._&j=%sysevalf(&&n_&i._s * &&n_s_&j/&N);
		%let X2=%sysevalf(&X2 + (&&n_&i._&j-&&m_&i._&j)*(&&n_&i._&j-&&m_&i._&j)/&&m_&i._&j  );  
	  %end;
	%end;
	%let &M_value=&X2;
	%return;

%end; /* end of X2 */

%if (&Method=4) %then %do; /* Information value */
/* substitute in the equation for IV */
     %local IV;
     %let IV=0;
   /* first, check on the values of the N#s */
	%do i=1 %to &r;
	   	      %if (&&N_&i._1=.) or (&&N_&i._1=0) or 
                  (&&N_&i._2=.) or (&&N_&i._2=0) or
                  (&N_s_1=) or (&N_s_1=0)    or  
				  (&N_s_2=) or (&N_s_2=0)     
				%then %do ; /* return a missing value */ 
	               %let &M_Value=.;
	                %return; 
		              %end;
	    %end;
       %do i=1 %to &r;
          %let IV = %sysevalf(&IV + (&&N_&i._1/&N_s_1 - &&N_&i._2/&N_s_2)*%sysfunc(log(%sysevalf(&&N_&i._1*&N_s_2/(&&N_&i._2*&N_s_1)))) );
       %end;
    %let &M_Value=&IV; 
						%end;
%mend;

/*******************************************************/
/* Macro CalcMerit */
/*******************************************************/
%macro CalcMerit(BinDS, ix, method, M_Value);
/* claculation of the merit function for the current location 
   on a candidate bin. All nodes on or above the value
   are grouped together, and those larger up to the end 
   of the bin are together */

/*   Use SQL to find the frquencies of the contingency table  */
%local n_11 n_12 n_21 n_22 n_1s n_2s n_s1 n_s2; 
proc sql noprint;
 select sum(Ni1) into :n_11 from &BinDS where i<=&ix;
 select sum(Ni1) into :n_21 from &BinDS where i> &ix;

 select sum(Ni2) into : n_12 from &BinDS where i<=&ix ;
 select sum(Ni2) into : n_22 from &binDS where i> &ix ;

 select sum(total) into :n_1s from &BinDS where i<=&ix ;
 select sum(total) into :n_2s from &BinDS where i> &ix ;

 select sum(Ni1) into :n_s1 from &BinDS;
 select sum(Ni2) into :n_s2 from &BinDS;
quit;

/* Calcualte the merit functino according to its type */
/* The case of Gini */
%if (&method=1) %then %do;
    %local N G1 G2 G Gr;
	%let N=%eval(&n_1s+&n_2s);
	%let G1=%sysevalf(1-(&n_11*&n_11+&n_12*&n_12)/(&n_1s*&n_1s));
	%let G2=%sysevalf(1-(&n_21*&n_21+&n_22*&n_22)/(&n_2s*&n_2s));
	%let G =%sysevalf(1-(&n_s1*&n_s1+&n_s2*&n_s2)/(&N*&N));
	%let GR=%sysevalf(1-(&n_1s*&G1+&n_2s*&G2)/(&N*&G));
	%let &M_value=&Gr;
	%return;
				%end;
/* The case of Entropy */
%if (&method=2) %then %do;
   %local N E1 E2 E Er;
	%let N=%eval(&n_1s+&n_2s);
	%let E1=%sysevalf(-( (&n_11/&n_1s)*%sysfunc(log(%sysevalf(&n_11/&n_1s))) + 
						 (&n_12/&n_1s)*%sysfunc(log(%sysevalf(&n_12/&n_1s)))) / %sysfunc(log(2)) ) ;
	%let E2=%sysevalf(-( (&n_21/&n_2s)*%sysfunc(log(%sysevalf(&n_21/&n_2s))) + 
						 (&n_22/&n_2s)*%sysfunc(log(%sysevalf(&n_22/&n_2s)))) / %sysfunc(log(2)) ) ;
	%let E =%sysevalf(-( (&n_s1/&n  )*%sysfunc(log(%sysevalf(&n_s1/&n   ))) + 
						 (&n_s2/&n  )*%sysfunc(log(%sysevalf(&n_s2/&n   )))) / %sysfunc(log(2)) ) ;
	%let Er=%sysevalf(1-(&n_1s*&E1+&n_2s*&E2)/(&N*&E));
	%let &M_value=&Er;
	%return;
				%end;
/* The case of X2 pearson statistic */
%if (&method=3) %then %do;
 %local m_11 m_12 m_21 m_22 X2 N i j;
	%let N=%eval(&n_1s+&n_2s);
	%let X2=0;
	%do i=1 %to 2;
	  %do j=1 %to 2;
		%let m_&i.&j=%sysevalf(&&n_&i.s * &&n_s&j/&N);
		%let X2=%sysevalf(&X2 + (&&n_&i.&j-&&m_&i.&j)*(&&n_&i.&j-&&m_&i.&j)/&&m_&i.&j  );  
	  %end;
	%end;
	%let &M_value=&X2;
	%return;
%end;

/* The case of the information value */

%if (&method=4) %then %do;
  %local IV;
  %let IV=%sysevalf( ((&n_11/&n_s1)-(&n_12/&n_s2))*%sysfunc(log(%sysevalf((&n_11*&n_s2)/(&n_12*&n_s1)))) 
                    +((&n_21/&n_s1)-(&n_22/&n_s2))*%sysfunc(log(%sysevalf((&n_21*&n_s2)/(&n_22*&n_s1)))) );
   %let &M_Value=&IV;
   %return;
%end;
%mend;

/*******************************************************/
/* Macro BestSplit */
/*******************************************************/
%macro BestSplit(BinDs, Method, BinNo);

/* find the best split for one bin dataset */
/* the bin size=mb */
%local mb i value BestValue BestI;
proc sql noprint;
 select count(*) into: mb from &BinDs where Bin=&BinNo; 
quit;

/* find the location of the split on this list */
%let BestValue=0;
%let BestI=1;
%do i=1 %to %eval(&mb-1);
  %let value=;
  %CalcMerit(&BinDS, &i, &method, Value);
  %if %sysevalf(&BestValue<&value) %then %do;
      %let BestValue=&Value;
	  %let BestI=&i;
	   %end;
%end;

/* Number the bins from 1->BestI =BinNo, and from BestI+1->mb =NewBinNo */

/* split the BinNo into two bins */ 
data &BinDS;
 set &BinDS;
  if i<=&BestI then Split=1;
  else Split=0;
drop i;
run;
proc sort data=&BinDS; 
by Split;
run;
/* reorder i within each bin */
data &BinDS;
retain i 0;
set &BinDs;
 by Split;
 if first.split then i=1;
 else i=i+1;
run;
%mend;

/*******************************************************/
/* Macro CandSplit */
/*******************************************************/
%macro CandSplits(BinDS, Method, NewBins);
/* Generate all candidate splits from current
   Bins and select the best new bins */

/* first we sort the dataset OldBins by PDV1 and Bin */
proc sort data=&BinDS;
by Bin PDV1;
run;
/* within each bin, separate the data into a candidate dataset */
%local Bmax i value;
proc sql noprint;
 select max(bin) into: Bmax from &BinDS;
%do i=1 %to &Bmax;
%local m&i;
   create table Temp_BinC&i as select * from &BinDS where Bin=&i;
   select count(*) into:m&i from Temp_BinC&i;
%end;
   create table temp_allVals (BinToSplit num, DatasetName char(80), Value num);
run;quit;

/* for each of these bins,*/
%do i=1 %to &Bmax;
 %if (&&m&i>1) %then %do;  /* if the bin has more than one category */
 /* find the best split possible  */
  %BestSplit(Temp_BinC&i, &Method, &i);
 /* try this split and calculate its value */
  data temp_trysplit&i;
    set temp_binC&i;
	if split=1 then Bin=%eval(&Bmax+1);
  run;

  Data temp_main&i;
   set &BinDS;
   if Bin=&i then delete;
  run;
  Data Temp_main&i;
    set temp_main&i temp_trysplit&i;
  run;

 /* Evaluate the value of this split
    as the next best split */
  %let value=;
 %GValue(temp_main&i, &Method, Value);

 proc sql noprint;
  insert into temp_AllVals values(&i, "temp_main&i", &Value);
 run;quit;

 %end; /* end of trying for a bin wih more than one category */

%end;
 
/* find the best split  and return the new bin dataset */
proc sort data=temp_allVals;
by descending value;
run;
data _null_;
 set temp_AllVals(obs=1);
 call symput("bin", compress(BinToSplit));
run;

/* the return dataset is the best bin Temp_trySplit&bin */
Data &NewBins;
 set Temp_main&Bin;
 drop split;
run;

/* Clean the workspace */
proc datasets nodetails nolist library=work;
 delete temp_AllVals %do i=1 %to &Bmax; Temp_BinC&i  temp_TrySplit&i temp_Main&i %end; ;
run;
quit;
%mend;

/*******************************************************/
/* Macro ReduceCats */
/*******************************************************/
%macro  ReduceCats(DSin, IVVar, DVVar, Method, Mmax,  DSVarMap);
/* Reducing the categories of a categorical variable */

/* Get the categories of the IV, and the percentage 
   of the DV=1 and DV=0 in each one of them */
	/* get the categories using CalcCats macro */

proc freq data=&DSin noprint;
 table &IVVar*&DVvar /out=Temp_cross;
 table &IVVar /out=Temp_IVtot;
 run;

/* Rollup on the level of the category */
proc sort data=temp_cross;
 by &IVVar;
run;

proc sort data= temp_IVTot;
by &IVvar;
run;

data temp_cont; /* contingency table */
merge Temp_cross(rename=count=Ni2 ) temp_IVTot (rename=Count=total);
by &IVVar; 
PDV1=Ni2/total;
Ni1=total-Ni2;
label  Ni2= total=;
if &DVVar=1 then output;
drop percent &DVVar;
run;

/* sort by the percentage of DV=1 */
proc sort data=temp_cont;
by PDV1;
run;

%local m;
/* put all the category in one node as a string point */
data temp_cont;
 set temp_cont (Rename=&IVVar=Var);
 i=_N_;
 Bin=1;
 call symput("m", compress(_N_)); /* m=number of categories */
run;

/* loop until  the maximum number of nodes has been reached */
%local Nbins ;
%let Nbins=1; /* Current number of bins */ 
%DO %WHILE (&Nbins <&MMax);
	%CandSplits(temp_cont, &method, Temp_Splits);
	Data Temp_Cont;
  		set Temp_Splits;
	run;
	%let NBins=%eval(&NBins+1);

%end; /* end of the WHILE splitting loop  */
/* the output dataset is DSVarMap */
data &DSVarMap ;
 set temp_cont(Rename=Var=&IVVar); 
 set temp_cont(Rename=Var=Category); /*增加Category，方便后面生成评分卡*****************************************************************/
 drop Ni2 PDV1 Ni1 i ;
 label Bin      ='New Category Group' 
       Category ='Old Category Group'
        total   ='Number of Records';
 run;

proc sort data=&DSVarMap;
by Bin;
run;

 /* clean the workspace */
proc datasets library=work nodetails nolist;
 delete temp_cont temp_cross temp_ivtot temp_Splits;
run;quit;
%mend;





******************************************************************************;                                                                                                                                
*** 3名义变量分组映射                                                      ***;                                                                                                                                 
******************************************************************************;  
/* Macro ApplyMap1 */
/******************************************************
%macro ApplyMap1(DSin, VarX, NewVarX, DSVarMap, DSout);
%local m i;
proc sql noprint;
 select count(&VarX) into:m from &DSVarMap;
quit; 
%do i=1 %to &m;
 %local Cat_&i Bin_&i;
%end; 
data _null_;
 set &DSVarMap;
  call symput ("Cat_"||left(_N_), trim(&VarX));
  call symput ("Bin_"||left(_N_), bin);
run;
Data &DSout;
 set &DSin;
 %do i=1 %to &m;
   IF &VarX = "&&Cat_&i"  THEN &NewVarX=&&Bin_&i;
 %end;
 %let n=%eval(&i-1);
 if &NewVarX="." then &NewVarX=&&Bin_&n;  
Run; 
%mend;
*/
/*************************************/
/* Macro ApplyMapl */
/*************************************/
%macro ApplyMap1(DSin, VarX, NewVarX, DSVarMap, DSout);
%local m i;
proc sql noprint;
 select count(&VarX) into:m from &DSVarMap;
quit; 
%do i=1 %to &m;
 %local Cat_&i Bin_&i;
%end; 
data _null_;
 set &DSVarMap;
  call symput ("Cat_"||left(_N_), trim(&VarX));
  call symput ("Bin_"||left(_N_), bin);
run;
Data &DSout;
 set &DSin;
 %do i=1 %to &m;
   IF &VarX = "&&Cat_&i"  THEN &NewVarX=&&Bin_&i;
 %end;
 %let n=%eval(&i-1);
 if &NewVarX="." then &NewVarX=&&Bin_&n;  
Run; 
%mend;


******************************************************************************;                                                                                                                                
*** 4连续变量最优法分割                                                    ***;                                                                                                                                 
******************************************************************************;   
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* The macros: GValue, CalcMerit, BestSplit, CandSplits,
   BinContVar
   macro BinContVar needs all the above 4 macros to run
   and to apply the binning maps, use ApplyMap2. 
/*******************************************************/



/*******************************************************/
/* Macro GValue */
/*******************************************************/
%macro GValue4(BinDS, Method, M_Value);
/* Calculation of the value of current split  */

/* Extract the frequency table values */
proc sql noprint;
  /* Count the number of obs and categories of X and Y */
   %local i j R N; /* C=2, R=Bmax+1 */
   select max(bin) into : R from &BinDS;
   select sum(total) into : N from &BinDS; 

   /* extract n_i_j , Ni_star*/
   %do i=1 %to &R; 
      %local N_&i._1 N_&i._2 N_&i._s N_s_1 N_s_2;
   Select sum(Ni1) into :N_&i._1 from &BinDS where Bin =&i ;
   Select sum(Ni2) into :N_&i._2 from &BinDS where Bin =&i ;
   Select sum(Total) into :N_&i._s from &BinDS where Bin =&i ;
   Select sum(Ni1) into :N_s_1 from &BinDS ;
   Select sum(Ni2) into :N_s_2 from &BinDS ;
%end;
quit;
%if (&method=1) %then %do; /* Gini */
	/* substitute in the equations for Gi, G */

	  %do i=1 %to &r;
	     %local G_&i;
	     %let G_&i=0;
	       %do j=1 %to 2;
	          %let G_&i = %sysevalf(&&G_&i + &&N_&i._&j * &&N_&i._&j);
	       %end;
	      %let G_&i = %sysevalf(1-&&G_&i/(&&N_&i._s * &&N_&i._s));
	   %end;

	   %local G; 
	    %let G=0;
	    %do j=1 %to 2;
	       %let G=%sysevalf(&G + &&N_s_&j * &&N_s_&j);
	    %end;
	    %let G=%sysevalf(1 - &G / (&N * &N));

	/* finally, the Gini ratio Gr */
	%local Gr;
	%let Gr=0; 
	 %do i=1 %to &r;
	   %let Gr=%sysevalf(&Gr+ &&N_&i._s * &&G_&i / &N);
	 %end;

	%let &M_Value=%sysevalf(1 - &Gr/&G); 
    %return;
					%end;
%if (&Method=2) %then %do; /* Entropy */
/* Check on zero counts or missings */
   %do i=1 %to &R; 
    %do j=1 %to 2;
	      %local N_&i._&j;
	      %if (&&N_&i._&j=.) or (&&N_&i._&j=0) %then %do ; /* return a missing value */ 
	         %let &M_Value=.;
	      %return; 
		                          %end;
     %end;
   %end;
/* substitute in the equations for Ei, E */
  %do i=1 %to &r;
     %local E_&i;
     %let E_&i=0;
       %do j=1 %to 2;
          %let E_&i = %sysevalf(&&E_&i - (&&N_&i._&j/&&N_&i._s)*%sysfunc(log(%sysevalf(&&N_&i._&j/&&N_&i._s))) );
       %end;
      %let E_&i = %sysevalf(&&E_&i/%sysfunc(log(2)));
   %end;

   %local E; 
    %let E=0;
    %do j=1 %to 2;
       %let E=%sysevalf(&E - (&&N_s_&j/&N)*%sysfunc(log(&&N_s_&j/&N)) );
    %end;
    %let E=%sysevalf(&E / %sysfunc(log(2)));

/* finally, the Entropy ratio Er */

	%local Er;
	%let Er=0; 
	 %do i=1 %to &r;
	   %let Er=%sysevalf(&Er+ &&N_&i._s * &&E_&i / &N);
	 %end;
	%let &M_Value=%sysevalf(1 - &Er/&E); 
	 %return;
					   %end;
%if (&Method=3)%then %do; /* The Pearson's X2 statistic */
 %local X2;
	%let N=%eval(&n_s_1+&n_s_2);
	%let X2=0;
	%do i=1 %to &r;
	  %do j=1 %to 2;
		%local m_&i._&j;
		%let m_&i._&j=%sysevalf(&&n_&i._s * &&n_s_&j/&N);
		%let X2=%sysevalf(&X2 + (&&n_&i._&j-&&m_&i._&j)*(&&n_&i._&j-&&m_&i._&j)/&&m_&i._&j  );  
	  %end;
	%end;
	%let &M_value=&X2;
	%return;
%end; /* end of X2 */
%if (&Method=4) %then %do; /* Information value */
/* substitute in the equation for IV */
     %local IV;
     %let IV=0;
   /* first, check on the values of the N#s */
	%do i=1 %to &r;
	   	      %if (&&N_&i._1=.) or (&&N_&i._1=0) or 
                  (&&N_&i._2=.) or (&&N_&i._2=0) or
                  (&N_s_1=) or (&N_s_1=0)    or  
				  (&N_s_2=) or (&N_s_2=0)     
				%then %do ; /* return a missing value */ 
	               %let &M_Value=.;
	                %return; 
		              %end;
	    %end;
       %do i=1 %to &r;
          %let IV = %sysevalf(&IV + (&&N_&i._1/&N_s_1 - &&N_&i._2/&N_s_2)*%sysfunc(log(%sysevalf(&&N_&i._1*&N_s_2/(&&N_&i._2*&N_s_1)))) );
       %end;
    %let &M_Value=&IV; 
						%end;

%mend;



/*******************************************************/
/* Macro CalcMerit */
/*******************************************************/
%macro CalcMerit4(BinDS, ix, method, M_Value);
/* claculation of the merit function for the current  */
/*   Use SQL to find the frquencies of the contingency table  */
%local n_11 n_12 n_21 n_22 n_1s n_2s n_s1 n_s2; 
proc sql noprint;
 select sum(Ni1) into :n_11 from &BinDS where i<=&ix;
 select sum(Ni1) into :n_21 from &BinDS where i> &ix;
 select sum(Ni2) into : n_12 from &BinDS where i<=&ix ;
 select sum(Ni2) into : n_22 from &binDS where i> &ix ;
 select sum(total) into :n_1s from &BinDS where i<=&ix ;
 select sum(total) into :n_2s from &BinDS where i> &ix ;
 select sum(Ni1) into :n_s1 from &BinDS;
 select sum(Ni2) into :n_s2 from &BinDS;
quit;
/* Calcualte the merit functino according to its type */
/* The case of Gini */
%if (&method=1) %then %do;
    %local N G1 G2 G Gr;
	%let N=%eval(&n_1s+&n_2s);
	%let G1=%sysevalf(1-(&n_11*&n_11+&n_12*&n_12)/(&n_1s*&n_1s));
	%let G2=%sysevalf(1-(&n_21*&n_21+&n_22*&n_22)/(&n_2s*&n_2s));
	%let G =%sysevalf(1-(&n_s1*&n_s1+&n_s2*&n_s2)/(&N*&N));
	%let GR=%sysevalf(1-(&n_1s*&G1+&n_2s*&G2)/(&N*&G));
	%let &M_value=&Gr;
	%return;
				%end;
/* The case of Entropy */
%if (&method=2) %then %do;
   %local N E1 E2 E Er;
	%let N=%eval(&n_1s+&n_2s);
	%let E1=%sysevalf(-( (&n_11/&n_1s)*%sysfunc(log(%sysevalf(&n_11/&n_1s))) + 
						 (&n_12/&n_1s)*%sysfunc(log(%sysevalf(&n_12/&n_1s)))) / %sysfunc(log(2)) ) ;
	%let E2=%sysevalf(-( (&n_21/&n_2s)*%sysfunc(log(%sysevalf(&n_21/&n_2s))) + 
						 (&n_22/&n_2s)*%sysfunc(log(%sysevalf(&n_22/&n_2s)))) / %sysfunc(log(2)) ) ;
	%let E =%sysevalf(-( (&n_s1/&n  )*%sysfunc(log(%sysevalf(&n_s1/&n   ))) + 
						 (&n_s2/&n  )*%sysfunc(log(%sysevalf(&n_s2/&n   )))) / %sysfunc(log(2)) ) ;
	%let Er=%sysevalf(1-(&n_1s*&E1+&n_2s*&E2)/(&N*&E));
	%let &M_value=&Er;
	%return;
				%end;
/* The case of X2 pearson statistic */
%if (&method=3) %then %do;
 %local m_11 m_12 m_21 m_22 X2 N i j;
	%let N=%eval(&n_1s+&n_2s);
	%let X2=0;
	%do i=1 %to 2;
	  %do j=1 %to 2;
		%let m_&i.&j=%sysevalf(&&n_&i.s * &&n_s&j/&N);
		%let X2=%sysevalf(&X2 + (&&n_&i.&j-&&m_&i.&j)*(&&n_&i.&j-&&m_&i.&j)/&&m_&i.&j  );  
	  %end;
	%end;
	%let &M_value=&X2;
	%return;
%end;
/* The case of the information value */
%if (&method=4) %then %do;
  %local IV;
  %let IV=%sysevalf( ((&n_11/&n_s1)-(&n_12/&n_s2))*%sysfunc(log(%sysevalf((&n_11*&n_s2)/(&n_12*&n_s1)))) 
                    +((&n_21/&n_s1)-(&n_22/&n_s2))*%sysfunc(log(%sysevalf((&n_21*&n_s2)/(&n_22*&n_s1)))) );
   %let &M_Value=&IV;
   %return;
%end;
%mend;


/*******************************************************/
/* Macro BestSplit */
/*******************************************************/
%macro BestSplit4(BinDs, Method, BinNo);
/* find the best split for one bin dataset */
/* the bin size=mb */
%local mb i value BestValue BestI;
proc sql noprint;
 select count(*) into: mb from &BinDs where Bin=&BinNo; 
quit;
/* find the location of the split on this list */
%let BestValue=0;
%let BestI=1;
%do i=1 %to %eval(&mb-1);
  %let value=;
  %CalcMerit4(&BinDS, &i, &method, Value);
  %if %sysevalf(&BestValue<&value) %then %do;
      %let BestValue=&Value;
	  %let BestI=&i;
	   %end;
%end;
/* Number the bins from 1->BestI =BinNo, and from BestI+1->mb =NewBinNo */
/* split the BinNo into two bins */ 
data &BinDS;
 set &BinDS;
  if i<=&BestI then Split=1;
  else Split=0;
drop i;
run;
proc sort data=&BinDS; 
by Split;
run;
/* reorder i within each bin */
data &BinDS;
retain i 0;
set &BinDs;
 by Split;
 if first.split then i=1;
 else i=i+1;
run;
%mend;


/*******************************************************/
/* Macro CandSplits */
/*******************************************************/
%macro CandSplits4(BinDS, Method, NewBins);
/* Generate all candidate splits from current
   Bins and select the best new bins */
/* first we sort the dataset OldBins by PDV1 and Bin */
proc sort data=&BinDS;
by Bin PDV1;
run;
/* within each bin, separate the data into a candidate dataset */
%local Bmax i value;
proc sql noprint;
 select max(bin) into: Bmax from &BinDS;
%do i=1 %to &Bmax; 
%local m&i;
   create table Temp_BinC&i as select * from &BinDS where Bin=&i;
   select count(*) into:m&i from Temp_BinC&i; 
%end;
   create table temp_allVals (BinToSplit num, DatasetName char(80), Value num);
run;quit;
/* for each of these bins,*/
%do i=1 %to &Bmax;
 %if (&&m&i>1) %then %do;  /* if the bin has more than one category */
 /* find the best split possible  */
  %BestSplit4(Temp_BinC&i, &Method, &i);
 /* try this split and calculate its value */
  data temp_trysplit&i;
    set temp_binC&i;
	if split=1 then Bin=%eval(&Bmax+1);
  run;
  Data temp_main&i;
   set &BinDS;
   if Bin=&i then delete; 
  run;
  Data Temp_main&i;
    set temp_main&i temp_trysplit&i;
  run;
 /* Evaluate the value of this split 
    as the next best split */
  %let value=;
 %GValue4(temp_main&i, &Method, Value);
 proc sql noprint; 
  insert into temp_AllVals values(&i, "temp_main&i", &Value); 
 run;quit; 
 %end; /* end of trying for a bin wih more than one category */
%end;
/* find the best split  and return the new bin dataset */
proc sort data=temp_allVals;
by descending value;
run;
data _null_;
 set temp_AllVals(obs=1);
 call symput("bin", compress(BinToSplit));
run;
/* the return dataset is the best bin Temp_trySplit&bin */
Data &NewBins;
 set Temp_main&Bin;
 drop split;
run;
/* Clean the workspace */
proc datasets nodetails nolist library=work;
 delete temp_AllVals %do i=1 %to &Bmax; Temp_BinC&i  temp_TrySplit&i temp_Main&i %end; ; 
run;
quit;
%mend;


/*******************************************************/
/* Macro BinContVar */
/*******************************************************/
%macro BinContVar(DSin, IVVar, DVVar, Method, MMax, Acc, DSVarMap);
/* Optimal binning of the continuous variable */

/* find the maximum and minimum values */
%local VarMax VarMin;
proc sql noprint;
 select min(&IVVar), max(&IVVar) into :VarMin, :VarMax from &DSin;
quit;
/* divide the range to a number of bins as needed by Acc */
%local Mbins i MinBinSize;
%let Mbins=%sysfunc(int(%sysevalf(1.0/&Acc)));
%let MinBinSize=%sysevalf((&VarMax-&VarMin)/&Mbins);
/* calculate the bin boundaries between the max, min */
%do i=1 %to %eval(&Mbins);
 %local Lower_&i Upper_&i;
 %let Upper_&i = %sysevalf(&VarMin + &i * &MinBinSize);
 %let Lower_&i = %sysevalf(&VarMin + (&i-1)*&MinBinSize);
%end;
%let Lower_1 = %sysevalf(&VarMin-0.0001);  /* just to make sure that no digits get trimmed */
%let Upper_&Mbins=%sysevalf(&VarMax+0.0001);
/* separate the IVVar, DVVAr in a small dataset for faster operation */
data Temp_DS;
 set &DSin;
 %do i=1 %to %eval(&Mbins-1);
  if &IVVar>=&&Lower_&i and &IVVar < &&Upper_&i Then Bin=&i;
 %end;
  if &IVVar>=&&Lower_&Mbins and &IVVar <= &&Upper_&MBins Then Bin=&MBins;
 keep &IVVar &DVVar Bin;
run;
/* Generate a dataset with the initial upper, lower limits per bin */
data temp_blimits;
 %do i=1 %to %Eval(&Mbins-1);
   Bin_LowerLimit=&&Lower_&i;
   Bin_UpperLimit=&&Upper_&i;
   Bin=&i;
   output;
 %end;
   Bin_LowerLimit=&&Lower_&Mbins;
   Bin_UpperLimit=&&Upper_&Mbins;
   Bin=&Mbins;
   output;
run;
proc sort data=temp_blimits;
by Bin;
run;
/* Find the frequencies of DV=1, DV=0 using freq */
proc freq data=Temp_DS noprint;
 table Bin*&DVvar /out=Temp_cross;
 table Bin /out=Temp_binTot;
 run;
/* Rollup on the level of the Bin */
proc sort data=temp_cross;
 by Bin;
run;
proc sort data= temp_BinTot;
by Bin;
run;
data temp_cont; /* contingency table */
merge Temp_cross(rename=count=Ni2 ) temp_BinTot(rename=Count=total) temp_BLimits ;
by Bin; 
Ni1=total-Ni2;
PDV1=bin; /* just for conformity with the case of nominal iv */
label  Ni2= total=;
if Ni1=0 then output;
else if &DVVar=1 then output;
drop percent &DVVar;
run;
data temp_contold;
set temp_cont;
run;

/* merge all bins that have either Ni1 or Ni2 or total =0 */
proc sql noprint;
%local mx;
 %do i=1 %to &Mbins;
  /* get all the values */
  select count(*) into : mx from Temp_cont where Bin=&i;
  %if (&mx>0) %then %do;
  select Ni1, Ni2, total, bin_lowerlimit, bin_upperlimit into 
         :Ni1,:Ni2,:total, :bin_lower, :bin_upper 
  from temp_cont where Bin=&i;
  	%if (&i=&Mbins) %then %do;
	   select max(bin) into :i1 from temp_cont where Bin<&Mbins;
	                      %end;
	%else %do;
	   select min(bin) into :i1 from temp_cont where Bin>&i;
	   %end;
   %if (&Ni1=0) or (&Ni2=0) or (&total=0) %then %do;
			update temp_cont set 
			           Ni1=Ni1+&Ni1 ,
					   Ni2=Ni2+&Ni2 , 
					   total=total+&Total 
			where bin=&i1;
			%if (&i<&Mbins) %then %do;
			update temp_cont set Bin_lowerlimit = &Bin_lower where bin=&i1;
			                      %end;
			%else %do;
			update temp_cont set Bin_upperlimit = &Bin_upper where bin=&i1;
				   %end;
		   delete from temp_cont where bin=&i;
      %end; 
  %end;
%end;
quit;
proc sort data=temp_cont;
by pdv1;
run;
%local m;
/* put all the category in one node as a string point */
data temp_cont;
 set temp_cont;
 i=_N_;
 Var=bin;
 Bin=1;
 call symput("m", compress(_N_)); /* m=number of categories */
run;
/* loop until  the maximum number of nodes has been reached */
%local Nbins ;
%let Nbins=1; /* Current number of bins */ 
%DO %WHILE (&Nbins <&MMax);
	%CandSplits4(temp_cont, &method, Temp_Splits);
	Data Temp_Cont;
  		set Temp_Splits;
	run;
	%let NBins=%eval(&NBins+1);
%end; /* end of the WHILE splitting loop  */
/* shape the output map */
data temp_Map1 ;
 set temp_cont(Rename=Var=OldBin);
 drop Ni2 PDV1 Ni1 i ;
 run;
proc sort data=temp_Map1;
by Bin OldBin ;
run;
/* merge the bins and calculate boundaries */
data temp_Map2;
 retain  LL 0 UL 0 BinTotal 0;
 set temp_Map1;
by Bin OldBin;
Bintotal=BinTotal+Total;
if first.bin then do;
  LL=Bin_LowerLimit;
  BinTotal=Total;
    End;
if last.bin then do;
 UL=Bin_UpperLimit;
 output;
end;
drop Bin_lowerLimit Bin_upperLimit Bin OldBin total;
 run;
proc sort data=temp_map2;
by LL;
run;
data &DSVarMap;
set temp_map2;
Bin=_N_;
run;
/* Clean the workspace */
proc datasets nodetails library=work nolist;
 delete temp_bintot temp_blimits temp_cont temp_contold temp_cross temp_ds temp_map1
    temp_map2 temp_splits;
run; quit;
%mend;




******************************************************************************;                                                                                                                                
*** 5连续变量分组映射                                                      ***;                                                                                                                                 
******************************************************************************;   
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* Macro ApplyMap2 */
/*******************************************************/
%macro ApplyMap2(DSin, VarX, NewVarX, DSVarMap, DSout);
/* Applying a mapping scheme; to be used with 
 macro BinContVar */

/* Generating macro variables to replace the cetgories with their bins */
%local m i;
proc sql noprint;
 select count(Bin) into:m from &DSVarMap;
quit; 
%do i=1 %to &m;
 %local Upper_&i Lower_&i Bin_&i;
%end; 
data _null_;
 set &DSVarMap;
  call symput ("Upper_"||left(_N_), UL);
  call symput ("Lower_"||left(_N_), LL);
  call symput ("Bin_"||left(_N_), Bin);
run;
/* the actual replacement */
Data &DSout;
 set &DSin;
 /* first bin - open left */
 IF &VarX < &Upper_1 Then &NewVarX=&Bin_1;
 /* intermediate bins */
 %do i=2 %to %eval(&m-1);
   if &VarX >= &&Lower_&i and &VarX < &&Upper_&i Then &NewVarX=&&Bin_&i;
 %end;
/* last bin - open right */
   if &VarX >= &&Lower_&i  Then &NewVarX=&&Bin_&i;  
   
Run; 
%mend;



******************************************************************************;                                                                                                                                
*** 6变量woe计算与映射                                                     ***;                                                                                                                                 
******************************************************************************; 
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/

/*******************************************************/
/* Macro: CalcWOE */
/*******************************************************/
%macro CalcWOE(DsIn, IVVar, DVVar, WOEDS, WOEVar, DSout);
/* Calculating the WOE of an Independent variable IVVar and 
adding it to the data set DSin (producing a different output 
dataset DSout). The merging is done using PROC SQL to avoid 
the need to sort for matched merge. The new woe variable
is called teh WOEVar. The weight of evidence values
are also produced in the dataset WOEDS*/

/* Calculate the frequencies of the categories of the DV in each
of the bins of the IVVAR */

PROC FREQ data =&DsIn noprint;
  tables &IVVar * &DVVar/out=Temp_Freqs;
run;

/* sort them */
proc sort data=Temp_Freqs;
 by &IVVar &DVVar;
run;

/* Sum the Goods and bads and calcualte the WOE for each bin */
Data Temp_WOE1;
 set Temp_Freqs;
 retain C1 C0 C1T 0 C0T 0;
 by &IVVar &DVVar;
 if first.&IVVar then do;
      C0=Count;
	  C0T=C0T+C0;
	  end;
 if last.&IVVar then do;
       C1=Count;
	   C1T=C1T+C1;
	   end;
 
 if last.&IVVar then output;
 drop Count PERCENT &DVVar;
call symput ("C0T", C0T);
call symput ("C1T", C1T);
run;

/* summarize the WOE values ina woe map */ 
Data &WOEDs;
 set Temp_WOE1;
  GoodDist=C0/&C0T;
  BadDist=C1/&C1T;
  if(GoodDist>0 and BadDist>0)Then   WOE=log(BadDist/GoodDist);
  Else WOE=.;
  keep &IVVar WOE;
run;

proc sort data=&WOEDs;
 by WOE;
 run;

/* Match the maps with the values and create the output
dataset */
proc sql noprint;
	create table &dsout as 
	select a.* , b.woe as &WOEvar from &dsin a, &woeds b where a.&IvVar=b.&IvVar; 
quit;

/* Clean the workspace */
proc datasets library=work nodetails nolist;
 delete Temp_Freqs Temp_WOE1;
run; quit;
%mend;


******************************************************************************;                                                                                                                                
*** 11混合矩阵                                                             ***;                                                                                                                                 
******************************************************************************;  
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/

/*******************************************************/
/* Macro ConfMat  */
/*******************************************************/

%macro ConfMat(DSin, ProbVar, DVVar, Cutoff, DSCM);
/* 
Calculation of the Confusion matrix from the input dataset DSIn
with a probability variable ProbVar, and the actual dependent
variable DVVar. DSCM will store the resulting Confusion matrix

The calculation is done with a cutoff between 0,1.
*/

/* extract the actual DVVar, and the predicted outcome
   to a temp dataset to make the calculation faster, 
   calculate the predicted outcome */
data temp;
 set &DSin;
 if &ProbVar>=&Cutoff then _PDV=1;
  else _PDV=0;
 keep &DVVAR  _PDV;
run;

/* compute the total the elements of the confusion matrix
   using simple sql queries */
%local Ntotal P N TP TN FP FN;
proc sql noprint;
 select sum(&DVVar) into :P from temp;
 select count(*) into :Ntotal from temp;
 select sum(_PDV) into :TP from temp where &DVVar=1;
 select sum(_PDV) into :FP from temp where &DVVar=0; 
quit;
%let N=%eval(&Ntotal-&P);
%let FN=%eval(&P-&TP);
%let TN=%eval(&N-&FN);

/* Store the results in DSCM */
data &DSCM;
 TP=&TP;  TN=&TN;
 FP=&FP;  FN=&FN;
 P=&P;  N=&N;
 Ntotal=&Ntotal;
run;


/* Clean workspace */
proc datasets library=work nodetails nolist;
delete temp;
run; quit;

%mend;


******************************************************************************;                                                                                                                                
*** 12绘制KS曲线                                                           ***;                                                                                                                                 
******************************************************************************;  
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* Macro KSStat  */
/*******************************************************/
%macro KSStat(DSin, ProbVar, DVVar, DSKS, M_KS);
/* Calculation of the KS Statistic from the results of 
   a predictive model. DSin is the dataset with a dependent
   variable DVVar, and a predicted probability ProbVar. 
   The KS statistic is returnd in the parameter M_KS. 
   DSKS contains the data of the Lorenz curve for good and bad
   as well as the KS Curve. 

*/

/* Sort the observations using the predicted Probability */
proc sort data=&DsIn;
by &ProbVar;
run;

/* Find the total number of Positives and Negatives */
proc sql noprint;
 select sum(&DVVar) into:P from &DSin;
 select count(*) into :Ntot from &DSin;
 quit;
 %let N=%eval(&Ntot-&P); /* Number of negative */


 /* The base of calculation is 100 tiles */

/* Count number of positive and negatives per tile, their proportions and 
    cumulative proportions decile */
data &DSKS;
set &DsIn nobs=NN;
by &ProbVar;
retain tile 1  totP  0 totN 0;
Tile_size=ceil(NN/100);

if &DVVar=1 then totP=totP+&DVVar;
else totN=totN+1;

Pper=totP/&P;
Nper=totN/&N;

/* end of tile? */
if _N_ = Tile*Tile_Size then 
  do;
  output;
   if Tile <100 then  
       do;
         Tile=Tile+1;
		 SumResp=0;
	   end;
  end;	
keep Tile Pper Nper;
run;

/* add the point of zero  */
data temp;
	 Tile=0;
	 Pper=0;
	 NPer=0;
run;

Data &DSKS;
  set temp &DSKS;
run;

 
/* Scale the tile to represent percentage and add labels*/
data &DSKS;
	set &DSKS;
	Tile=Tile/100;
	label Pper='Percent of Positives';
	label NPer ='Percent of Negatives';
	label Tile ='Percent of population';

	/* calculate the KS Curve */
	KS=NPer-PPer;
run;

/* calculate the KS statistic */

proc sql noprint;
 select max(KS) into :&M_KS from &DSKS;
run; quit;

/* Clean the workspace */
proc datasets library=work nodetails nolist;
 delete temp ;
run;
quit;

%mend;


%macro PlotKS(DSKS);
/* Plotting the KS curve using gplot using simple options */

 symbol1 value=dot color=red   interpol=join  height=1;
 legend1 position=top;
 symbol2 value=dot color=blue  interpol=join  height=1;
 symbol3 value=dot color=green interpol=join  height=1;

proc gplot data=&DSKS;

  plot( NPer PPer KS)*Tile / overlay legend=legend1;
 run;
quit;
 
	goptions reset=all;
%mend;



******************************************************************************;                                                                                                                                
*** 13绘制ROC曲线                                                          ***;                                                                                                                                 
******************************************************************************;   
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* Macro ROC  */
/*******************************************************/
%macro ROC(DSin, ProbVar, DVVar, DSROC, M_CStat);
/* 
Calculation of the ROC Chart from the input dataset DSIn
with a probability variable ProbVar, and the actual dependent
variable DVVar. Iplot=1 will plot the ROC in the output window,
and DSROC will store the resulting ROC data

The calculation is done with a precision of delta (eg. 0.1 or 0.01)
*/
%let delta=0.01;

/* Sort the dataset using the probability in descending order */

proc sort data=&DSin;
by descending &ProbVar;
run;

/* compute the total number of observations, total number of positives
   and negatives */

proc sql noprint;
 select sum(&DVVar) into :NP from &DSin;
 select count(*) into :N from &DSin;
quit;
%let NN=%eval(&N-&NP);



/* This is the main calculation loop for the elements of the 
  confusion matrix */

data temp1;
 set &DSin;
  by descending &ProbVar;

retain TP 0 FP 0 TN &NN FN &NP level 1.0;

  NN=&NN;
  NP=&NP;

  Sensitivity=TP/NP;
  Specificity1=FP/NN;

/* and their labels */
  label Sensitivity ='Sensitivity';
  label Specificity1 ='1-Specificity';

if &ProbVar<level then 
   do;
	  output;
	  level=level-&Delta;
   end;


  if &DVVar=1 then TP=TP+1;
  if &DVVar=0 then FP=FP+1;


  FN=&NP-TP;
  TN=&NN-FP;
keep TP FP TN FN NN NP Level Sensitivity Specificity1;	
run;

/* The last entry in the ROC Data */

data temp2;
	level=0;
	TP=&NP;
	FP=0;
	TN=0;
	FN=&NN;
	NP=&NP;
	NN=&NN;
	Sensitivity=1;
	Specificity1=1;
run;

/* Append the last row */
data &DSROC;
 set temp1 temp2;
 run;

 /* Calculate the area under the curve using the 
   trapezoidal integration approximation.
   C=0.5 * Sum_(k=1)^(n)[X_k - X_(k-1)]*[Y_k + Y_(k-1)]
*/
%local C;
data _null_; /* use the null dataset for the summation */
retain Xk 0 Xk1 0 Yk 0 Yk1 0 C 0;
set &DSROC;

Yk=Sensitivity;
Xk=Specificity1;

C=C+0.5*(Xk-Xk1)*(Yk+Yk1);

/* next iteration */
Xk1=Xk;
Yk1=Yk;

/* output the C-statistic */
call symput ('C', compress(c) );
run;

/* Store the value of C in the output macro parameter M_CStat */

%let &M_CStat=&C;

/* Clean workspace */
proc datasets library=work nodetails nolist;
delete temp1 temp2;
run;
quit;


%mend;


/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* Macro PlotROC  */
/*******************************************************/
%macro PlotROC(DSROC);
goptions reset=global gunit=pct border cback=white
         colors=(black blue green red)
         ftitle=swissb ftext=swiss htitle=6 htext=4;


symbol1 color=red
        interpol=join
;
 
  proc gplot data=&DSROC;
   plot Sensitivity*Specificity1 / haxis=0 to 1 by 0.1
                    vaxis=0 to 1 by 0.1
                    hminor=3
                    vminor=1
 
                      vref=0.2 0.4 0.6 0.8 1.0
                    lvref=2
                    cvref=blue
                    caxis=blue
                    ctext=red;
run;
quit;
 
	goptions reset=all;
%mend;


******************************************************************************;                                                                                                                                
*** 13评分卡实施                                                           ***;                                                                                                                                 
******************************************************************************;   
/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/


/*******************************************************/
/* Macro SCScale */
/*******************************************************/
%macro SCScale(BasePoints, BaseOdds, PDO, M_alpha, M_beta);
/* this macro calculates alpha, beta to scale the scorecard
   such that points=alpha + beta (ln odds) 
   beta = pdo/ln(2)
   alpha=basePoints - beta * (ln base odds)
*/
%local bb;
%let bb=%sysevalf(&PDO / %sysfunc(log(2)));
%let &M_Beta = &bb;
%let &M_alpha= %sysevalf(&BasePoints - &bb * %sysfunc(log(&BaseOdds)));
%mend;




/*******************************************************/
/* Macro GenSCDS */
/*******************************************************/
%macro GenSCDS(ParamDS, Lib, DVName, BasePoints, BaseOdds, PDO, SCDS);
/*
Generation of a scorecard dataset using the predictive model stored in ParamDS
The datasets are in the library LIB
*/
 
/* first, get alpha and beta from the base points and pdo */
%local alpha beta;
%let alpha=;
%let beta=;
%SCScale(&BasePoints, &BaseOdds, &PDO, alpha, beta);

/* read the model coefficients from the model dataset */

proc transpose data =&ParamDS out=temp_mpt;
run;


/* remove ignore variables and ln likeilhood value, and get the intercept */
%local Intercept;

data temp_mptc;
 set temp_mpt;
length VarName $32.;
length MapDS  $32.;
length WOEDS $32.;
if _Name_ eq 'Intercept' then do;
  call symput('Intercept', compress(&DVName));
  delete;
  end;
 /* Make all names upper case */
  *_Name_=upcase(_Name_);

 /* restore variable names, names of maps, WOE datasets */
  ix=find(upcase(_Name_),'_WOE')-1;
  if ix >0 then VarName=substr(_Name_,1,ix);
  MapDS=compress(VarName)||'_MAP';
  BinName=compress(VarName)||'_b';
  WOEDS=_Name_;
  Parameter=&DVName;

  if _Name_ ne '_LNLIKE_' and &DVName ne . ;
  keep VarName BinName MapDS WOEDS Parameter;
run;

/* Scorecard Base points = alpha + intercept * beta */
  %local SCBase; 
  %let SCBase = %sysfunc(int(&alpha + &beta * &Intercept));


%local i N;
data _null_;
 set temp_mptc;
  call symput('N',compress(_N_));
run;
%do i=1 %to &N;
 %local V_&i P_&i WOE_&i Map_&i;
%end;

/* Start merging the scorecard table */
data _null_;
 set temp_mptc;
  call symput('V_'||left(_N_),compress(VarName));
  call symput('B_'||left(_N_),compress(BinName));
  call symput('P_'||left(_N_),compress(Parameter));
  call symput('WOE_'||left(_N_),"&Lib.."||compress(WOEDS));
  call symput('Map_'||left(_N_),"&lib.."||compress(MapDS));
run;

proc sql noprint;
 create table &SCDS (VarName char(80), UL num, LL num,  Points num);
 insert into &SCDS values('_BasePoints_' , 0    , 0     ,  &SCBase);
run; quit;

%do i=1 %to &N;

   data temp1;
     set &&WOE_&i;
	   bin=&&B_&i;
	   VarName="&&V_&i";
	   ModelParameter=&&P_&i;
   run;

   proc sort data=temp1;
    by bin;
   run;
   /* check the type of the nominal variable */
	proc contents data=&&Map_&i out=temp_cont nodetails noprint;
	run;
	%local MapType;
	proc sql noprint; 
	 select Type into :MapType from temp_cont where upcase(Name)='CATEGORY';
	run; quit;
	%if &MapType =1 %then %do; /* numeric variable */
	 Data &&Map_&i;
	  set &&Map_&i;
	   N_category=Category;
	   drop category;
	 run;
	%end;

   proc sort data=&&Map_&i;
    by bin;
   run;

    data temp_v;
     length category $70.;
	 informat category $70.;
	 format category $70.;
     merge temp1 &&Map_&i;
	  by bin;
	run;

	proc sort data=temp_v;
	 by VarName;
	run;

    proc sort data=&SCDS;
	 by VarName;
    run;

    data temp_all;
	 merge &&SCDS temp_v;
	  by VarName;
	run;

    Data &SCDS;
	  set temp_all;
	  drop &&B_&i;
	run;

%end;
/* Calculate the points and drop unnecessary varibles, 
   and setup the variable type for ease of generation of
   code: VarType 1 = continuous, 2=nominal string, 3=nominal numeric,
         0= Base Points */

data &SCDS;
  set &SCDS;
   if VarName = '_BasePoints_' then VarType=0;
   else do;
       Points=-WOE*ModelParameter * &beta ;
        if UL ne . and LL ne . then VarType=1;
          else if N_Category eq . then VarType=2;
	        else VarType=3;
	end;

/*   drop WOE bin ModelParameter;*/
	keep VarName UL LL Points WOE bin ModelParameter BinTotal VarType Category N_Category;

run;

proc sort data=&SCDS;
 by VarType VarName;
run;



/* clean up workspace */
proc datasets library=work nodetails;
delete temp1 temp_all temp_cont temp_mpt temp_mptc temp_v;
run; quit;



%mend;




/*******
  Credit Risk Scorecards: Development and Implementation using SAS
  (c)  Mamdouh Refaat
********/



/*******************************************************/
/* Macro SCSASCode */
/*******************************************************/
%macro SCSasCode(SCDS,BasePoints, BaseOdds, PDO, IntOpt,FileName);
/* writing the scorecard generated by the scorecard dataset to an output
  file FileName generating SAS code
  If The option IntOpt=1 then we convert the points to integer values
  otherwise they are left as numbers */

/* direct the output to the filename */

proc sort data=&SCDS;
by VarType VarName;
run;

data _null_;
set &SCDS nobs=nx;
by VarType VarName;
file "&FileName";
length cond $300.;
length value $300.;

if _N_ =1 then do;
	put '/*********************************************/' ;
	put '/*********************************************/';
	put '/***** Automatically Generated Scorecard *****/';
	put '/*********************************************/';
	put '/************    SAS CODE             ********/';
	put;
	put '/* Scorecard Scale : */';
	put "/*  Odds of [ 1 : &BaseOdds ] at  [ &BasePoints ] Points ";
    put "     with PDO of [ &PDO ] */";
	put; 
	put '/*********************************************/';
	put '/*********************************************/';
	put ;


	put '/********** START OF SCORING DATA STEP *******/';
	put '/*********************************************/';
	put '/*********************************************/';
	put;
	put 'DATA SCORING;        /********** Modify ************/';
	put ' SET ScoringDataset; /********** Modify ************/';
	put;
	put '/*********************************************/';
	put '/*********************************************/';
end; 

/* print the dataset RulesDS */


%if &IntOpt=1 %then xPoints=int(Points);
%else xPoints=Points; ;

if VarName="_BasePoints_" then do;
	put '/*********************************************/';
	put "/* Base Points   */";
	put '/*********************************************/';
put "Points=" xPoints ";";
                            end;
 else do;
   if first.VarName then do;
	put '/*********************************************/';
	put "/* Variable : " VarName "    *****/";
	put '/*********************************************/';
                      end;
    value= "  THEN  Points=Points +("||compress(xPoints)||");";

    /* The rule */
    if VarType=1 then  do;/* continuous */
	if first.VarName then  cond='IF '||compress(VarName)||' LE ('||compress(UL) || ') '; 
	else if last.VarName then cond='IF '||compress(VarName)||' GT ('|| compress(LL)||')';
    else cond='IF '||compress(VarName)||' GT ('|| compress(LL)||') AND '||compress(VarName)||' LE ('||compress(UL) || ') '; 
                       end; 
    else if VarType=2 then /* nominal string */
	cond = 'IF '||compress(VarName)||' = '|| quote(compress(Category)) ; 

	else /* nominal numeric */
	cond='IF '||compress(VarName)||' = ('|| compress(N_Category)||') '; 
	
	put "      " cond value;

 end;

 if _N_=Nx then do;
	put 'RUN;'; 
	put;
	put '/*************END OF SCORING DATA STEP *******/';
	put '/*********************************************/';
	end;
run;


%mend;



******************************************************************************;                                                                                                                                
*** Validation Application                                                 ***;                                                                                                                                 
******************************************************************************;   

/*******************************************************/
/* Macro: CalcWOE */
/*******************************************************/
%macro CalcWOE2(DsIn, IVVar, DVVar, WOEDS, WOEVar, DSout);
/*修改宏，把woeds固定为使用train生成的woe文件*/

/* Match the maps with the values and create the output
dataset */
proc sql noprint;
	create table &dsout as 
	select a.* , b.woe as &WOEvar from &dsin a, &WOEDS. b where a.&IvVar=b.&IvVar; 
quit;

%mend;



******************************************************************************;                                                                                                                                
*** Data Preparation                                                       ***;                                                                                                                                 
******************************************************************************;   

/*******************************************************/
/* Simple Replacement For Nominal Variables
/*******************************************************/

%macro ModeCat(DSin, Xvar, M_Mode);
/* Finding the mode of a string variable in a dataset */
%local _mode;
proc freq data=&DSin noprint order=freq;
tables &Xvar/out=Temp_Freqs;
run;
/* Remove the missing category if found */
data Temp_freqs;
set Temp_freqs;
if &Xvar='' then delete;
run;
/* Set the value of the macro variable _mode */
data Temp_Freqs;
set Temp_Freqs;
if _N_=1 then call symput('_mode',trim(&xvar));
run;
/* Set the output variable M_mode and clean the workspace */
%let &M_Mode=&_mode;
proc datasets library=work nodetails nolist;
delete Temp_Freqs;
quit;
%mend;

%macro SubCat(DSin, Xvar, Method, Value, DSout);
/*
Substitution of missing values in a nominal (String) variable
DSin: input dataset
Xvar: the string variable
Method: Method to be used:
1=Substitute mode
2=Substitute Value
3=Delete the record
Value: Used with Method
DSout: output dataset with the variable Xvar free of missing
values
*/
/* Option 1: Substitute the Mode */
%if &Method=1 %then %do;
/* calculate the mode using macro ModeCat */
%let mode=;
%ModeCat(&DSin, &Xvar, Mode);
/* substitute the mode whenever Xvar=missing */
Data &DSout;
Set &DSin;
if &Xvar='' Then &Xvar="&mode";
run;
%end;
/* Option 2: Substitute a user-defined value */
%else %if &Method=2 %then %do;
/* substitute the Value whenever Xvar=missing */
Data &DSout;
Set &DSin;
if &Xvar='' Then &Xvar="&Value";
run;
%end;
/* Option 3: (anything else) delete the record */
%else %do;
/* Delete record whenever Xvar=missing */
Data &DSout;
Set &DSin;
if &Xvar='' Then delete;
run;
%end;
%mend;


/*******************************************************/
/* Simple Replacement For Continuous And Ordinal Var
/*******************************************************/
%macro VarUnivar1(ds,varX, StatsDS);
proc univariate data=&ds noprint;
var &VarX;
output out=&StatsDS
N=Nx
Mean=Vmean
min=VMin
max=VMax
STD=VStd
VAR=VVar
mode=Vmode
median=Vmedia
P1=VP1
P5=VP5
P10=VP10
P90=VP90
P95=VP95
P99=VP99
;
run;
%mend;


/************************************************************
 *%SubCont功能：对单一变量的缺失值处理
 *DSin,DSout:输入输出数据集
 *XVar：待处理的变量
 *Value：填补的值
 *Method：方法
 ************************************************************/

%macro SubCont(DSin, Xvar, Method, Value, DSout);
/* Calculate the univariate measures */
%VarUnivar1(&DSin, &Xvar, Temp_univ);
/* Convert them into macro variables */
data _null_;
set Temp_univ;
Call symput('Mean' ,Vmean);
Call symput('min' ,VMin);
Call symput('max' ,VMax);
Call symput('STD' ,VStd);
Call symput('mode' ,Vmode);
Call symput('median',Vmedian);
Call symput('P1' ,VP1);
Call symput('P5' ,VP5);
Call symput('P10' ,VP10);
Call symput('P90' ,VP90);
Call symput('P95' ,VP95);
Call symput('P99' ,VP99);
run;
/* Substitute the appropriate value using the
specified option in the parameter 'Method' */
Data &DSout;
set &DSin;
%if %upcase(&Method)=DELETE %then %do;
if &Xvar=. then Delete;
%end;
%else %do;
if &Xvar=. then &Xvar=
%if %upcase(&Method)=MEAN %then &mean;
%if %upcase(&Method)=MIN %then &min;
%if %upcase(&Method)=MAX %then &max;
%if %upcase(&Method)=STD %then &std;
%if %upcase(&Method)=MODE %then &mode;
%if %upcase(&Method)=MEDIAN %then &median;
%if %upcase(&Method)=P1 %then &p1;
%if %upcase(&Method)=P5 %then &P5;
%if %upcase(&Method)=P10 %then &P10;
%if %upcase(&Method)=P90 %then &P90;
%if %upcase(&Method)=P95 %then &P95;
%if %upcase(&Method)=P99 %then &P99;
%if %upcase(&Method)=VALUE %then &Value;
%end;
run;
/* Finally, clean the workspace */
proc datasets library=work nolist nodetails;
delete temp_univ;
run; quit;
%mend;

%macro GiniStat(DSin, ProbVar, DVVar, DSLorenz, M_Gini);
/* Calculation of the Gini Statistic from the results of 
   a predictive model. DSin is the dataset with a dependent
   variable DVVar, and a predicted probability ProbVar. 
   The Gini coefficient is returnd in the parameter M_Gini. 
   DSLorenz contains the data of the Lorenz curve. 

*/

/* Sort the observations using the predicted Probability */
proc sort data=&DsIn;
by &ProbVar;
run;

/* Find the total number of responders */
proc sql noprint;
 select sum(&DVVar) into:NResp from &DSin;
 select count(*) into :NN from &DSin;
 quit;


 /* The base of calculation is 100  */

/* Get Count number of correct Responders per decile */
data &DSLorenz;
set &DsIn nobs=NN;
by &ProbVar;
retain tile 1  TotResp 0;
Tile_size=ceil(NN/100);

TotResp=TotResp+&DVVar;
TotRespPer=TotResp/&Nresp;

if _N_ = Tile*Tile_Size then 
  do;
  output;
   if Tile <100 then  
       do;
         Tile=Tile+1;
		 SumResp=0;
	   end;
  end;	
keep Tile TotRespPer;
run;
/* add the point of zero to the Lorenz data */
data temp;
 Tile=0;
 TotRespPer=0;
 run;
 Data &DSLorenz;
  set temp &DSLorenz;
run;


/* Scale the tile to represent percentage */
data &DSLorenz;
set &DSLorenz;
Tile=Tile/100;
label TotRespPer='Percent of Positives';
label Tile ='Percent of population';

run;

/* produce a simple plot of the Lorenze cruve the uniform response 
   if the IPlot is set to 1 */

/* Calculate the Gini coefficient from the approximation of the Lorenz
   curve into a sequence of straight line segments and using the 
   trapezoidal integration approximation.
   G=1 - Sum_(k=1)^(n)[X_k - X_(k-1)]*[Y_k + Y_(k-1)]
*/
data _null_; /* use the null dataset for the summation */
retain Xk 0 Xk1 0 Yk 0 Yk1 0 G 1;
set &DSLorenz;
Xk=tile;
Yk=TotRespPer;
G=G-(Xk-Xk1)*(Yk+Yk1);

/* next iteration */
Xk1=Xk;
Yk1=Yk;

/* output the Gini Coefficient */
call symput ('G', compress(G));
run;


/* store the Gini coefficient in the parameter M_Gini */

%let &M_Gini=&G;
/* Clean the workspace */
proc datasets library=work nodetails nolist;
 delete temp ;
run;
quit;

%mend;




GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
