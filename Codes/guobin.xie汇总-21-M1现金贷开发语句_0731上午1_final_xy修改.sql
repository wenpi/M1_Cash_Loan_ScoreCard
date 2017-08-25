----07.23下午1
--废表删除

--正式重跑语句  时间区间：2016.10.01-2017.07.21
---------------------------------------------------------------------------------
--------------01.数据样本代码201610-201612---------------------------------------
---------------------------------------------------------------------------------
---1.1 tmp_dcc.tm1m3_lf_xj_population_simple
---来源：01.数据样本代码,cs1.tm1m3_lf_xj_population_simple。
---修改by XGB
--------M1现金贷开发
--drop table tmp_dcc.tm1m3_lf_xj_population_simple;
--drop table tmp_dcc.tm1m3_lf_xj_population_simple_v1;
--drop table tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp;
create table tmp_dcc.tm1m3_lf_xj_population_simple as
select t.contract_no
       ,t.putout_date
       ,t.state_date
       ,t.acct_loan_no 
       ,t.customerid
       --,t.cs_cpd
from ods.overdue_contract t 
left join rcas.v_cu_risk_credit_summary t1
on t.contract_no = t1.contract_no 
where to_date(t.state_date) >= to_date('2016-10-01')
  and to_date(t.state_date) <= to_date('2017-07-21') 
  and t.cs_cpd = 1                                          --暂只取M1
  and t.is_presource+t.is_outsource=0
  and t1.sub_product_type in('1','2','3')
  and t1.data_source = 'AMAR'
  and t.customerid not in (select customerid from cs1.cs_blacklist where end_date is null)
  
select substr(state_date,1,7) as month1,cs_cpd,count(*) as num1 from tmp_dcc.tm1m3_lf_xj_population_simple group by substr(state_date,1,7),cs_cpd order by month1,cs_cpd

  
/*query Y value*/
--drop table tmp_dcc.tm1m3_lf_xj_population_simple_v1
create table tmp_dcc.tm1m3_lf_xj_population_simple_v1 
as
select tt.*
       ,nvl(tt1.cs_cpd,0) cpd
       ,nvl(tt1.cs_dpd,0) dpd
from (select t.*
             ,t1.DATE_DUE1
             ,CASE WHEN t.state_date = date_add(t1.DATE_DUE1,1) then 'FP'
                   ELSE 'nFP' END IS_FP
             ,date_add(t.state_date,30) Y_DATE
      from tmp_dcc.tm1m3_lf_xj_population_simple T
           ,RCAS.V_CU_RISK_CREDIT_SUMMARY T1
      WHERE T.CONTRACT_NO = T1.CONTRACT_NO
      ) tt
left join ods.overdue_contract tt1
on tt.contract_No = tt1.contract_no  and tt.y_date = tt1.state_date 

--select * from tmp_dcc.tm1m3_lf_xj_population_simple_v1 limit 100

---------------------------------------------------------------------------------
---1.1 tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp
---来源：01.数据样本代码,cs1.tm1m3_lf_xj_population_simple_v1_nfp。
---仅提取npf 案件
---修改by XGB
create table tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp
as
select *
from tmp_dcc.tm1m3_lf_xj_population_simple_v1 t
--where is_fp = 'nFP'  --注释掉本句取nFP FP目标用户

---------------------------------------------------------------------------------
---1.2 tmp_dcc.tm1m3_lf_xj_population_simple_v3_nfp
---来源：01.数据样本代码,cs1.tm1m3_lf_xj_population_simple_v3_nfp。
---修改by XGB
---仅提取npf 案件
------仅提取over_due_value,n_cur_balance
create table tmp_dcc.tm1m3_lf_xj_population_simple_v3_nfp
as
select t.*,'M1' as phase,t1.over_due_value over_due_value_v0,t1.n_cur_balance n_cur_balance_v0
from tmp_dcc.tm1m3_lf_xj_population_simple_v1 t,
ods.overdue_contract t1
--where is_fp = 'nFP'   --注释掉本句取nFP FP目标用户
where t.state_date=t1.state_date
and t.contract_no=t1.contract_no

select substr(state_date,1,7) as month1,is_fp,count(*) from tmp_dcc.tm1m3_lf_xj_population_simple_v3_nfp group by substr(state_date,1,7),is_fp order by month1,is_fp

---------------------------------------------------------------------------------
---1.3 tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp
---来源：01.数据样本代码,cs1.tm1m3_lf_xj_population_simple_v2_nfp。
---修改by XGB
---提取over_due_value
---建立主键表
--drop table tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp 
create table tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp 
as
select t.contract_no
       ,t.putout_date
       ,t.state_date 
       ,t.customerid
       ,t.date_due1
       ,t.is_fp
       ,t.cpd
       ,t.dpd
       ,t1.contract_No p_contract_no
       ,t1.acct_loan_no 
       ,t1.loan_amount credit_amount
       ,t1.settle_date
       ,t1.installment_cancel_time
       ,case when t1.settle_date is null then '0' 
             when t1.settle_date < t.state_date then t1.loan_status
             else '0'
        end loan_stat_his
       ,case when t1.installment_cancel_time is null then '0' 
             when t1.installment_cancel_time < t.state_date then '1'
             else '0' end is_cancel_his
from tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp t,
(
  select XX1.* 
  from ods.loan_acct XX1,
       (
       select acct_loan_no,loan_amount,putout_date,contract_no,max(etl_in_dt) as etl_in_dt 
       from ods.loan_acct a1 
       group by acct_loan_no,loan_amount,putout_date,contract_no
  ) XX2
  where XX1.acct_loan_no=XX2.acct_loan_no AND XX1.loan_amount=XX2.loan_amount AND XX1.putout_date=XX2.putout_date AND XX1.contract_no=XX2.contract_no AND XX1.etl_in_dt=XX2.etl_in_dt
)     t1
where t.customerid=t1.customer_id 
      and t1.putout_date < t.state_date
      
select substr(state_date,1,7) as month1,count(*) from tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp group by substr(state_date,1,7) order by month1      

---------------------------------------------------------------------------------
---1.4 tmp_dcc.tm1m3_lf_xj_population_new
---来源：01.数据样本代码,cs1.tm1m3_lf_xj_population_new。
---修改by XGB
---增加over_due,n_balance,phase
--drop table tmp_dcc.tm1m3_lf_xj_population_new
create table tmp_dcc.tm1m3_lf_xj_population_new  as
select 'M1' as phase
       ,t.*
       ,t1.over_due_value
       ,t1.n_cur_balance
from tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp t
left join ods.overdue_contract t1
on t.p_contract_no=t1.contract_no
and t.state_date=t1.state_date

select substr(state_date,1,7) as month1,count(*) from tmp_dcc.tm1m3_lf_xj_population_new group by substr(state_date,1,7) order by month1 

--create table tmp_dcc.lf_xj_population_new_16  as select * from tmp_dcc.tm1m3_lf_xj_population_new t
--where to_date(t.state_date) >= to_date('2016-10-01')
--  and to_date(t.state_date) <= to_date('2016-12-31')

---------------------------------------------------------------------------------
--------------02.申请信息代码----------------------------------------------------
---------------------------------------------------------------------------------
---2.1 tmp_dcc.tm1m3_lf_xj_population_temp1
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_population_temp1
---修改by XGB
---建中间表取SA历史分组
create table tmp_dcc.tm1m3_lf_xj_population_temp1 
as
select CONTRACT_NO
       , PUTOUT_DATE
       , STATE_DATE
       , CUSTOMERID
       , ACCT_LOAN_NO
       , max(case when CREATE_TIME = putout_sa then sa_rgroup else null end) as putout_sagroup
from (
select t.*
               ,t1.SA_ID
               ,t2.SA_RGROUP
               ,to_date(t2.CREATE_TIME) as CREATE_TIME
               ,max(case when putout_date>t2.create_time then to_date(t2.create_time) else null end) over() as putout_sa
               ,max(case when state_date>t2.create_time then to_date(t2.create_time) else null end) over() as state_sa
        from tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp t
        LEFT JOIN rcas.v_cu_risk_credit_summary t1 on t.contract_no = t1.CONTRACT_NO
        LEFT JOIN rcas.v_risk_group_sa_his t2 on t1.SA_ID = t2.SA_ID ) as c
group by CONTRACT_NO
       , PUTOUT_DATE
       , STATE_DATE 
       , CUSTOMERID
       , ACCT_LOAN_NO
;
       
---------------------------------------------------------------------------------
---2.2 tmp_dcc.tm1m3_lf_xj_population_temp2
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_population_temp2
---修改by XY
---建中间表取SA个人信息
create table  tmp_dcc.tm1m3_lf_xj_population_temp2 as  
SELECT distinct t.contract_no
							 ,t2.fdiploma sa_education 
							 ,t2.fwed sa_familystate
							 ,t3.mark SA_area
from (
select tm.contract_no,tn.sa_id 
		 from  tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp tm,rcas.v_cu_risk_credit_summary tn
     where tm.contract_no=tn.CONTRACT_NO) t
     left join s1.user_info t1 on t.sa_id=t1.userid
     left join RCAS.V_S5_SA_INFO t2 on t1.workid=t2.fnumber
     left join tmp_dcc.certseq_area t3  
     on substr(t1.certid,1,2)=t3.province 
     and substr(t1.certid,3,2)=t3.city 
     and substr(t1.certid,5,2)=t3.d_istrict
;

---------------------------------------------------------------------------------
---2.3 tmp_dcc.tm1m3_lf_xj_population_temp3
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_population_temp3
---修改by XY
---重新取POS点以及SA过去表现变量（宽表当中的t3表）
---添加计算标示
create table tmp_dcc.tm1m3_lf_xj_population_temp3 as  
select t.CONTRACT_NO
       ,t.CITY
       ,t.POS_CODE
       ,t.APP_DATE
       ,t.INTER_CODE
       ,t.DEF_FPD30
       ,t.AGR_FPD30
       ,t.CREDIT_AMOUNT
       ,t.SA_ID
       ,case when t.STATUS_EN in ('020','050','110') then 1
             when (t.STATUS_EN='160' and datediff(self_date_format(t1.finishdate),self_date_format(t1.putoutdate))>15) then 1
             else 0 end is_performace
       ,case when t.STATUS_EN in('010','020','040','050','080','090','110','120','160') then 1 else 0 end is_app
       ,case when t.STATUS_EN in('020','040','050','080','090','110','120','160') then 1 else 0 end  is_apr
from rcas.v_cu_risk_credit_summary t join s1.acct_loan t1 on
			t.CONTRACT_NO = t1.putoutno
 			 and t.STATUS_EN in('010','020','040','050','080','090','110','120','160')
 			 and t.LOAN_TYPE='030'
;  
  
---------------------------------------------------------------------------------
---2.4 tmp_dcc.tm1m3_lf_xj_population_temp4
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_population_temp4
---修改by XY
---计算SA以及POS点历史表现  
---这一部分没有生成完整
create table tmp_dcc.tm1m3_lf_xj_population_temp4 as
select t.CONTRACT_NO
       ,t.CITY
       ,t.POS_CODE                                                                                                             
from   tmp_dcc.tm1m3_lf_xj_population_temp3  t
;

---------------------------------------------------------------------------------
---2.5 tmp_dcc.tm1m3_lf_xj_zp_t5
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_zp_t5
---修改by XY
---t5表 上传照片信息表
create table tmp_dcc.tm1m3_lf_xj_zp_t5
(	  OBJECTNO    STRING, 
 		BANK_INFO_IMAGE    STRING, 
 		WORK_IMAGE   STRING, 
 		SSI_IMAGE    STRING, 
		DRIVER_IMAGE    STRING,
 		REG_IMAGE    STRING, 
 		LIVE_IMAGE   STRING, 
		 PROPERTY_IMAGE    STRING
)
;

insert into tmp_dcc.tm1m3_lf_xj_zp_t5
select t.objectno 
       ,max(oracle_decode(t.typename,'银行卡正面(POS回单）' ,1, '银行卡背面' ,1, '银行卡对账单' ,1, 0)) as bank_info_image,
       max(oracle_decode (t.typename,'工卡', 1,0 )) as work_image,
       max(oracle_decode (t.typename,'社保卡', 1,'社保网站截图' ,1, 0)) as ssi_image,
       max(oracle_decode (t.typename,'驾驶证', 1,0 )) as driver_image,
       max(oracle_decode (t.typename,'户口本', 1,0 )) as reg_image,
       max(oracle_decode (t.typename,'居住证', 1,0 )) as live_image,
       max(oracle_decode (t.typename,'财产所有权证明', 1,0))  as Property_image
from (select  a.Objectno as objectno,T1.TYPENAME as typename FROM s1.ECM_IMAGE_TYPE  T1 JOIN s1.ECM_PAGE a ON T1.TYPENO=a.TYPENO) t
group by t.objectno
;


---------------------------------------------------------------------------------
---2.6 tmp_dcc.tm1m3_lf_xj_APPLICATION
---来源：02.申请信息代码,cs1.tm1m3_lf_xj_APPLICATION
---修改by XY
---------- 贷前申请信息表 ----------
---首先，根据tmp_dcc.tm1m3_lf_xj_info_tmp1,tmp2,tmp3生成tm1m3_tmp_xy_info子表
create table tmp_dcc.tm1m3_lf_xj_info_tmp1 as
select   t1.customerid,
	       itemname as family_state from s1.code_library t2, s1.ind_info t1  
	       where t2.codeno='Marriage' and t2.itemno=t1.marriage
;

create table tmp_dcc.tm1m3_lf_xj_info_tmp2 as
select   t3.customerid,
	       itemname as education from s1.code_library t4, s1.ind_info t3  
	       where t4.codeno='EducationExperience' and t4.itemno=t3.EduExperience
;

create table tmp_dcc.tm1m3_lf_xj_info_tmp3 as
select   t5.customerid,
		     itemname as other_person_type from s1.code_library t6, s1.ind_info t5  
		     where t6.codeno='RelativeAccountOther' and t6.itemno=t5.Contactrelation
;

create table tmp_dcc.tm1m3_tmp_xy_info as
select TT.*
		from (
		select t1.customerid
       		,t1.family_state
       		,t2.education
      	  ,t3.other_person_type                                                                  
		from tmp_dcc.tm1m3_lf_xj_info_tmp1        t1    
		left join tmp_dcc.tm1m3_lf_xj_info_tmp2   t2       
		     on t1.customerid=t2.customerid
		left join tmp_dcc.tm1m3_lf_xj_info_tmp3   t3                        
		     on t2.customerid=t3.customerid	     
)TT
;

------------------------------------
---然后生成贷前申请信息表 
---tmp_dcc.tm1m3_lf_xj_APPLICATION
---修改by XY
---有很多字段未生成
------------------------------------
create table tmp_dcc.tm1m3_lf_xj_APPLICATION
as
select distinct ttt.*
	from (
	select tt.contract_no
		    ,tt.id_credit   
        ,tt.STATUS_EN
        ,tt.person_sex                                                          ---1、性别
        ,floor(datediff(self_date_format(t2.inputdate),getbirthday(tt.cert_seq))/365) as  person_app_age  ---2、申请者年龄S
        ,t3.family_state                                                        ---3、婚姻状态
        ,t3.education														    ---4、教育程度
        ,t3.other_person_type                                                   ---5、 其他联系人    
        ,tt.city                                                                ---8、城市
	,tt.province                                                            ---9、省份
        ,self_date_format(t2.inputdate)  app_date                               ---2.申请日期
        ,round(tt.credit_amount,2)     credit_amount                            ---2、贷款金额
        ,tt.init_pay                                                            ---4、首付金额                                                                   
        ,t2.CreditCycle IS_insure                                               ---8、是否投保
        ,t2.Periods                                                             ---10、分期还款期数
        ,tk.shoufuratio          min_init_Rate                                  ---15、产品最低首付比例
        ,tt.price                                                               ---6、商品价格
        ,oracle_decode(t1.Falg4,'2','0','1','1',null)  IS_SSI                   ---5、是否社保
        ,t1.Severaltimes  last_app_num                                          ---10、过去本公司申请过几次贷款
        ,t1.alimony expense_month                                               ---2、月支出
        ,t1.otherrevenue other_income                                           ---3、其他收入
        ,t1.familymonthincome family_income                                     ---4、家庭月收入
        ,t1.Childrentotal                                                       ---1、子女个数
       
	from tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp    k --来自1数据样本表
	left join rcas.v_cu_risk_credit_summary        tt--主档表
     on k.contract_no=tt.CONTRACT_NO
	left join s1.business_type                     tk--dbeaver产品类型表
     on tt.prod_code = tk.typeno   
	left join tmp_dcc.tm1m3_tmp_xy_info                  t3--生成信息表
		     on TT.id_person=T3.customerid	          
	left join s1.ind_info                          t1--dbeaver客户信息表
     on TT.id_person=T1.customerid
join s1.business_contract_cu                     t2--dbeaver合同信息表
     on TT.CONTRACT_NO=T2.SERIALNO
) ttt
;



---------------------------------------------------------------------------------
--------------03审核信息代码 暂不跑-------------------------------------------------
---------------------------------------------------------------------------------



---------------------------------------------------------------------------------
--------------04.还款信息代码----------------------------------------------------
---------------------------------------------------------------------------------
---4.1 tmp_dcc.tm1m3_lf_xj_behavior_base1
---首先生成子表 tmp_dcc.tm1m3_lf_xj_behavior_base1_pre
---来源：04.还款信息代码,cs1.tm1m3_lf_xj_behavior_base1
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_behavior_base1_pre as
select a1.contract_no, a1.acct_loan_no ,a1.p_contract_no,a1.n_cur_balance n_cur_balance1,a1.putout_date,a1.state_date as state_date1,
       a2.state_date, a2.cs_cpd, a2.cs_dpd, a2.f_bucket, a2.cpd_date, a3.app_date, a3.CREDIT_AMOUNT,
       max(case when cs_cpd>0 then 1 else 0 end) over(partition by a1.contract_no,a1.acct_loan_no,a1.p_contract_no, a1.state_date, a2.cpd_date) as cpd1
from tmp_dcc.tm1m3_lf_xj_population_new as a1 left join ods.overdue_contract as a2 on a1.acct_loan_no = a2.acct_loan_no   
     left join rcas.v_cu_risk_credit_summary as a3 on a1.p_contract_no=a3.contract_no
where a1.state_date >= a2.state_date    ------在历史参考点之前
;

--drop table tmp_dcc.tm1m3_lf_xj_behavior_base1
create table tmp_dcc.tm1m3_lf_xj_behavior_base1 as 
select contract_no,state_date, max(max_cpd) as max_cpd, sum(his_delaydays) as his_delaydays, 
       max(avg_days) as avg_days,sum(delay_days) as delay_days, max(delay_days_rate) as delay_days_rate
from
(
  select contract_no,state_date1 as state_date,p_contract_no,APP_DATE,CREDIT_AMOUNT,
         ------逾期表整合数据
         max(cs_cpd) as max_cpd , ----历史最大逾期cs_cpd
         sum(case when cpd1=1 and cs_cpd <> 0 then 1 else 0 end) as his_delaydays, --历史处于延滞阶段的天数,
         oracle_decode(sum(case when cs_cpd=1 then 1 else 0 end) ,0,0,
           sum(case when cpd1=1 and cs_cpd <> 0 then 1 else 0 end)/sum(case when cs_cpd=1 then 1 else 0 end)) as avg_days,---平均每次逾期停留天数     ----5天起算？
         sum(case when cpd1=1 AND cs_cpd <> 0 then 1 else 0 end) as delay_days,
         sum(case when cpd1=1 AND cs_cpd <> 0 then 1 else 0 end)/datediff(state_date1,to_date(APP_DATE)) as delay_days_rate ----历史延滞天数/账龄天数
  from tmp_dcc.tm1m3_lf_xj_behavior_base1_pre
  group by contract_no,state_date1,p_contract_no,APP_DATE,CREDIT_AMOUNT
) b
group by contract_no,state_date
;

---------------------------------------------------------------------------------
---4.2 tmp_dcc.tm1m3_lf_xj_behavior_base2
---首先生成子表 tmp_dcc.tm1m3_lf_xj_behavior_base22
---来源：04.还款信息代码,cs1.tm1m3_lf_xj_behavior_base2
---修改by LPY
create table tmp_dcc.tm1m3_lf_xj_behavior_base22  as
select  contract_no,state_date,acct_loan_no,psserialno,paytype,
        min(payprincipalamt) as payprincipalamt,
        max(case when actualpaydate<state_date then pay_num else 0 end) as pay_num,        --还款次数
        sum(case when actualpaydate<state_date then actualpayprincipalamt else 0 end) as actualpayprincipalamt,
        sum(case when actualpaydate<state_date then actualpayinteamt else 0 end) as actualpayinteamt
        from 
	(select contract_no,state_date,a1.acct_loan_no ,paytype,payprincipalamt,payinteamt,
			row_number() over(partition by contract_no,state_Date,psserialno order by actualpaydate) as rn,
	        dense_rank() over(partition by contract_no,state_Date order by actualpaydate) as pay_num,
	         psserialno,paydate,actualpaydate,actualpayprincipalamt,actualpayinteamt
	from tmp_dcc.tm1m3_lf_xj_population_new a1 LEFT join
		(
		select acct_loan_no ,
			(case when aps.paytype = 'A10' and aps.serialno like 'XF2016%' then to_date(self_date_format(substr(aps.serialno,3,8)))---补
				  WHEN aps.paytype = 'A10' and aps.serialno like 'XF%' then hive_date_format(concat('20',substr(aps.serialno,3,6)),'yyyyMMdd')
			      when aps.paytype = 'A10' and aps.serialno like 'T%' then hive_date_format(substr(aps.serialno,2,8),'yyyyMMdd')
			      when aps.paytype = 'A10' then hive_date_format(substr(aps.serialno,1,8),'yyyyMMdd')
			      else to_date(self_date_format(aps.paydate)) end) as paydate,
			      aps.paytype,aps.payprincipalamt,aps.payinteamt,apl.psserialno,
			to_date(self_date_format(apl.actualpaydate)) as actualpaydate,apl.actualpayprincipalamt,apl.actualpayinteamt
		from s1.acct_payment_schedule aps LEFT JOIN
		     s1.acct_payment_log apl ON aps.serialno=apl.psserialno 
		) a4  -------连应还实还表
	 on a1.acct_loan_no = a4.acct_loan_no 
	where a1.state_date >  a4.paydate
	and  a1.state_date >  a4.actualpaydate
	) a
group by contract_no,state_date,acct_loan_no,psserialno,paytype;

---然后根据tmp_dcc.tm1m3_lf_xj_behavior_base22生成tmp_dcc.tm1m3_lf_xj_behavior_base2
---修改by LPY
create table tmp_dcc.tm1m3_lf_xj_behavior_base2  as 
select  contract_no , 
        state_date ,
        max(pay_num) as pay_num, --还款次数    
        sum(oracle_nvl(actualpayprincipalamt,0)) + sum(oracle_nvl(actualpayinteamt,0)) as pay_total, --总还款金额
        sum(case when paytype = '1' then actualpayprincipalamt else 0 end) as pay_principal, --累积还本金金额
        sum(case when paytype = '1' then actualpayinteamt else 0 end) as pay_interest, --累积还利息金额
        sum(case when paytype = 'A2' then actualpayprincipalamt else 0 end) as pay_service_fee, --累积还客服费用
        sum(case when paytype = 'A7' then actualpayprincipalamt else 0 end) as pay_finance_fee, --累积还财管费用
        sum(case when paytype = 'A10' and actualpayprincipalamt>0 then 1 else 0 end) as pay_delay_num, --累积还滞纳金次数
        sum(case when paytype = 'A10' then actualpayprincipalamt else 0 end) as pay_delay_fee, --累积还滞纳金金额
        sum(case when paytype = 'A10' and payprincipalamt = 30 and actualpayprincipalamt>0 then 1 else 0 end) as pay_delay10_num, --累积还10天滞纳金次数
        sum(case when paytype = 'A10' and payprincipalamt = 30 then actualpayprincipalamt else 0 end) as pay_delay10_fee, --累积还10天滞纳金金额
        sum(case when paytype = 'A10' and payprincipalamt = 80 and actualpayprincipalamt>0 then 1 else 0 end) as pay_delay30_num, --累积还30天滞纳金次数
        sum(case when paytype = 'A10' and payprincipalamt = 80 then actualpayprincipalamt else 0 end) as pay_delay30_fee, --累积还30天滞纳金金额
        sum(case when paytype = 'A10' and payprincipalamt = 100 and actualpayprincipalamt>0 then 1 else 0 end) as pay_delay60_num, --累积还60天滞纳金次数
        sum(case when paytype = 'A10' and payprincipalamt = 100 then actualpayprincipalamt else 0 end) as pay_delay60_fee, --累积还60天滞纳金金额
        sum(case when paytype = 'A10' and payprincipalamt = 160 and actualpayprincipalamt>0 then 1 else 0 end) as  pay_delay90_num, --累积还90天滞纳金次数
        sum(case when paytype = 'A10' and payprincipalamt = 160 then actualpayprincipalamt else 0 end) as pay_delay90_fee, --累积还90天滞纳金金额
        sum(case when paytype = 'A12' then actualpayprincipalamt else 0 end) as pay_addservice_fee, --累积还增值服务费用
        sum(case when paytype = 'A18' then actualpayprincipalamt else 0 end) as pay_random_fee, --累积还随心还费用
        sum(case when paytype <> '1' then oracle_nvl(actualpayprincipalamt,0) + oracle_nvl(actualpayinteamt,0) else 0 end) as pay_total_fee--累积还费用金额*
from tmp_dcc.tm1m3_lf_xj_behavior_base22 group by contract_no ,state_date;


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---4.3 tmp_dcc.lf_xj_behavior_base4
---首先生成子表 tmp_dcc.lf_xj_behavior_base4_pre
---来源：04.还款信息代码,cs1.lf_xj_behavior_base4
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_behavior_base4_pre AS
select m.acct_loan_no ,m.contract_no,m.p_contract_no,m.state_date,
       to_date(self_date_format(aps.paydate)) as paydate,aps.seqid,aps.paytype,aps.payprincipalamt,aps.payinteamt,apl.psserialno,
       max(to_date(self_date_format(apl.actualpaydate))) as actualpaydate,
       sum(apl.actualpayprincipalamt) as actualpayprincipalamt,
       sum(apl.actualpayinteamt) as actualpayinteamt
from tmp_dcc.tm1m3_lf_xj_population_new m
  left join s1.acct_payment_schedule aps on m.acct_loan_no = aps.acct_loan_no
  left join s1.acct_payment_log apl on aps.serialno=apl.psserialno
where aps.paytype='1'
  and m.state_date >to_date(self_date_format(aps.paydate))
  and apl.actualpaydate is not null
  and m.state_date >to_date(self_date_format(apl.actualpaydate))
group by m.acct_loan_no ,m.contract_no,m.p_contract_no,m.state_date,to_date(self_date_format(aps.paydate)),
         aps.seqid,aps.paytype,aps.payprincipalamt,aps.payinteamt,apl.psserialno
;

---修改by ZDY
---然后根据tmp_dcc.tm1m3_lf_xj_behavior_base4_pre生成tmp_dcc.tm1m3_lf_xj_behavior_base4
create table tmp_dcc.tm1m3_lf_xj_behavior_base4 as 
select contract_no,state_date,
       max(max_due1) as max_condue,---历史最大连续逾期期数
       sum(con_due_times) as con1_due_times,--历史连续逾期次数
       max(max_due10) as max_condue10,---历史最大连续逾期10天的期数
       sum(con10_due_times) as con10_due_times,--历史连续逾期10天的次数     
       max(max_due30) as max_condue30,---历史最大连续逾期30天的期数
       sum(con30_due_times) as con30_due_times,--历史连续逾期30天的次数   
        
       max(sixmax_due1) as six_condue,---6个月内最大连续逾期期数
       sum(sixcon_due_times) as sixcon1_due_times,--6个月内连续逾期次数
       max(sixmax_due10) as six_condue10,---6个月内最大连续逾期10天的期数
       sum(sixcon10_due_times) as sixcon10_due_times,--6个月内连续逾期10天的次数   
       max(sixmax_due30) as six_condue30,---6个月内最大连续逾期30天的期数
       sum(sixcon30_due_times) as sixcon30_due_times,--6个月内连续逾期30天的次数   
               
       max(due_num) as due_num, --到期期次
       sum(his_dueseq) as his_dueseq,
       sum(six_perpay) as six_perpay,
       sum(twe_perpay) as twe_perpay,
       sum(six_inpay) as six_inpay,------增
       sum(twe_inpay) as twe_inpay,
       sum(six_fullpay) as six_fullpay,
       sum(twe_fullpay) as twe_fullpay,
       sum(six_pay) as six_pay,
       sum(twe_pay) as twe_pay,
       sum(six_due) as six_due,
       sum(twe_due) as twe_due,
       --max(num_delay) as num_delay,       --到期期次欠款状态
       sum(is10fine) as is10fine,
       sum(is30fine) as is30fine,
       sum(is60fine) as is60fine,
       sum(is90fine) as is90fine,
       sum(pay5to10) as pay5to10,--增
       sum(seq_duedays) as seq_duedays--增

from 
(
select  contract_no,state_date,p_contract_no,
        flag1,flag10,flag30,sixflag1,sixflag10,sixflag30,
        sum(case when con_due1=2 then 1 else 0 end) as con_due_times,
        sum(case when con_due10=2 then 1 else 0 end) as con10_due_times,
        sum(case when con_due30=2 then 1 else 0 end) as con30_due_times,
        sum(case when sixcon_due1=2 then 1 else 0 end) as sixcon_due_times,
        sum(case when sixcon_due10=2 then 1 else 0 end) as sixcon10_due_times,
        sum(case when sixcon_due30=2 then 1 else 0 end) as sixcon30_due_times,
        max(con_due1) as max_due1,
        max(con_due10) as max_due10,
        max(con_due30) as max_due30,
        max(sixcon_due1) as sixmax_due1,
        max(sixcon_due10) as sixmax_due10,
        max(sixcon_due30) as sixmax_due30,
        max(seqid) as due_num,
        sum(is_due1) as his_dueseq,
        sum(six_perpay) as six_perpay,
        sum(twe_perpay) as twe_perpay,
        sum(six_inpay) as six_inpay,------增
        sum(twe_inpay) as twe_inpay,
        sum(six_fullpay) as six_fullpay,
        sum(twe_fullpay) as twe_fullpay,
        sum(six_pay) as six_pay,
        sum(twe_pay) as twe_pay,
        sum(six_due) as six_due,
        sum(twe_due) as twe_due,
        --max(num_delay) as num_delay,
        --max(pay_dd)PAY_DD,
        max(is10fine) as is10fine,
        max(is30fine) as is30fine,
        max(is60fine) as is60fine,
        max(is90fine) as is90fine,
        max(pay5to10) as pay5to10,
        max(seq_duedays) as seq_duedays
        
from (
select contract_no,state_date,p_contract_no,flag1,flag10,flag30,sixflag1,sixflag10,sixflag30,
       seqid,is_due1,seq_duedays,
       sum(is_due1) over (partition by contract_no,p_contract_no,state_date,flag1 order by seqid) as con_due1,
       sum(is_due10) over (partition by contract_no,p_contract_no,state_date,flag10 order by seqid) as con_due10,
       sum(is_due30) over (partition by contract_no,p_contract_no,state_date,flag30 order by seqid) as con_due30,
       sum(six_due1) over (partition by contract_no,p_contract_no,state_date,sixflag1 order by seqid) as sixcon_due1,
       sum(six_due10) over (partition by contract_no,p_contract_no,state_date,sixflag10 order by seqid) as sixcon_due10,
       sum(six_due30) over (partition by contract_no,p_contract_no,state_date,sixflag30 order by seqid) as sixcon_due30,
       six_perpay,
       twe_perpay,
       six_inpay,------增
       twe_inpay,
       six_fullpay,
       twe_fullpay,
       six_pay,
       twe_pay,
       six_due,
       twe_due,
       --num_delay ,
       is10fine,
       is30fine,
       is60fine,
       is90fine,
       pay5to10                   
from (

select contract_no,state_date,p_contract_no,seqid,paydate,
       --listagg(num_delay,',')within group(order by seqid)over(partition by contract_no,p_contract_no,state_date) as num_delay,
       is_due1,is_due10,is_due30,
       six_due1,six_due10,six_due30,seq_duedays,
       sum(flag1) over (partition by contract_no,p_contract_no,state_date order by seqid) as flag1,
       sum(flag10) over (partition by contract_no,p_contract_no,state_date order by seqid) as flag10,
       sum(flag30) over (partition by contract_no,p_contract_no,state_date order by seqid) as flag30,
       sum(sixflag1) over (partition by contract_no,p_contract_no,state_date order by seqid) as sixflag1,
       sum(sixflag10) over (partition by contract_no,p_contract_no,state_date order by seqid) as sixflag10,
       sum(sixflag30) over (partition by contract_no,p_contract_no,state_date order by seqid) as sixflag30,
       six_perpay,
       twe_perpay,
       six_inpay,------增
       twe_inpay,
       six_fullpay,
       twe_fullpay,
       six_pay,
       twe_pay,
       six_due,
       twe_due,
       is10fine,
       is30fine,
       is60fine,
       is90fine,
       pay5to10      

from(
select        
       contract_no,p_contract_no,seqid,state_date,
       paydate,actualpaydate,
       (case when seq_duedays>0 then seq_duedays else 0 end) as seq_duedays,
       --is_due,--lag(is_due)over(partition by acct_loan_no order by paydate) lag_due
       --1-is_due flag,
       case when seq_duedays>0 then 1 else 0 end as is_due1,
       1-case when seq_duedays>0 then 1 else 0 end as flag1,
       case when seq_duedays>9 then 1 else 0 end as is_due10,
       1-case when seq_duedays>9 then 1 else 0 end as flag10,
       case when seq_duedays>29 then 1 else 0 end as is_due30,
       1-case when seq_duedays>29 then 1 else 0 end as flag30,
       
       case when oracle_months_between(state_date,paydate)<=6 and seq_duedays>0 then 1 else 0 end as six_due1,
       1-case when oracle_months_between(state_date,paydate)<=6 and seq_duedays>0 then 1 else 0 end as sixflag1,
       case when  oracle_months_between(state_date,paydate)<=6 and seq_duedays>9 then 1 else 0 end as six_due10,
       1-case when  oracle_months_between(state_date,paydate)<=6 and seq_duedays>9 then 1 else 0 end as sixflag10,
       case when  oracle_months_between(state_date,paydate)<=6 and seq_duedays>29 then 1 else 0 end as six_due30,
       1-case when  oracle_months_between(state_date,paydate)<=6 and seq_duedays>29 then 1 else 0 end as sixflag30,
       
       case when seq_duedays=0
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=6 then 1 else 0 end as six_perpay,
       case when seq_duedays=0
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=12 then 1 else 0 end as twe_perpay,       
            
       case when seq_duedays<=1
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=6 then 1 else 0 end as six_inpay,
       case when seq_duedays<=1
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=12 then 1 else 0 end as twe_inpay,             
                 
       case when fullback=1 
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=6 then 1 else 0 end as six_fullpay,
       case when fullback=1 
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<= 12 then 1 else 0 end as twe_fullpay,           
       case when actualpaydate is not null
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=6 then 1 else 0 end as six_pay,  
       case when actualpaydate is not null
            and  oracle_months_between(state_date,actualpaydate)>0
            and  oracle_months_between(state_date,actualpaydate)<=12 then 1 else 0 end as twe_pay,  
       case when  oracle_months_between(state_date,paydate)<=6 then 1 else 0 end as six_due,       
       case when  oracle_months_between(state_date,paydate)<=12 then 1 else 0 end as twe_due,
       
       --case when seq_duedays>90 then 4 when seq_duedays>60 then 3 when seq_duedays>30 then 2
            --when seq_duedays>=1 then 1 else 0 end num_delay ,
       
       is10fine,
       is30fine,
       is60fine,
       is90fine,
       pay5to10
       
from 
(
select a.contract_no,a.p_contract_no,a.state_date,paydate,seqid,actualpaydate,
       case when state_Date>actualpaydate and date_add(paydate,10)>actualpaydate and datediff(date_add(paydate,10),actualpaydate)<=3 then 1 else 0 end as is10fine,
       case when state_Date>actualpaydate and date_add(paydate,30)>actualpaydate and datediff(date_add(paydate,30),actualpaydate)<=3 then 1 else 0 end as is30fine,
       case when state_Date>actualpaydate and date_add(paydate,60)>actualpaydate and datediff(date_add(paydate,60),actualpaydate)<=3 then 1 else 0 end as is60fine,
       case when state_Date>actualpaydate and date_add(paydate,90)>actualpaydate and datediff(date_add(paydate,90),actualpaydate)<=3 then 1 else 0 end as is90fine,
       case when state_Date>actualpaydate and date_add(paydate,10)>actualpaydate and datediff(date_add(paydate,10),actualpaydate)<=5 then 1 else 0 end as pay5to10,
       case when 
            oracle_nvl(actualpayprincipalamt,0) + oracle_nvl(actualpayinteamt,0)
            -oracle_nvl(payprincipalamt,0)-oracle_nvl(payinteamt,0)=0 then 1 else 0 end as fullback,--经过上一级加工后方正确
       case when actualpaydate is null or actualpaydate>state_date
            then datediff(state_date,paydate) 
            when oracle_nvl(actualpayprincipalamt,0) + oracle_nvl(actualpayinteamt,0)
                 -oracle_nvl(payprincipalamt,0)-oracle_nvl(payinteamt,0)<0
            then datediff(state_date,paydate)
            else datediff(actualpaydate,paydate) end as seq_duedays ---截至统计日，期次逾期天数
from tmp_dcc.tm1m3_lf_xj_behavior_base4_pre a -------连应还实还表
) a7
) a8
) a9
) a10
group by contract_no,state_date,p_contract_no,
         flag1,flag10,flag30,sixflag1,sixflag10,sixflag30,seqid
) b
group by contract_no,state_date
; 

--select contract_no,state_date,seq_duedays 
--from tmp_dcc.tm1m3_lf_xj_behavior_base4 
--where contract_no in ('10503597002','10500862002','10503940002','11777066004','14093072003','19121150002','32329765002','71372466002')
--      and state_date < '2016-12-31'
--order by contract_no,state_date;
--
--select * from tmp_dcc.tm1m3_lf_xj_behavior_base4 limit 100;


---------------------------------------------------------------------------------
---4.4 tmp_dcc.tm1m3_lf_xj_behavior_base
---还款信息汇总
---来源：04.还款信息代码,cs1.tm1m3_lf_xj_behavior_base
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_behavior_base as 
select 
        t1.*
       ,t2.PAY_DELAY_FEE
       ,t2.PAY_DELAY_NUM
       ,t4.MAX_CONDUE10
       ,t4.CON10_DUE_TIMES
       ,t4.SEQ_DUEDAYS

from tmp_dcc.tm1m3_lf_xj_behavior_base1 t1,
     tmp_dcc.tm1m3_lf_xj_behavior_base2 t2,
     tmp_dcc.tm1m3_lf_xj_behavior_base4 t4
where t1.contract_no=t2.contract_no
  and t1.state_date=t2.state_date
  and t1.contract_no=t4.contract_no
  and t1.state_date=t4.state_date
;   

select count(*) from tmp_dcc.tm1m3_lf_xj_behavior_base


---------------------------------------------------------------------------------
--------------05.回退信息代码----------------------------------------------------
---------------------------------------------------------------------------------
---5.1 tmp_dcc.tm1m3_lf_xj_back
---来源：05.还款信息代码,cs1.tm1m3_lf_xj_xj_back,第1行-30行代码。
---修改by XGB
create table tmp_dcc.tm1m3_lf_xj_back as          --此表用在 8信息整合用到
select contract_no,state_date,
       sum(case when roll_back>0 then 1 else 0 end) back,
       sum(case when add_months(state_date,-6)<full_date and roll_back>0 then 1 else 0 end) six_back,--回跳次数
       sum(case when add_months(state_date,-12)<full_date and roll_back>0 then 1 else 0 end) twe_back,
       max(case when roll_back>0 then roll_back else 0 end) max_back_seq,
       max(case when add_months(state_date,-6)<full_date and roll_back>0 then roll_back else 0 end) sixmax_back_seq,--最大回跳期数
       max(case when add_months(state_date,-12)<full_date and roll_back>0 then roll_back else 0 end) twemax_back_seq,
       sum(case when roll_back>0 then roll_back else 0 end) back_seq,
       sum(case when add_months(state_date,-6)<full_date and roll_back>0 then roll_back else 0 end) six_back_seq,--回跳期数
       sum(case when add_months(state_date,-12)<full_date and roll_back>0 then roll_back else 0 end) twe_back_seq
      
from 
(
  select K1.contract_no,k1.state_date,k1.p_contract_no,full_date,f_bucket,
         substr(NVL(K2.F_BUCKET,bucket),2,1)-lead(substr(NVL(K2.F_BUCKET,bucket),2,1)) over (partition by k1.contract_no,k1.p_contract_no,k1.state_date order by full_date) roll_back
  
  from 
    (select a1.phase,a1.contract_no,a1.state_date,a1.p_contract_no,a2.state_date full_date,a2.bucket
       from tmp_dcc.tm1m3_lf_xj_population_new a1,
               tmp_dcc.lf_xj_cs_day_temp a2
       where date_add(a1.putout_date,30)<a2.state_date   ------在历史参考点之前
       and a1.state_date>a2.state_date
    ) K1
    left join ods.overdue_contract K2
    on K1.p_contract_no=K2.contract_no and K1.full_date=K2.state_date   
) XX1
group by contract_no,state_date


---------------------------------------------------------------------------------
---5.2 tmp_dcc.tm1m3_lf_xj_roll1
---首先生成子表 tmp_dcc.tm1m3_lf_xj_roll123
---然后生成子表 tmp_dcc.tm1m3_lf_xj_roll12
---最后生成 tmp_dcc.tm1m3_lf_xj_roll1
---来源：05.还款信息代码,cs1.tm1m3_lf_xj_roll1
---首先生成子表tmp_dcc.tm1m3_lf_xj_roll123
---修改by LPY
--来自5回退信息代码，生成tmp_dcc.tmp1m3_lf_xj_roll123
--DROP TABLE tmp_dcc.tmp1m3_lf_xj_roll123;
--来自5回退信息代码，生成tmp_dcc.tm1m3_lf_xj_roll123
--来自5回退信息代码，生成tmp_dcc.tm1m3_lf_xj_roll123
--DROP TABLE tmp_dcc.tm1m3_lf_xj_roll123;
CREATE TABLE tmp_dcc.tm1m3_lf_xj_roll123 as 
select acct_loan_no,state_date,actualpaydate as actualpaydate from (
	select acct_loan_no,state_date,seqid,
		to_date(self_date_format(paydate)) as paydate,to_date(self_date_format(actualpaydate)) as actualpaydate,
	case when oracle_nvl(actualpayprincipalamt,0) + oracle_nvl(actualpayinteamt,0)
          -oracle_nvl(payprincipalamt,0) -oracle_nvl(payinteamt,0)=0 then 1 else 0 end as payback
from
	(		
	select m.acct_loan_no,m.state_date ,aps.seqid,aps.paydate,psserialno,APS.payprincipalamt,APS.payinteamt,
	sum(apl.actualpayprincipalamt)actualpayprincipalamt,sum(apl.actualpayinteamt)actualpayinteamt,max(apl.actualpaydate)actualpaydate
	from tmp_dcc.tm1m3_lf_xj_population_new m
	left join
	s1.acct_payment_schedule aps
	on m.acct_loan_no = aps.acct_loan_no	
	left join
	s1.acct_payment_log apl
	on aps.serialno=apl.psserialno
	WHERE apl.actualpaydate is not null
	and m.state_date >to_date(self_date_format(apl.actualpaydate))
	and aps.paytype='1'
	and m.state_date >to_date(self_date_format(aps.paydate))
	group by m.acct_loan_no,m.state_date,aps.seqid,aps.paydate,psserialno,APS.payprincipalamt,APS.payinteamt
	) m1)m2
	where payback=1;


--来自5回退信息代码，由tmp_dcc.tm1m3_lf_xj_roll123生成tmp_dcc.tm1m3_lf_xj_roll12
--drop TABLE tmp_dcc.tm1m3_lf_xj_roll12;
create table tmp_dcc.tm1m3_lf_xj_roll12 as 
select a1.acct_loan_no,a1.STATE_DATE,a1.contract_no,a1.p_contract_no,a1.PAYDATE,a1.seqid,oracle_months_between(a1.STATE_DATE,a1.PAYDATE) as month,
       a1.seqid-sum(case when a2.acct_loan_no is not null and a1.paydate>=a2.actualpaydate then 1 else 0 end) as ROLL_BACK_FLAG       
from 
	(select L2.ACCT_LOAN_NO,L2.STATE_DATE,l2.contract_no,l2.p_contract_no,L1.SEQID,L1.PAYDATE from 
		(
		select acct_loan_no,aps.seqid,to_date(self_date_format(aps.paydate)) as paydate
		from s1.acct_payment_schedule aps
		where aps.paytype='1'
		)L1 RIGHT JOIN tmp_dcc.tm1m3_lf_xj_population_new L2
	 on l2.acct_loan_no=L1.acct_loan_no WHERE l2.state_date>=L1.paydate
	)A1 LEFT JOIN
	(
	SELECT a11.* from tmp_dcc.tm1m3_lf_xj_roll123 a11 JOIN(
		SELECT acct_loan_no,state_date,max(actualpaydate) as actualpaydate FROM tmp_dcc.tm1m3_lf_xj_roll123 GROUP BY acct_loan_no, state_date) a12
		on a11.acct_loan_no=a12.acct_loan_no and a11.state_date=a12.state_date AND a11.actualpaydate=a12.actualpaydate 
	)A2
on a1.acct_loan_no=a2.acct_loan_no AND a1.state_date=a2.state_date
group by a1.acct_loan_no,a1.STATE_DATE,a1.contract_no,a1.p_contract_no,a1.seqid,a1.PAYDATE; 

--来自5回退信息代码，由tmp_dcc.tm1m3_lf_xj_roll12生成tmp_dcc.tm1m3_lf_xj_roll1
--DROP TABLE tmp_dcc.tm1m3_lf_xj_roll1;
create table tmp_dcc.tm1m3_lf_xj_roll1 as
select state_date,contract_no,
       case when max(last_roll-roll_back_flag)<0 then 0 else max(last_roll-roll_back_flag) end as max_roll_Seq,
       sum(case when last_roll-roll_back_flag<0 then 0 else last_roll-roll_back_flag end) as roll_seq,
       sum(case when last_roll-roll_back_flag>0 then 1 else 0 end) as roll_time,

       case when max(sixlast_roll-sixroll_flag)<0 then 0 else max(sixlast_roll-sixroll_flag) end as sixmaxroll_Seq,
       sum(case when sixlast_roll-sixroll_flag<0 then 0 else sixlast_roll-sixroll_flag end) as sixroll_seq,
       sum(case when sixlast_roll-sixroll_flag>0 then 1 else 0 end) as sixroll_time,
       
       case when max(twelast_roll-tweroll_flag)<0 then 0 else max(twelast_roll-tweroll_flag) end as twemaxroll_Seq,
       sum(case when twelast_roll-tweroll_flag<0 then 0 else twelast_roll-tweroll_flag end) as tweroll_seq,
       sum(case when twelast_roll-tweroll_flag>0 then 1 else 0 end) as tweroll_time       
from 
(select T.acct_loan_no,
       t.state_date,
       t.contract_no,
       t.p_contract_no,
       t.roll_back_flag,
       oracle_nvl(lag(roll_back_flag) over(partition by acct_loan_no,state_Date order by seqid),0) as last_roll,
       t.seqid,
       case when month>6 then 0 else roll_back_flag end as sixroll_flag,
       case when month>6 then 0 else oracle_nvl(lag(roll_back_flag) over(partition by acct_loan_no,state_Date order by seqid),0) end as sixlast_roll,
       case when month>=12 then 0 else roll_back_flag end as tweroll_flag,
       case when month>=12 then 0 else oracle_nvl(lag(roll_back_flag) over(partition by acct_loan_no,state_Date order by seqid),0) end as twelast_roll
from tmp_dcc.tm1m3_lf_xj_roll12 t) b group by state_date,contract_no;

--来自5回退信息代码，tmp_dcc.tm1m3_lf_xj_roll123生成tmp_dcc.tm1m3_lf_xj_roll22
--DROP TABLE tmp_dcc.tm1m3_lf_xj_roll22;
CREATE TABLE tmp_dcc.tm1m3_lf_xj_roll22 AS
select a1.acct_loan_no,a1.STATE_DATE,a1.contract_no,a1.p_contract_no,a1.seqid,
       a1.seqid-sum(case when a2.acct_loan_no is not null and a1.paydate>=a2.actualpaydate then 1 else 0 end) as ROLL_BACK_FLAG
from 
	(select L2.ACCT_LOAN_NO,L2.STATE_DATE,l2.contract_no,l2.p_contract_no,L1.SEQID,L1.PAYDATE from 
		(
		select acct_loan_no,aps.seqid,
		to_date(self_date_format(aps.paydate)) as paydate
		from s1.acct_payment_schedule aps
		where aps.paytype='1'
		)L1 right JOIN
	tmp_dcc.tm1m3_lf_xj_population_new L2 
	on l2.acct_loan_no=L1.acct_loan_no WHERE l2.state_date>=L1.paydate
	) A1 LEFT JOIN
	(
	SELECT a11.* from tmp_dcc.tm1m3_lf_xj_roll123 a11 JOIN(
		SELECT acct_loan_no,state_date,max(actualpaydate) as actualpaydate FROM tmp_dcc.tm1m3_lf_xj_roll123 GROUP BY acct_loan_no, state_date) a12
		on a11.acct_loan_no=a12.acct_loan_no and a11.state_date=a12.state_date AND a11.actualpaydate=a12.actualpaydate 
	) A2
ON a1.acct_loan_no=a2.acct_loan_no AND a1.state_date=a2.state_date
group by a1.acct_loan_no,a1.STATE_DATE,a1.contract_no,a1.p_contract_no,a1.seqid;

--来自5回退信息代码，tmp_dcc.tm1m3_lf_xj_roll22生成tmp_dcc.tm1m3_lf_xj_roll2
--DROP TABLE tmp_dcc.tm1m3_lf_xj_roll2;
create table tmp_dcc.tm1m3_lf_xj_roll2 as 
select STATE_DATE,contract_no
from tmp_dcc.tm1m3_lf_xj_roll22 GROUP BY STATE_DATE,contract_no;

--来自5回退信息代码，tmp_dcc.tm1m3_lf_xj_roll1和tmp_dcc.tm1m3_lf_xj_roll2，生成tmp_dcc.tm1m3_lf_xj_roll
--DROP TABLE tmp_dcc.tm1m3_lf_xj_roll;
create table tmp_dcc.tm1m3_lf_xj_roll as 
select t2.* from 
tmp_dcc.tm1m3_lf_xj_roll2 t1 LEFT JOIN
tmp_dcc.tm1m3_lf_xj_roll1 t2
ON t1.contract_no=t2.contract_no
  and t1.state_date=t2.state_date;
  
--select count(*) from tmp_dcc.tm1m3_lf_xj_rol
--select * from tmp_dcc.tm1m3_lf_xj_roll where contract_no in ('10503597002','14093072003','71372466002')


---------------------------------------------------------------------------------
--------------06.催收信息代码----------------------------------------------------
---------------------------------------------------------------------------------
---6.1 tmp_dcc.tm1m3_lf_xj_collection_base1
---来源：06.催收信息代码,cs1.tm1m3_lf_xj_collection_base1。
---修改by XGB
--本sql一共生成3张表 tmp_dcc.tm1m3_lf_xj_collection_base1 tmp_dcc.tm1m3_lf_xj_collection_base2 再合并为tmp_dcc.tm1m3_lf_xj_collection_base
create table tmp_dcc.tm1m3_lf_xj_collection_base1 as 
select QQ1.*,NVL(QQ2.KPTP,0)KPTP,NVL(QQ2.KPRO,0)KRPO,
       NVL(QQ2.M1_KPTP,0)M1_KPTP,NVL(QQ2.M1_KPRO,0)M1_KPRO,
       NVL(QQ2.M2_KPTP,0)M2_KPTP,NVL(QQ2.M2_KPRO,0)M2_KPRO,
       NVL(QQ2.M3_KPTP,0)M3_KPTP,NVL(QQ2.M3_KPRO,0)M3_KPRO,
       QQ1.PTP-NVL(QQ2.KPTP,0)BPTP,QQ1.PROMISE-NVL(QQ2.KPRO,0)BPRO, 
       QQ1.M1_PTP-NVL(QQ2.M1_KPTP,0) M1_BPTP,QQ1.M1_PROMISE-NVL(QQ2.M1_KPRO,0) M1_BPRO,
       QQ1.M2_PTP-NVL(QQ2.M2_KPTP,0) M2_BPTP,QQ1.M2_PROMISE-NVL(QQ2.M2_KPRO,0) M2_BPRO,
       QQ1.M3_PTP-NVL(QQ2.M3_KPTP,0) M3_BPTP,QQ1.M3_PROMISE-NVL(QQ2.M3_KPRO,0) M3_BPRO
from 
  (
    select contract_no,state_date,
    sum(cuishou_times)cs_times,
    sum(vaild)vaild,
    sum(contact)contact,
    sum(lost)lost,
    max(con_lost)con_lost,
    sum(promise)promise,
    sum(ptp)ptp,
    sum(cptp)cptp,
    sum(optp)optp,
    sum(FNBM_times)FNBM_times,
    sum(INCM_times)INCM_times,
    sum(pro_days)pro_days,
    sum(pro_sum)pro_sum,
    sum(ptp_days)ptp_days,
    sum(ptp_sum)ptp_sum,
    sum(case when f_bucket='M1' then vaild else 0 end) m1_vaild,
    sum(case when f_bucket='M1' then contact else 0 end) m1_contact,
    sum(case when f_bucket='M1' then lost else 0 end) m1_lost,
    sum(case when f_bucket='M1' then promise else 0 end) m1_promise,
    sum(case when f_bucket='M1' then ptp else 0 end) m1_ptp,
    sum(case when f_bucket='M1' then optp else 0 end) m1_optp,
    sum(case when f_bucket='M1' then cptp else 0 end) m1_cptp,
    sum(case when f_bucket='M1' then FNBM_times else 0 end) m1_FNBM_times,
    sum(case when f_bucket='M1' then INCM_times else 0 end) m1_INCM_times,
    sum(case when f_bucket='M1' then pro_days else 0 end) m1_pro_days,
    sum(case when f_bucket='M1' then pro_sum else 0 end) m1_pro_sum,
    sum(case when f_bucket='M1' then ptp_days else 0 end) m1_ptp_days,
    sum(case when f_bucket='M1' then ptp_sum else 0 end) m1_ptp_sum,
    sum(case when f_bucket='M1' then cuishou_times else 0 end) m1_cstimes,
    sum(case when f_bucket='M2' then vaild else 0 end) M2_vaild,
    sum(case when f_bucket='M2' then contact else 0 end) M2_contact,
    sum(case when f_bucket='M2' then lost else 0 end) M2_lost,
    sum(case when f_bucket='M2' then promise else 0 end) M2_promise,
    sum(case when f_bucket='M2' then ptp else 0 end) M2_ptp,
    sum(case when f_bucket='M2' then optp else 0 end) m2_optp,
    sum(case when f_bucket='M2' then cptp else 0 end) m2_cptp,
    sum(case when f_bucket='M2' then FNBM_times else 0 end) M2_FNBM_times,
    sum(case when f_bucket='M2' then INCM_times else 0 end) M2_INCM_times,
    sum(case when f_bucket='M2' then pro_days else 0 end) M2_pro_days,
    sum(case when f_bucket='M2' then pro_sum else 0 end) M2_pro_sum,
    sum(case when f_bucket='M2' then ptp_days else 0 end) m2_ptp_days,
    sum(case when f_bucket='M2' then ptp_sum else 0 end) m2_ptp_sum,
    sum(case when f_bucket='M2' then cuishou_times else 0 end) M2_cstimes,  
    sum(case when f_bucket='M3' then vaild else 0 end) M3_vaild,
    sum(case when f_bucket='M3' then contact else 0 end) M3_contact,
    sum(case when f_bucket='M3' then lost else 0 end) M3_lost,
    sum(case when f_bucket='M3' then promise else 0 end) M3_promise,
    sum(case when f_bucket='M3' then ptp else 0 end) M3_ptp,
    sum(case when f_bucket='M3' then optp else 0 end) m3_optp,
    sum(case when f_bucket='M3' then cptp else 0 end) m3_cptp,
    sum(case when f_bucket='M3' then FNBM_times else 0 end) M3_FNBM_times,
    sum(case when f_bucket='M3' then INCM_times else 0 end) M3_INCM_times,
    sum(case when f_bucket='M3' then pro_days else 0 end) M3_pro_days,
    sum(case when f_bucket='M3' then pro_sum else 0 end) M3_pro_sum,
    sum(case when f_bucket='M3' then ptp_days else 0 end) m3_ptp_days,
    sum(case when f_bucket='M3' then ptp_sum else 0 end) m3_ptp_sum,
    sum(case when f_bucket='M3' then cuishou_times else 0 end) M3_cstimes
    
    from  
    (
      select 
      customerid,contract_no,state_date,F_BUCKET,
      sum(case when executorcode in ('PTP','CPTP','OPTP','PWTR','CMLM')then 1 else 0 end)vaild,                          ---有效次数
      sum(case when executorcode in ('PTP','CPTP','OPTP','FNBM','PWTR','ORLM','CWOC','CMLM','APPO','INCM','FOUP')
               then 1 else 0 end)contact,                                                                                ---可联次数
      sum(case when executorcode in ('CMNA','UNLO','POOF','CMCU','MONM','MRAN','CMBY','ONSP')
               then 1 else 0 end)lost,                                                                                   ---失联次数         
      sum(case when executorcode in ('PTP','CPTP','PWTR')then 1 else 0 end)promise,                                      ---承诺还款次数
      sum(case when executorcode='PTP' then 1 else 0 end)ptp,                                                            ---PTP次数
      sum(case when executorcode='CPTP' then 1 else 0 end)cptp,                                                          ---CPTP次数/来电承诺还款次数
      sum(case when executorcode='OPTP' then 1 else 0 end)optp,                                                          ---OPTP次数/他人承诺还款次数
      sum(oracle_decode(executorcode,'FNBM',1,0)) FNBM_times,                                                            ---财务困难次数
      sum(oracle_decode(executorcode,'INCM',1,0)) INCM_times,                                                            ---来电次数
      sum(case when executorcode in ('PTP','CPTP','PWTR')then cast(promisrepaymentdate as double) else 0 end)pro_days,
      sum(case when executorcode in ('PTP','CPTP','PWTR')then cast(promisrepaymentsum as double) else 0 end)pro_sum,
      sum(case when executorcode ='PTP' then cast(promisrepaymentdate as double) else 0 end)ptp_days,
      sum(case when executorcode ='PTP' then cast(promisrepaymentsum as double) else 0 end)ptp_sum,
      sum(case when serialno is not null then 1 else 0 end)cuishou_times,
      max(con_lost)con_lost
      FROM
      (
      select W.*,sum(lost1)over(partition by contract_no,state_date,flag1)con_lost
      from
        (
          select m.customerid,m.contract_no,m.state_date,m.F_BUCKET,
                 n.executorcode,n.serialno,n.promisrepaymentsum,n.promisrepaymentdate,n.input_date,n.inputdate,
          case when executorcode in ('CMNA','UNLO','POOF','CMCU','MONM','MRAN','CMBY','ONSP') then 1 else 0 end lost1,
          sum(1-(case when executorcode in ('CMNA','UNLO','POOF','CMCU','MONM','MRAN','CMBY','ONSP')
          then 1 else 0 end))over(partition by contract_no,state_date order by inputdate)flag1
          
          from
            (
              select contract_no,state_date,customerid,flag4,f_bucket,
              min(state_date0)state_sdate,max(state_date0)state_edate,datediff(max(state_date0),min(state_date0)) m_days
              from 
              ( 
                select k.*,sum(flag2)over(partition by acct_loan_no,state_date order by state_date0)flag4
                from 
                (    
                  select  A1.contract_no,A1.acct_loan_no,A1.state_date,A1.customerid,A2.f_bucket,a2.STATE_DATE STATE_DATE0,
                          oracle_decode(cs_cpd,1,1,31,1,61,1,0) flag2
                  from  
                    tmp_dcc.tm1m3_lf_xj_population_new a1
                    left join ods.overdue_contract a2 on a1.acct_loan_no=a2.acct_loan_no 
                  where a1.state_date>a2.state_date
                    and a2.cs_cpd>0
                ) K
              ) XX1
              group by  contract_no,state_date,customerid,flag4,f_bucket
            )    M
            left join
            (select a7.*,regexp_replace(substr(inputdate,1,10),'/','-') input_date
            from S1.CONSUME_COLLECTIONREGIST_INFO a7
            where inputdate is not null
            )    N  on M.customerid=N.customerid
          where 
            M.state_sdate<=input_date
            and M.state_edate>=input_date
        ) W
      ) XX2
      group by customerid,contract_no,state_date,F_BUCKET
    ) XX3
    GROUP BY CONTRACT_NO,STATE_DATE
  ) QQ1
  
    left join 
  (
    select ab.CONTRACT_NO,AB.STATE_DATE,
         sum(case when AB.F_BUCKET='M1' and executorcode ='PTP' and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)m1_kptp,
         sum(case when AB.F_BUCKET='M1' and executorcode in ('PTP','CPTP','PWTR') and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)m1_kpro,
         sum(case when AB.F_BUCKET='M2' and executorcode ='PTP' and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)M2_kptp,
         sum(case when AB.F_BUCKET='M2' and executorcode in ('PTP','CPTP','PWTR') and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)M2_kpro,
         sum(case when AB.F_BUCKET='M3' and executorcode ='PTP' and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)M3_kptp,
         sum(case when AB.F_BUCKET='M3' and executorcode in ('PTP','CPTP','PWTR') and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)M3_kpro,
         sum(case when executorcode ='PTP' and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)kptp,
         sum(case when executorcode in ('PTP','CPTP','PWTR') and nvl(CD.OVER_DUE_VALUE,0)<50 then 1 else 0 end)kpro
   from 
    (
     select M.*,N.executorcode,N.input_date,N.recheck_date from                                              
      ( select contract_no,state_date,customerid,flag4,f_bucket,                                                       
            min(state_date0)state_sdate,max(state_date0)state_edate,datediff(max(state_date0),min(state_date0)) m_days                                             
       from                                                                                                     
       (                                                                                                        
        select K.*,sum(flag2) over(partition by acct_loan_no,state_date order by state_date0) flag4                
        from                                                                                                     
         (                                                                                                        
          select  A1.contract_no,A1.acct_loan_no,A1.state_date,A1.customerid,A2.f_bucket,a2.STATE_DATE STATE_DATE0,
              oracle_decode(cs_cpd,1,1,31,1,61,1,0) flag2                                                              
          from                                                                                                     
            tmp_dcc.cscore_population_new a1                                                                            
            left join ods.overdue_contract a2   on a1.acct_loan_no=a2.acct_loan_no                                                              
          where a1.state_date>a2.state_date and a2.cs_cpd>0                                                                                        
         ) K
       ) YY1  
       group by  contract_no,state_date,customerid,flag4,f_bucket                                               
      ) M,

      (select a7.*,regexp_replace(substr(inputdate,1,10),'/','-') input_date,regexp_replace(substr(recheckdate,1,10),'/','-') recheck_date
         from S1.CONSUME_COLLECTIONREGIST_INFO a7                                                                 
         where executorcode in ('PTP','CPTP','PWTR')                                                                                                                                       
      ) N                                                                                                      
      where M.customerid=N.customerid  and M.state_sdate<=input_date  and M.state_edate>=input_date                                                                          
    ) ab 

    left join 
    (select k.*,cast(k.state_date as string) statedate from  ods.overdue_contract k) cd
      on ab.contract_no=cd.contract_no and ab.recheck_date=cd.statedate
      group by  ab.CONTRACT_NO,AB.STATE_DATE
  ) QQ2
on QQ1.CONTRACT_NO=QQ2.CONTRACT_NO AND QQ1.STATE_DATE=substr(QQ2.STATE_DATE,1,10)  

select * from tmp_dcc.tm1m3_lf_xj_collection_base1 limit 100

---------------------------------------------------------------------------------
---6.2 tmp_dcc.tm1m3_lf_xj_collection_base2
---来源：06.催收信息代码,cs1.tm1m3_lf_xj_collection_base2。
---修改by XGB
---近三个月催收信息
create table tmp_dcc.tm1m3_lf_xj_collection_base2 as
select 
  customerid,contract_no,state_date,
  sum(case when serialno is not null then 1 else 0 end)thrmon_cstimes,
  sum(vaild)thrmon_vaild,         ---有效次数
  sum(contact)thrmon_contact,     ---可联次数
  sum(RPC)thrmon_RPC,               
  sum(promise)thrmon_promise,     ---承诺还款次数
  sum(ptp)thrmon_ptp,             ---PTP次数
  sum(Cptp)thrmon_cptp,           ---CPTP次数/来电承诺还款次数
  sum(Optp)thrmon_optp,           ---OPTP次数/他人承诺还款次数
  sum(FNBM) thrmon_FNBM_times,    ---财务困难次数
  sum(INCM) thrmon_INCM_times,    ---来电次数
  sum(prodays)thrmon_prodays,
  sum(prosum)thrmon_prosum,
  sum(ptpdays)thrmon_ptpdays,
  sum(ptpsum)thrmon_ptpsum,
  max(con_lost)thrmon_conlost,
  SUM(lost1)thrmon_lost,
  datediff(state_Date,max(case when lost1=0 THEN INPUT_DATE ELSE NULL END))   lost_day ,
  datediff(state_Date,max(INPUT_DATE))                                        nocall_day ,
  datediff(state_Date,max(case when RPC=1 THEN INPUT_dATE ELSE NULL END))     norpc_day,
  datediff(state_date,max(case when promise=1 then input_date else null end)) nopro_day,
  oracle_decode(sum(case when serialno is not null then 1 else 0 end),0,null,sum(promise)/sum(case when serialno is not null then 1 else 0 end)) ptp_rate,
  oracle_decode(sum(contact),0,null,sum(promise)/sum(contact))PTP_CONTACT
FROM
(
  select W.*,sum(lost1)over(partition by contract_no,state_date,flag1)con_lost,
         case when executorcode in ('PTP','CPTP','OPTP','PWTR','CMLM') then 1 else 0 end vaild,
         case when executorcode in ('PTP','CPTP','OPTP','FNBM','PWTR','ORLM','CWOC','CMLM','APPO','INCM','FOUP') then 1 else 0 end contact,
         case when executorcode in ('CPTP','PTP','OPTP','FNBM','PWTR','COWC','APPO') then 1 else 0 end RPC,
         (case when executorcode in ('PTP','CPTP','PWTR') then 1 else 0 end) promise,
         (case when executorcode='PTP' then 1 else 0 end) ptp,
         (case when executorcode='CPTP' then 1 else 0 end) CPTP,
         (case when executorcode='OPTP' then 1 else 0 end) OPTP,
         oracle_decode(executorcode,'FNBM',1,0) FNBM,  ---财务困难次数
         oracle_decode(executorcode,'INCM',1,0) INCM,  ---来电次数
         case when executorcode in ('PTP','CPTP','PWTR')then cast(promisrepaymentdate as double) else 0 end prodays,
         case when executorcode in ('PTP','CPTP','PWTR')then cast(promisrepaymentsum as double) else 0 end prosum,
         case when executorcode ='PTP' then cast(promisrepaymentdate as double) else 0 end ptpdays,
         case when executorcode ='PTP' then cast(promisrepaymentsum as double) else 0 end  ptpsum
  
  from
    (
      select m.customerid,m.contract_no,m.state_date,
             n.executorcode,n.serialno,n.promisrepaymentsum,n.promisrepaymentdate,n.input_date,n.inputdate,
             case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end lost1,
             sum(1-(case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end)) over(partition by contract_no,state_date order by inputdate)flag1
      FROM tmp_dcc.tm1m3_lf_xj_population_new  M
      left join
        (select a7.*,regexp_replace(substr(inputdate,1,10),'/','-') input_date
         from S1.CONSUME_COLLECTIONREGIST_INFO a7
         where inputdate is not null
        ) N           on M.customerid=N.customerid
      where 
        M.state_date>=input_date
        and ADD_MONTHS(TO_DATE(M.state_date),-3)<=regexp_replace(substr(inputdate,1,10),'/','-')    --input_date 格式2016/08/30 14:49:08
    ) w
) YY1
group by customerid,contract_no,state_date

select * from tmp_dcc.tm1m3_lf_xj_collection_base2 limit 100
        
---------------------------------------------------------------------------------
---6.3 tmp_dcc.tm1m3_lf_xj_collection_base
---来源：06.催收信息代码,cs1.tm1m3_lf_xj_collection_base。
---修改by XGB
---整合
create table tmp_dcc.tm1m3_lf_xj_collection_base as
select t1.*,
  t2.THRMON_CSTIMES,
  t2.THRMON_VAILD,
  t2.THRMON_CONTACT,
  t2.THRMON_RPC,
  t2.THRMON_PROMISE,
  t2.THRMON_PTP,
  t2.THRMON_CPTP,
  t2.THRMON_OPTP,
  t2.THRMON_FNBM_TIMES,
  t2.THRMON_INCM_TIMES,
  t2.THRMON_PRODAYS,
  t2.THRMON_PROSUM,
  t2.THRMON_PTPDAYS,
  t2.THRMON_PTPSUM,
  t2.THRMON_CONLOST,
  t2.THRMON_LOST,
  t2.LOST_DAY,
  t2.NOCALL_DAY,
  t2.NORPC_DAY,
  t2.NOPRO_DAY,
  t2.PTP_RATE,
  t2.PTP_CONTACT
from 
  tmp_dcc.tm1m3_lf_xj_collection_base1 t1,
  tmp_dcc.tm1m3_lf_xj_collection_base2 t2
where t1.contract_no=t2.contract_no
  and t1.state_date=t2.state_date
  
select * from tmp_dcc.tm1m3_lf_xj_collection_base limit 100  




---------------------------------------------------------------------------------
--------------07客户维度信息代码 暂不跑----------------------------------------------
---------------------------------------------------------------------------------




---------------------------------------------------------------------------------
--------------08.整合信息模块----------------------------------------------------
---------------------------------------------------------------------------------
---8.1 tmp_dcc.tm1m3_lf_xj_back
---来源：08.整合信息模块
---修改by XGB
--drop table tmp_dcc.tm1m3_lf_xj_new_m1
create table tmp_dcc.tm1m3_lf_xj_new_m1 as
select 
t1.*,
--t2.STATE_TIME,
--t2.ID_CREDIT,
--t2.APP_MONTH,
--t2.APP_WEEKEND,
--t2.APP_DATE,
--t2.STATUS_EN,
--t2.INNER_CODE,
t2.CREDIT_AMOUNT CREDIT_AMOUNT_v0,
--t2.INIT_PAY,
--t2.IS_HOLIDAYS,
--t2.IS_DD,
t2.IS_INSURE,
--t2.PAYMENT_RATE,
--t2.PERIODS,
--t2.OPENBANK,
--t2.PROD_CODE,
--t2.MIN_INIT_RATE,
--t2.EXTRA_INIT_RATE,
--t2.GOODS_COUNT,
--t2.GOODS_TYPE,
--t2.PRODUCTCATEGORYNAME,
--t2.BRANDTYPE,
--t2.GOODS_CODE,
--t2.PRICE,
t2.PERSON_SEX,
t2.PERSON_APP_AGE,
t2.FAMILY_STATE,
t2.EDUCATION,
t2.IS_SSI,
--t2.CERTF_EXP,
--t2.CERTF_INTERVAL_YEARS,
--t2.CERTF_AUTH,
--t2.LAST_APP_NUM,
--t2.ID_PERSON,
--t2.CERT_6_INITAL,
--t2.CUSTOMER_BIRTH,
--t2.PERSON_NAME,
--t2.IS_HAN,
--t2.NATIONALITY,
--t2.NATIVE_CITY,
--t2.EMP_NAME,
--t2.COMPANY_TYPE,
--t2.JOBTIME,
--t2.INDUSTRY,
--t2.DEPARTMENT,
--t2.POSITION,
--t2.TOTAL_WK_EXP,
--t2.LAST3YEAR_WORKCHANGE_NUM,
--t2.HOUSE_TYPE,
--t2.EXPENSE_MONTH,
--t2.OTHER_INCOME,
--t2.FAMILY_INCOME,
t2.CHILDRENTOTAL,
--t2.QQNO,
--t2.QQ_LENGTH,
--t2.EMAIL,
--t2.F_SAME_REG,
--t2.IS_CERTID_PROVINCE,
--t2.RELATIVE_TYPE,
t2.OTHER_PERSON_TYPE,
--t2.RELATIVE_TEL_TYPE,
--t2.CONTACT_TEL_TYPE,
--t2.RELATIVEADD_SAME_REG,
--t2.WECHAT,
--t2.KINSHIPTEL,
--t2.CONTACTTEL,
--t2.TEL_NO,
--t2.F_SAME_MAI,
--t2.F_SAME_COM,
--t2.BANK_INFO_IMAGE,
--t2.WORK_IMAGE,
--t2.SSI_IMAGE,
--t2.DRIVER_IMAGE,
--t2.REG_IMAGE,
--t2.LIVE_IMAGE,
--t2.PROPERTY_IMAGE,
--t2.COMPETITOR,
--t2.OPERATEMODE,
--t2.POS_TYPE,
--t2.POS_CODE,
t2.PROVINCE,
t2.CITY,
--t2.INNER3_USE_RATE60_POS,
--t2.INNER3_USE_RATE60_SA,
--t2.INNER3_USE_COUNT_POS,
--t2.INNER3_USE_COUNT_SA,
--t2.POS_PRE60_APP_COUNT,
--t2.POS_PRE60_APP_APROVE_COUNT,
--t2.POS_PRE30_APP_COUNT,
--t2.POS_PRE30_APP_APROVE_COUNT,
--t2.POS_PRE30_APR_RATE,
--t2.POS_PRE60_APR_RATE,
--t2.SA_ID,
--t2.SA_SEX,
--t2.SA_APP_AGE,
--t2.SA_PRE60_APP_COUNT,
--t2.SA_PRE60_APP_APROVE_COUNT,
--t2.SA_PRE30_APP_COUNT,
--t2.SA_PRE30_APP_APROVE_COUNT,
--t2.SA_PRE30_APR_RATE,
--t2.SA_PRE60_APR_RATE,
--t2.POS_AVG_CREAMOUNT,
--t2.SA_AVG_CREAMOUNT,
--t2.SA_GROUP,
--t2.SA_EDUCATION,
--t2.SA_FAMILYSTATE,
--t2.SA_AREA,
--t2.TYPENAME,
--t2.ISINUSE,
--t2.SHOUFURATIOTYPE,
--t2.TERM,
--t2.MONTHLYINTERESTRATE,
--t2.MANAGEMENTFEESRATE,
--t2.CUSTOMERSERVICERATES,
--t2.SALESCOMMISSION,
--t2.PRODUCTCATEGORYID,
--t2.LOWPRINCIPAL,
--t2.TALLPRINCIPAL,
--t2.SHOUFURATIO,
--t2.EFFECTIVEANNUALRATE,
--t2.EXTRA_POS_AVG,
--t2.EXTRA_SA_AVG,


--t3.FLOW_NAME,
--t3.UW_AUDIT_COUNT,
--t3.UW_AUDIT_TIME,
--t3.CE_AUDIT_FLAG,
--t3.CE_AUDIT_TIME,
--t3.IS_NCIIC_AUTO,
--t3.NCIIC_AUTO_RES,
--t3.IS_NCIIC_MANUAL,
--t3.NCIIC_MANUAL_RES,
--t3.IS_NCIIC_PHOTO,
--t3.NCIIC_PHOTO_RES,
--t3.IS_OTHER_CONTACT,
--t3.OTHER_CONTACT_RES,
--t3.IS_ID5_HOMEP,
--t3.ID5_HOMEP_RES,
--t3.IS_HOMEP_DIAL,
--t3.HOMEP_DIAL_RES,
--t3.IS_RELATED_DIAL,
--t3.RELATED_DIAL_RES,
--t3.IS_ID5_WORKP,
--t3.ID5_WORKP_RES,
--t3.IS_WORKP_DIAL,
--t3.WORKP_DIAL_RES,
--t3.IS_SSI_CHECK,
--t3.SSI_CHECK_RES,
--t3.IS_MOBILE_DIAL,
--t3.MOBILE_DIAL_RES,
--t3.IS_SUB_JUDEGE,
--t3.SUB_JUDEGE_RES,
--t3.RAW_SCORE,


--/*
--t4.TOTAL_CONTRACT,
--t4.SETTLE_CONTRACT,
--t4.ACTIVE_CONTRACT,
--t4.CANCELINSTAL_CONTRACT,
--t4.ACTIVE_PRINCIPAL,
--t4.CUS_TOTALLOAN,
--t4.CUS_MOB,
--t4.CUS_MONTHPAYMENT,
--
--t4.CUS_DUESEQ,
--t4.CUS_SIXDUESEQ,
--t4.CUS_PAYPARINCIPAL,
--t4.CUS_PAYSEQ,
--t4.CUS_DUEDAYS,
--t4.CUS_FINISHSEQ,
--t4.CUS_TOTALPAY,
--t4.CUS_DUE_VALUE,
--*/


t5.CS_TIMES,
t5.VAILD,
t5.CONTACT,
t5.LOST,
t5.CON_LOST,
t5.PROMISE,
t5.PTP,
t5.CPTP,
t5.OPTP,
t5.FNBM_TIMES,
t5.INCM_TIMES,
t5.PRO_DAYS,
t5.PRO_SUM,
t5.PTP_DAYS,
t5.PTP_SUM,
t5.M1_VAILD,
t5.M1_CONTACT,
t5.M1_LOST,
t5.M1_PROMISE,
t5.M1_PTP,
t5.M1_OPTP,
t5.M1_CPTP,
t5.M1_FNBM_TIMES,
t5.M1_INCM_TIMES,
t5.M1_PRO_DAYS,
t5.M1_PRO_SUM,
t5.M1_PTP_DAYS,
t5.M1_PTP_SUM,
t5.M1_CSTIMES,
t5.M2_VAILD,
t5.M2_CONTACT,
t5.M2_LOST,
t5.M2_PROMISE,
t5.M2_PTP,
t5.M2_OPTP,
t5.M2_CPTP,
t5.M2_FNBM_TIMES,
t5.M2_INCM_TIMES,
t5.M2_PRO_DAYS,
t5.M2_PRO_SUM,
t5.M2_PTP_DAYS,
t5.M2_PTP_SUM,
t5.M2_CSTIMES,
t5.M3_VAILD,
t5.M3_CONTACT,
t5.M3_LOST,
t5.M3_PROMISE,
t5.M3_PTP,
t5.M3_OPTP,
t5.M3_CPTP,
t5.M3_FNBM_TIMES,
t5.M3_INCM_TIMES,
t5.M3_PRO_DAYS,
t5.M3_PRO_SUM,
t5.M3_PTP_DAYS,
t5.M3_PTP_SUM,
t5.M3_CSTIMES,
t5.KPTP,
t5.KRPO,
t5.M1_KPTP,
t5.M1_KPRO,
t5.M2_KPTP,
t5.M2_KPRO,
t5.M3_KPTP,
t5.M3_KPRO,
t5.BPTP,
t5.BPRO,
t5.M1_BPTP,
t5.M1_BPRO,
t5.M2_BPTP,
t5.M2_BPRO,
t5.M3_BPTP,
t5.M3_BPRO,
t5.THRMON_CSTIMES,
t5.THRMON_VAILD,
t5.THRMON_CONTACT,
t5.THRMON_RPC,
t5.THRMON_PROMISE,
t5.THRMON_PTP,
t5.THRMON_CPTP,
t5.THRMON_OPTP,
t5.THRMON_FNBM_TIMES,
t5.THRMON_INCM_TIMES,
t5.THRMON_PRODAYS,
t5.THRMON_PROSUM,
t5.THRMON_PTPDAYS,
t5.THRMON_PTPSUM,
t5.THRMON_CONLOST,
t5.THRMON_LOST,
t5.LOST_DAY,
t5.NOCALL_DAY,
t5.NORPC_DAY,
t5.NOPRO_DAY,
t5.PTP_RATE,
t5.PTP_CONTACT,



--t6.PAY_NUM,
--t6.PAY_TOTAL,
--t6.PAY_PRINCIPAL,
--t6.PAY_INTEREST,
--t6.PAY_SERVICE_FEE,
--t6.PAY_FINANCE_FEE,
t6.PAY_DELAY_NUM,
t6.PAY_DELAY_FEE,
--t6.PAY_DELAY10_NUM,
--t6.PAY_DELAY10_FEE,
--t6.PAY_DELAY30_NUM,
--t6.PAY_DELAY30_FEE,
--t6.PAY_DELAY60_NUM,
--t6.PAY_DELAY60_FEE,
--t6.PAY_DELAY90_NUM,
--t6.PAY_DELAY90_FEE,
--t6.PAY_ADDSERVICE_FEE,
--t6.PAY_RANDOM_FEE,
--t6.PAY_TOTAL_FEE,
--t6.BALANCE_LEFT,
--t6.DELAY_TIMES,   --没有找到该字段
--t6.SIX_DELAY_TIMES,
t6.MAX_CPD,
--/*t6.MAX_DPD,*/
--t6.M1_DAYS,
--t6.EVER_M1_TIMES,
--t6.IF_M2,
--t6.M2_DAYS,
--t6.EVER_M2_TIMES,
--t6.IF_M3,
--t6.M3_DAYS,
--t6.EVER_M3_TIMES,
t6.HIS_DELAYDAYS,
t6.AVG_DAYS,
--/*t6.MOB,*/
t6.DELAY_DAYS,
t6.delay_days_rate,
--t6.ONEPAY_NUM,
--t6.ONTIME_PAY,
--t6.INTIME_PAY,
--t6.PAY_SEQ,
--t6.FINISH_SEQ,
--t6.PAY_DELAY,
--t6.DD_DIFF,
--t6.MAX_CONDUE,
--t6.CON1_DUE_TIMES,
t6.MAX_CONDUE10,
t6.CON10_DUE_TIMES,
--/*t6.MAX_CONDUE5,*/
--/*t6.CON5_DUE_TIMES,*/
--t6.MAX_CONDUE30,
--t6.CON30_DUE_TIMES,
--t6.SIX_CONDUE,
--t6.SIXCON1_DUE_TIMES,
--t6.SIX_CONDUE10,
--t6.SIXCON10_DUE_TIMES,
--/*t6.SIX_CONDUE5,*/
--/*t6.SIXCON5_DUE_TIMES,*/
--t6.SIX_CONDUE30,
--t6.SIXCON30_DUE_TIMES,
--t6.DUE_NUM,
--t6.HIS_DUESEQ,
--t6.SIX_PERPAY,
--t6.TWE_PERPAY,
--t6.SIX_INPAY,
--t6.TWE_INPAY,
--t6.SIX_FULLPAY,
--t6.TWE_FULLPAY,
--t6.SIX_PAY,
--t6.TWE_PAY,
--t6.SIX_DUE,
--t6.TWE_DUE,
--t6.NUM_DELAY,
--t6.IS10FINE,
--t6.IS30FINE,
--t6.IS60FINE,
--t6.IS90FINE,
--t6.PAY5TO10,
t6.SEQ_DUEDAYS,
--/*t6.SIX_due_PRINCIPAL,
--t6.SIX_due_INTEAMT,
--t6.SIX_due_SERVICE,
--t6.SIX_due_FINANCE,
--t6.six_due_delay,*/
--t6.OUT1_PRINCIPAL,
--t6.OUT1_INTEAMT,
--t6.OUT1_SERVICE,
--t6.OUT1_FINANCE,
--t6.OUT1_DELAY,

t7.MAX_ROLL_SEQ,--
t7.ROLL_SEQ,    --
t7.ROLL_TIME,   --
t7.SIXMAXROLL_SEQ,
t7.SIXROLL_SEQ,
t7.SIXROLL_TIME,
t7.TWEMAXROLL_SEQ,
t7.TWEROLL_SEQ,
t7.TWEROLL_TIME,
--t7.ROLL_BACK_FLAG,

t8.BACK,
t8.SIX_BACK,
t8.TWE_BACK,
t8.MAX_BACK_SEQ,
t8.SIXMAX_BACK_SEQ,
t8.TWEMAX_BACK_SEQ,
t8.BACK_SEQ,
t8.SIX_BACK_SEQ,
t8.TWE_BACK_SEQ,

--oracle_decode(t2.family_income,0,null,t9.over_due_value/t2.family_income)value_income_ratio,
--oracle_decode(t9.credit_amount,0,null,t9.over_due_value/t9.credit_amount)value_credit_ratio,
oracle_decode(t9.n_cur_balance,0,null,t9.over_due_value/t9.n_cur_balance)value_balance_ratio,
--oracle_decode(t6.due_num,0,null,t6.pay_seq/t6.due_num)pay_due_ratio,
--oracle_decode(t6.due_num,0,null,t6.finish_seq/t6.due_num)finish_due_ratio,
--oracle_decode(t2.periods,0,null,t6.due_num/t2.periods)due_periods_ratio,
--oracle_decode(t2.periods,0,null,t6.finish_seq/t2.periods)finish_periods_ratio,  --t2.periods、t6.finish_seq字段目前暂无 但是finish_periods_ratio
--oracle_decode(t2.periods,0,null,substr(t1.phase,2,1)/t2.periods)overdue_periods_ratio,

--oracle_decode(t5.m1_cstimes,0,null,t6.m1_days/t5.m1_cstimes)m1_csfq,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_contact/t5.m1_cstimes)m1_contact_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_vaild/t5.m1_cstimes)m1_vaild_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_promise/t5.m1_cstimes)m1_promise_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_ptp/t5.m1_cstimes)m1_ptp_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_lost/t5.m1_cstimes)m1_lost_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_fnbm_times/t5.m1_cstimes)m1_fnbm_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_incm_times/t5.m1_cstimes)m1_incm_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_cptp/t5.m1_cstimes)m1_cptp_ratio,
--oracle_decode(t5.m1_cstimes,0,null,t5.m1_optp/t5.m1_cstimes)m1_optp_ratio,
--oracle_decode(t5.m1_ptp,0,null,t5.m1_bptp/t5.m1_ptp)m1_bptp_ratio,
--oracle_decode(t5.m1_promise,0,null,t5.m1_bpro/t5.m1_promise)m1_bpro_ratio,
      
--oracle_decode(t5.m2_cstimes,0,null,t6.m2_days/t5.m2_cstimes)m2_csfq,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_contact/t5.m2_cstimes)m2_contact_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_vaild/t5.m2_cstimes)m2_vaild_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_promise/t5.m2_cstimes)m2_promise_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_ptp/t5.m2_cstimes)m2_ptp_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_lost/t5.m2_cstimes)m2_lost_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_fnbm_times/t5.m2_cstimes)m2_fnbm_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_incm_times/t5.m2_cstimes)m2_incm_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_cptp/t5.m2_cstimes)m2_cptp_ratio,
--oracle_decode(t5.m2_cstimes,0,null,t5.m2_optp/t5.m2_cstimes)m2_optp_ratio,
--oracle_decode(t5.m2_ptp,0,null,t5.m2_bptp/t5.m2_ptp)m2_bptp_ratio,
--oracle_decode(t5.m2_promise,0,null,t5.m2_bpro/t5.m2_promise)m2_bpro_ratio,

     
--oracle_decode(t5.m3_cstimes,0,null,t6.m3_days/t5.m3_cstimes)m3_csfq,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_contact/t5.m3_cstimes)m3_contact_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_vaild/t5.m3_cstimes)m3_vaild_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_promise/t5.m3_cstimes)m3_promise_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_ptp/t5.m3_cstimes)m3_ptp_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_lost/t5.m3_cstimes)m3_lost_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_fnbm_times/t5.m3_cstimes)m3_fnbm_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_incm_times/t5.m3_cstimes)m3_incm_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_cptp/t5.m3_cstimes)m3_cptp_ratio,
--oracle_decode(t5.m3_cstimes,0,null,t5.m3_optp/t5.m3_cstimes)m3_optp_ratio,
--oracle_decode(t5.m3_ptp,0,null,t5.m3_bptp/t5.m3_ptp)m3_bptp_ratio,
--oracle_decode(t5.m3_promise,0,null,t5.m3_bpro/t5.m3_promise)m3_bpro_ratio,
oracle_decode(t6.delay_days,0,null,t5.cs_times/t6.delay_days)csfq,
--oracle_decode(t6.max_cpd,0,null,t9.over_due_value/t6.max_cpd)due_delay_ratio,
oracle_decode(t5.cs_times,0,null,t9.over_due_value/t5.cs_times)due_cstime_ratio,
oracle_decode(t5.contact,0,null,t9.over_due_value/t5.contact)due_contact_ratio,
--oracle_decode(t5.vaild,0,null,t9.over_due_value/t5.vaild)due_vaild_ratio,
oracle_decode(t5.ptp,0,null,t9.over_due_value/t5.ptp)due_ptp_ratio,
--oracle_decode(t5.promise,0,null,t9.over_due_value/t5.promise)due_promise_ratio,
--oracle_decode(t6.six_due,0,null,t6.six_fullpay/t6.six_due)sixfull_due_ratio,
--oracle_decode(t6.six_due,0,null,t6.six_pay/t6.six_due)sixpay_due_ratio,
--oracle_decode(t6.six_due,0,null,t6.six_perpay/t6.six_due)sixper_due_ratio,
--oracle_decode(t6.twe_due,0,null,t6.twe_fullpay/t6.twe_due)twefull_due_ratio,
--oracle_decode(t6.twe_due,0,null,t6.twe_pay/t6.twe_due)twepay_due_ratio,
--oracle_decode(t6.twe_due,0,null,t6.twe_perpay/t6.twe_due)tweper_due_ratio,   
      
--oracle_decode(t6.six_due,0,null,t8.six_back/t6.six_due)sixback_due_ratio,
--oracle_decode(t6.six_due,0,null,t8.sixmax_back_seq/t6.six_due)sixmax_backdue_ratio,
--oracle_decode(t6.six_due,0,null,t8.six_back_seq/t6.six_due)sixseq_backdue_ratio,
--oracle_decode(t8.six_back,0,null,t8.six_back_seq/t8.six_back)six_avg_backseq,
--oracle_decode(t6.six_due,0,null,t8.six_back,0,null,(t8.six_back_seq/t8.six_back)/t6.six_due)sixavg_back_ratio,
      
--oracle_decode(t6.twe_due,0,null,t8.twe_back/t6.twe_due)tweback_due_ratio,
--oracle_decode(t6.twe_due,0,null,t8.twemax_back_seq/t6.twe_due)twemax_backdue_ratio,
--oracle_decode(t6.twe_due,0,null,t8.twe_back_seq/t6.twe_due)tweseq_backdue_ratio,
--oracle_decode(t8.twe_back,0,null,t8.twe_back_seq/t8.twe_back)twe_avg_backseq,
--oracle_decode(t6.twe_due,0,null,t8.twe_back,0,null,(t8.twe_back_seq/t8.twe_back)/t6.twe_due)tweavg_back_ratio,
      
--oracle_decode(t6.due_num,0,null,t8.back/t6.due_num)back_due_ratio,
--oracle_decode(t6.due_num,0,null,t8.max_back_seq/t6.due_num)max_backdue_ratio,
--oracle_decode(t6.due_num,0,null,t8.back_seq/t6.due_num)seq_backdue_ratio,
--oracle_decode(t8.back,0,null,t8.max_back_seq/t8.back)avg_backseq,
--oracle_decode(t6.due_num,0,null,t8.back,0,null,(t8.max_back_seq/t8.back)/t6.due_num)avg_back_ratio,      
     

--oracle_decode(t6.due_num,0,null,t7.roll_time/t6.due_num)roll_due_ratio,
--oracle_decode(t6.due_num,0,null,t7.max_roll_seq/t6.due_num)max_rolldue_ratio,
--oracle_decode(t6.due_num,0,null,t7.roll_seq/t6.due_num)rollseq_due_ratio,
oracle_decode(t7.roll_time,0,null,t7.max_roll_seq/t7.roll_time)avg_rollseq
--oracle_decode(t6.due_num,0,null,t7.roll_time,0,null,(t7.max_roll_seq/t7.roll_time)/t6.due_num)avg_roll_ratio,      
     
--oracle_decode(t6.six_due,0,null,t7.sixroll_time/t6.six_due)sixroll_due_ratio,
--oracle_decode(t6.six_due,0,null,t7.sixmaxroll_seq/t6.six_due)sixroll_max_ratio,
--oracle_decode(t6.six_due,0,null,t7.sixroll_seq/t6.six_due)sixseq_roll_ratio,
--oracle_decode(t7.sixroll_time,0,null,t7.sixmaxroll_seq/t7.sixroll_time)sixavg_rollseq,
--oracle_decode(t6.six_due,0,null,t7.sixroll_time,0,null,(t7.sixmaxroll_seq/t7.sixroll_time)/t6.six_due)sixavg_roll_ratio,      
        
--oracle_decode(t6.twe_due,0,null,t7.tweroll_time/t6.twe_due)tweroll_due_ratio,
--oracle_decode(t6.twe_due,0,null,t7.twemaxroll_seq/t6.twe_due)tweroll_max_ratio,
--oracle_decode(t6.twe_due,0,null,t7.tweroll_seq/t6.twe_due)tweseq_roll_ratio,
--oracle_decode(t7.tweroll_time,0,null,t7.twemaxroll_seq/t7.tweroll_time)tweavg_rollseq,
--oracle_decode(t6.twe_due,0,null,t7.tweroll_time,0,null,(t7.twemaxroll_seq/t7.tweroll_time)/t6.twe_due)tweavg_roll_ratio,      
      
--decode (t6.pay_num,0,null,t6.is10fine/t6.pay_num)fine10_num_ratio,
--decode (t6.pay_num,0,null,t6.pay5to10/t6.pay_num)pay5to10_num_ratio,
--decode (t6.due_num,0,null,t6.is10fine/t6.due_num)fine10_due_ratio,
--decode (t6.due_num,0,null,t6.pay5to10/t6.due_num)pay5to10_due_ratio,


--decode (t6.pay_num,0,null,t6.is30fine/t6.pay_num)fine30_num_ratio,
--decode (t6.pay_num,0,null,t6.is60fine/t6.pay_num)fine60_num_ratio,
--decode (t6.pay_num,0,null,t6.is90fine/t6.pay_num)fine90_num_ratio,
--decode (t6.pay_seq,0,null,t6.is10fine/t6.pay_seq)fine10_seq_ratio,
--decode (t6.pay_seq,0,null,t6.is30fine/t6.pay_seq)fine30_seq_ratio,
--decode (t6.pay_seq,0,null,t6.is60fine/t6.pay_seq)fine60_seq_ratio,
--decode (t6.pay_seq,0,null,t6.is90fine/t6.pay_seq)fine90_seq_ratio

from 
  tmp_dcc.tm1m3_lf_xj_population_simple_v3_nfp    t1  
  left join tmp_dcc.tm1m3_lf_xj_application       t2 on t1.contract_no=t2.contract_no
--left join tmp_dcc.tm1m3_lf_xj_audit             t3 on t1.contract_no=t3.contract_no 
--left join tmp_dcc.tm1m3_lf_xj_cust              t4 on t1.contract_no=t5.contract_no and t1.state_date=t5.state_date
  left join tmp_dcc.tm1m3_lf_xj_collection_base   t5 on t1.contract_no=t5.contract_no and t1.state_date=t5.state_date
  left join tmp_dcc.tm1m3_lf_xj_behavior_base     t6 on t1.contract_no=t6.contract_no and t1.state_date=t6.state_date
  left join tmp_dcc.tm1m3_lf_xj_roll              t7 on t1.contract_no=t7.contract_no and t1.state_date=t7.state_date    --lpy生成
  left join tmp_dcc.tm1m3_lf_xj_back              t8 on t1.contract_no=t8.contract_no and t1.state_date=t8.state_date
  left join   
     (select t.contract_no,t.state_date,sum(t.over_due_value)over_due_value,
             sum(t.n_cur_balance)n_cur_balance,sum(t.credit_amount)credit_amount 
     from tmp_dcc.tm1m3_lf_xj_population_new t 
     group by t.contract_no,t.state_date)   t9 on t1.contract_no=t9.contract_no and t1.state_date=t9.state_date


select * from tmp_dcc.tm1m3_lf_xj_new_m1 limit 100
select count(*) as num1 from tmp_dcc.tm1m3_lf_xj_new_m1 limit 100
  
  
--tmp_dcc.tm1m3_lf_xj_population_simple_v3_nfp t1,     1数据样本
--tmp_dcc.tm1m3_lf_xj_APPLICATION t2,                  2申请信息
--tmp_dcc.tm1m3_lf_xj_audit t3,                        3审核信息
--/*tmp_dcc.tm1m3_lf_xj_cust t4,*/                     7客户维度
--tmp_dcc.tm1m3_lf_xj_collection_base t5,              6催收信息
--tmp_dcc.tm1m3_lf_xj_behavior_base t6,                4还款信息
--tmp_dcc.tm1m3_lf_xj_roll t7,                         5回退信息
--tmp_dcc.tm1m3_lf_xj_back t8,                         5回退信息




---------------------------------------------------------------------------------
--------------09.整合变量代码----------------------------------------------------
---------------------------------------------------------------------------------
---9.1 tmp_dcc.tm1m3_lf_xj_cuishou_info_v3
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_cuishou_info_v3
---修改by XGB
---第9段代码中的催收3张表 第1行-151行代码
---lost,incm_times,cs_times
---tm1m3_lf_xj_pay_info_v3 cs1.tm1m3_lf_xj_cus_info_v1  /*无用，注释掉*/
create table tmp_dcc.tm1m3_lf_xj_cuishou_info_v3 as
select
      t1.customerid
      ,t1.contract_no
      ,t1.state_date     
      ,sum(lost) lost                                                  ---完全失联次数                                      
      ,sum(incm_times)incm_times                                       ---来电次数
      ,sum(cs_times) cs_times                                                     
      --,case when sum(contact)=0 then null else sum(ptp)/sum(contact) end    ---PTP ratio
FROM
      (select T.CONTRACT_NO, T.STATE_DATE, T.CUSTOMERID, T.ACCT_LOAN_NO, T.SERIALNO,T.FLAG1,
              T.EXECUTORCODE, T.PROMISREPAYMENTDATE,T.INPUT_DATE, T.RECHECK_DATE
              ,case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end lost
              ,case when executorcode ='INCM' then 1 else 0 end INCM_TIMES
              ,case when input_date is not null then 1 else 0 end cs_times         
      from

            (select M.CONTRACT_NO, M.STATE_DATE, M.CUSTOMERID, M.ACCT_LOAN_NO, 
                    N.SERIALNO, N.EXECUTORCODE, N.PROMISREPAYMENTDATE, N.INPUT_DATE, N.RECHECK_DATE
                    ,sum(1-(case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end)) over(partition by contract_no,state_date order by input_date) flag1
               FROM tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp M
                    left join 
                    (select a7.*
                            ,regexp_replace(substr(inputdate,1,10),'/','-')   input_date
                            ,regexp_replace(substr(recheckdate,1,10),'/','-') recheck_date
                      from S1.CONSUME_COLLECTIONREGIST_INFO a7
                      where inputdate is not null
                    )N
                    on M.customerid=N.customerid
              where M.state_date>regexp_replace(substr(inputdate,1,10),'/','-')           --TO_DATE(M.state_date)
            ) t 
       ) t1
group by t1.customerid
         ,t1.contract_no
         ,t1.STATE_DATE
;  
         
---------------------------------------------------------------------------------
---9.1 tmp_dcc.tm1m3_lf_xj_cuishou_info_v2
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_cuishou_info_v2
---修改by XGB
---KPTP,BPTP（BPTP_RATIO分子）
create table tmp_dcc.tm1m3_lf_xj_cuishou_info_v2 as 
select 
 customerid, state_date, contract_no,sum(kptp)kptp,sum(1 - kptp) bptp    -----------------BPTP次数
  from (select customerid,serialno,state_date,contract_no, 
                case when sum(case when serialno is null then null
                                   when state_date1 is null or cs_cpd < 4 then 0
                                    else 1 end) >= 1 
                    then 0
                    when sum(case when serialno is null then null
                                  when state_date1 is null or cs_cpd < 4 then 0
                                  else 1 end) is null 
                   then null else 1 end kptp
          from (select t.*,
                        t1.state_date state_date1,
                        t1.cs_cpd,
                        t1.over_due_value,
                        case
                          when t.serialno is null then 
                           null
                          when t1.state_date is null then
                           1
                          when t1.cs_cpd < 4 then
                           1
                          else
                           0
                        end kptp
                   from (select 
                          t.CONTRACT_NO,
                          t.STATE_DATE,
                          t.CUSTOMERID,
                          t.ACCT_LOAN_NO,
                          t.p_contract_no,
                          t.SERIALNO,
                          t.EXECUTORCODE,
                          t.INPUT_DATE,
                          t.RECHECK_DATE
                           FROM (select a7.serialno,
                                        m.customerid,
                                        collectionserialno,
                                        a7.executorcode,
                                        regexp_replace(substr(inputdate,1,10),'/','-')   input_date,
                                        regexp_replace(substr(recheckdate,1,10),'/','-') recheck_date,
                                        m.CONTRACT_NO,
                                        M.state_date,
                                        M.ACCT_LOAN_NO,
                                        m.p_contract_no
                                   from S1.CONSUME_COLLECTIONREGIST_INFO a7
                                        left join tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp M    on M.customerid = a7.customerid
                                  where a7.inputdate is not null
                                    and a7.EXECUTORCODE = 'PTP'    
                                    and M.state_date>regexp_replace(substr(inputdate,1,10),'/','-')
                                 ) t                         
                         ) t
                   left join ods.overdue_contract t1
                     on t.p_contract_no = t1.contract_no and t.recheck_date = t1.state_Date
                   --and t.input_date <= t1.state_Date                 
                 ) XX1
         group by customerid, serialno, state_date, contract_no) XX2
 group by customerid, state_date, contract_no
; 
 
--select * from tmp_dcc.tm1m3_lf_xj_cuishou_info_v2 limit 100
 
---------------------------------------------------------------------------------
---9.3 tmp_dcc.tm1m3_lf_xj_cuishou_info_v1
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_cuishou_info_v1
---修改by XGB
---PTP,CONTACT
create table tmp_dcc.tm1m3_lf_xj_cuishou_info_v1 as
select
      customerid
      ,contract_no
      ,state_date     
      ,sum(contact) contact                                                   ---可联次数                                      
      ,sum(ptp)ptp                                                            ---PTP次数
      --,case when sum(contact)=0 then null else sum(ptp)/sum(contact) end    ---PTP ratio
FROM
      (select T.CONTRACT_NO, T.STATE_DATE, T.CUSTOMERID, T.ACCT_LOAN_NO, T.SERIALNO,T.LOST,T.FLAG1,
              T.EXECUTORCODE, T.PROMISREPAYMENTDATE,T.INPUT_DATE, T.RECHECK_DATE
              ,case when T.executorcode in ('PTP','CPTP','OPTP','FNBM','PWTR','ORLM','CWOC','CMLM','APPO','INCM','FOUP','YHK') then 1 else 0 end contact
              ,(case when T.executorcode='PTP' then 1 else 0 end) ptp              
      from

            (select M.CONTRACT_NO, M.STATE_DATE, M.CUSTOMERID, M.ACCT_LOAN_NO, 
                    N.SERIALNO, N.EXECUTORCODE, N.PROMISREPAYMENTDATE, N.INPUT_DATE, N.RECHECK_DATE
                    ,sum(1-(case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end)) over(partition by contract_no,state_date order by input_date)flag1
                    ,case when executorcode in ('UNLO','CMCU','MONM','ONSP') then 1 else 0 end lost
                    ,case when executorcode in ('PTP','CPTP','OPTP','FNBM','PWTR','ORLM','CWOC','CMLM','APPO','INCM','FOUP','YHK') then 1 else 0 end contact
               FROM tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp M
                    left join
                    (select a7.*
                            ,regexp_replace(substr(inputdate,1,10),'/','-')   input_date
                            ,regexp_replace(substr(recheckdate,1,10),'/','-') recheck_date
                      from S1.CONSUME_COLLECTIONREGIST_INFO a7
                      where inputdate is not null
                    ) N
                    on M.customerid=N.customerid
              where M.state_date>input_date
            ) T 
       ) YY1
group by customerid
         ,contract_no
         ,STATE_DATE
;

---------------------------------------------------------------------------------
---9.4 tmp_dcc.tm1m3_lf_xj_pay_info_v2
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_pay_info_v2
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_pay_info_v2 as
select  t.contract_no
       ,t.p_contract_no
       ,t.state_date
       ,t.acct_loan_no
       ,t.customerid
       ,t.is_cancel_his
       ,t.loan_stat_his
       ,t.credit_amount
       ,sum(case when t.cpd1 = 1 and t.cs_cpd=1 then 1 else 0 end) as  delay_times  --进入逾期状态的次数（cpd1天起算）
       ,max(cs_cpd) as  max_cpd ----历史最大逾期cs_cpd
       ,max(over_due_value) as  MAX_OVERDUE ----历史最大逾期金额
from 
(
      select  a1.contract_no
             ,a1.p_contract_no
             ,a1.state_date 
             ,a1.acct_loan_no
             ,a1.customerid
             ,a1.is_cancel_his
             ,a1.loan_stat_his
             ,a1.credit_amount            
             ,s2.over_due_value
             ,s2.cs_cpd
             ,max(case when s2.cs_cpd>0 then 1 else 0 end) over(partition by a1.contract_no
                                                                             ,a1.p_contract_no
                                                                             ,a1.state_date
                                                                             ,a1.acct_loan_no
                                                                             ,a1.customerid
                                                                             ,s2.cpd_date) as cpd1
      from tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp a1
        left join ods.overdue_contract s2 on a1.p_contract_no=s2.contract_no
      where a1.state_date >= s2.state_date
) t
group by t.contract_no
        ,t.p_contract_no
        ,t.state_date
        ,t.acct_loan_no
        ,t.customerid
        ,t.is_cancel_his
        ,t.loan_stat_his
        ,t.credit_amount
;    

--select * from tmp_dcc.tm1m3_lf_xj_pay_info_v2 limit 10;


---------------------------------------------------------------------------------
---9.5 tmp_dcc.tm1m3_lf_xj_contract_info_v1
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_contract_info_v1
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_contract_info_v1 as
select  ttt.CONTRACT_NO
       , ttt.PUTOUT_DATE
       , ttt.STATE_DATE
      -- , ttt.DATASET
       , ttt.CUSTOMERID
       , ttt.ACCT_LOAN_NO
       , ttt.apr_payment_num              -- 通过总期次
       , ttt.apr_credit_amt               --通过总贷款金额
from 
(
      select  tt.*
             ,tt1.apr_payment_num
             ,tt1.apr_credit_amt
             ,row_number()over(partition by    tt.CONTRACT_NO
                                             , tt.PUTOUT_DATE
                                             , tt.STATE_DATE
                                            -- , tt.DATASET
                                             , tt.CUSTOMERID
                                             , tt.ACCT_LOAN_NO order by tt1.app_date desc) as rn
      from 
            tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp tt
           ,(select t.CONTRACT_NO
                   ,t.app_date
                   ,t.STATUS_EN
                   ,t.INTER_CODE
                   ,t.REJ
                   ,t.APPROVED
                   ,t.id_person
                   ,sum(case when t.APPROVED = '1' then t.PAYMENT_NUM else 0 end)over(partition by t.id_person order by t.APP_DATE) as apr_payment_num
                   ,sum(case when t.APPROVED = '1' then t.credit_amount else 0 end)over(partition by t.id_person order by t.APP_DATE) as apr_credit_amt
            from rcas.v_cu_risk_credit_summary t
            where (t.INTER_CODE = '3' or t.REJ='1' or (t.APPROVED='1'and t.LOAN_DATE is not null) or t.STATUS_EN='210')
                  and exists (select 1 from tmp_dcc.tm1m3_lf_xj_population_simple_v1_nfp t1 where t.id_person=t1.customerid)
             ) tt1                         
      where tt.customerid = tt1.id_person
            and tt.state_date >= tt1.app_date
) ttt
where ttt.rn=1
;


---------------------------------------------------------------------------------
---9.6 tmp_dcc.tm1m3_lf_xj_pay_info_v1
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_pay_info_v1
---修改by ZDY
create table tmp_dcc.tm1m3_lf_xj_pay_info_v1  as
select   contract_no
        ,STATE_DATE
        ,ACCT_LOAN_NO
        ,sum(case when (t1.paytype = '1' or (t1.paytype = '5' and t1.remark not like '%费用%' and t1.remark not like 'A%')) 
             then t1.finish_periods else 0 end) as finish_periods-- 全额还款期次
from (
select contract_no, STATE_DATE, ACCT_LOAN_NO
             ,paydate
             ,paydate_mod
             ,seqid
             ,paytype
             ,remark
             ,case when pay_rn = 1 and paydate_mod < state_date and finishdate < state_Date then 1 else 0 end as finish_periods  -- 全额还款期次
      from (
              select  a1.*
                     ,to_date(self_date_format(aps.paydate)) as paydate
                     ,(case when APS.paytype = 'A10' and APS.serialno like 'XF1%' then to_date(concat('20',substr(APS.serialno,3,2),'-',substr(APS.serialno,5,2),'-',substr(APS.serialno,7,2)))
                                   when APS.paytype = 'A10' and APS.serialno like 'XF2%' then to_date(concat(substr(APS.serialno,3,4),'-',substr(APS.serialno,7,2),'-',substr(APS.serialno,9,2)))
                                   when APS.paytype = 'A10' and APS.serialno like 'T%' then to_date(concat(substr(APS.serialno,2,4),'-',substr(APS.serialno,6,2),'-',substr(APS.serialno,8,2)))
                                   when APS.paytype = 'A10' then to_date(concat(substr(APS.serialno,1,4),'-',substr(APS.serialno,5,2),'-',substr(APS.serialno,7,2)))
                                 else to_date(self_date_format(APS.paydate)) end) as paydate_mod
                     ,aps.seqid
                     ,aps.paytype
                     ,aps.payprincipalamt
                     ,aps.payinteamt
                     ,aps.remark
                     ,aps.serialno
                     ,apl.psserialno
                     ,to_date(self_date_format(apl.actualpaydate)) as actualpaydate
                     ,case when aps.finishdate is not null and aps.actualpayprincipalamt is null and aps.payprincipalamt = 0 then null
                           else to_date(self_date_format(aps.finishdate)) end as finishdate
                     ,apl.actualpayprincipalamt
                     ,apl.actualpayinteamt
                     ,row_number() over(partition by aps.serialno,a1.contract_no, a1.STATE_DATE, a1.ACCT_LOAN_NO order by apl.actualpaydate) as pay_rn
              from tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp a1
                   left join s1.acct_payment_schedule APS on a1.acct_loan_no = aps.acct_loan_no
                   left join s1.acct_payment_log apl on aps.serialno=apl.psserialno
              where APS.paytype NOT IN ('A9','A19','A17')  -- 排除提前还款手续费 委外催收费 提前委外催收费 （因费用记录时间并不准确）
            )t
)t1
group by contract_no,STATE_DATE,ACCT_LOAN_NO
;

--select * from tmp_dcc.tm1m3_lf_xj_pay_info_v1 limit 10;

---------------------------------------------------------------------------------
---9.7 tmp_dcc.tm1m3_lf_xj_pay_info
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_pay_info
---修改by ZDY
---整合tmp_dcc.tm1m3_lf_xj_pay_info
create table tmp_dcc.tm1m3_lf_xj_pay_info as
select tt1.CONTRACT_NO, tt1.STATE_DATE, FINISH_PERIODS, DELAY_TIMES,  MAX_CPD, MAX_OVERDUE
from 
(
     select  t1.contract_no
            ,t1.state_date
            ,sum(t1.finish_periods) as finish_periods
     from tmp_dcc.tm1m3_lf_xj_pay_info_v1 t1
     group by  t1.contract_no
              ,t1.state_date
)tt1
,
(
     select  t2.contract_no
            ,t2.state_Date
            ,sum(t2.delay_times) as delay_times -- 历史逾期总次数
            ,max(max_cpd) as max_cpd -- 历史最大CPD逾期天数
            ,max(max_overdue) as max_overdue
     from tmp_dcc.tm1m3_lf_xj_pay_info_v2 t2
     group by t2.contract_no
             ,t2.state_date
)tt2
where     tt1.contract_no = tt2.contract_no
      and tt1.state_date  = tt2.state_date
;

---------------------------------------------------------------------------------
---9.8 tmp_dcc.tm1m3_lf_xj_bank_information
---来源：09.整合变量代码,cs1.tm1m3_lf_xj_bank_information
---修改by LPY
---来自9整合变量，生成tmp_dcc.tm1m3_lf_xj_bank_information
---代扣失败比例变量
create table tmp_dcc.tm1m3_lf_xj_bank_information as
select a1.contract_no, a1.state_date, 
       sum(case when dd_status = '0' then 1 else 0 end)/sum(case when dd_status is not null then 1 else 0 end) as DK_RATIO
from tmp_dcc.tm1m3_lf_xj_population_simple_v2_nfp a1
left join 
	(select contractserialno contract_no, 
	       to_date(self_date_format(inputdate)) as inputdate, -- 交易日
	       oracle_decode(managereturncode, '0000', '1', '0') as dd_status 
	from s1.import_file_ebu
	union all
	select contractserialno contract_no, 
	       to_date(self_date_format(inputdate)) as inputdate, -- 交易日
	       oracle_decode(returncode, 'FSBR0000', '1', '0') as dd_status
	from s1.import_file_kft) a2
on a1.p_contract_no = a2.contract_no
where a1.state_date > a2.inputdate
group by a1.contract_no, a1.state_date;




---------------------------------------------------------------------------------
--------------10整合宽表变量最后版----------------------------------------------------
---------------------------------------------------------------------------------
----10.1tmp_dcc.tm1m3_lf_xj_base_m1_f1
---修改by XGB
--drop table tmp_dcc.tm1m3_lf_xj_base_m1_f1
create table tmp_dcc.tm1m3_lf_xj_base_m1_f1 as
select 
--/*主键们*/
 ba.CONTRACT_NO                           -- 1.1 合同号
,ba.PUTOUT_DATE                           -- 1.2 放款日
,ba.STATE_DATE                            -- 1.3 观察日
--,ba.DATASET                             -- 1.4 训练集/测试集/验证集
,ba.CUSTOMERID                            -- 1.5 客户ID
,ba.ACCT_LOAN_NO                          -- 1.6 放款号       
--/*Y值*/
,ba.CPD                                   -- 2.1 Y值
--/*X特征*/
--,ba.PERIODS                               --分期还款期数
,ba.PERSON_SEX                            --性别
,ba.PERSON_APP_AGE                        --年龄
,ba.FAMILY_STATE                          --婚姻状态
,ba.EDUCATION                             --教育程度
,ba.IS_SSI                                --是否社保
--,ba.CERTF_INTERVAL_YEARS                  --证件有效时长
--,ba.COMPANY_TYPE                          --公司类别
--,ba.JOBTIME                               --当前工作年限
--,ba.INDUSTRY                              --工作单位所属行业
--,ba.POSITION                              --工作职位
--,ba.TOTAL_WK_EXP                          --工作总年限
--,ba.LAST3YEAR_WORKCHANGE_NUM              --过去三年内换工作或开业的次数
--,ba.HOUSE_TYPE                            --住房类型
--,ba.EXPENSE_MONT                          --月支出
--,ba.OTHER_INCOME                          --其他收入
--,ba.FAMILY_INCOME                         --家庭月收入
,ba.CHILDRENTOTAL                           --子女个数
--,ba.QQ_LENGTH                             --QQ号码长度
--,ba.EMAIL                                 --电子邮箱类型
--,ba.F_SAME_REG                            --家庭(居住)地址是否与户籍一致
--,ba.IS_CERTID_PROVINCE                    --身份证省份是否与POS一致
,ba.OTHER_PERSON_TYPE                     --其他联系人类型
--,ba.F_SAME_COM                            --公司地址是否在当前城市
--,ba.POS_TYPE                              --POS门店类型
,ba.PROVINCE                              --省份
,ba.CITY                                  --城市
--,ba.MANAGEMENTFEESRATE                    --管理费率
--,ba.CUSTOMERSERVICERATES                  --客户服务费率
--,ba.EFFECTIVEANNUALRATE                   --EIR 有效年利率
,cs3.CS_TIMES                             --历史总催收次数
,round(cs3.CS_TIMES/ba.delay_days,2) CSFQ --催收频次
,cs1.CONTACT                              --历史可联次数
,cs3.LOST                                 --历史完全失联次数
,cs1.PTP                                  --PTP次数
,(cs1.ptp*3) HIS_PTP                      --ptp复核总天数
,cs3.INCM_TIMES                           --来电次数
,cs2.KPTP                                 --KPTP次数
,cs2.BPTP                                 --BPTP次数
,ba.AVG_DAYS                              --平均每次逾期停留天数
,ba.DELAY_DAYS                            --处于逾期状态的天数（cpd1天起算）
,ba.delay_days_rate                       --历史延迟天数/账龄天数（取最大值）
--,ba.ONTIME_PAY                            --按时还款期次
--,ba.INTIME_PAY                            --及时还款期次
--,ba.CON1_DUE_TIMES                        --历史连续逾期次数
,ba.MAX_CONDUE10                          --历史最大连续逾期10天的期数
,ba.CON10_DUE_TIMES                       --历史连续逾期10天的次数
--,ba.HIS_DUESEQ                            --历史逾期总期数
--,ba.IS10FINE                              --还款时间距离10天滞纳金收取间隔3天以内的次数
,ba.SEQ_DUEDAYS                           --延滞天数（每期最大（本金、费用可能延滞天数不同）的总和（所有期次相加））
,ba.MAX_ROLL_SEQ                          --最大回退期数
--,ba.VALUE_INCOME_RATIO                    --应还金额比家庭月收入
,ba.VALUE_BALANCE_RATIO                   --应还金额比贷款余额
--,ba.DUE_PERIODS_RATIO                     --应还期数比
--,ba.OVERDUE_PERIODS_RATIO                 --逾期期数比
--,ba.DUE_DELAY_RATIO                       --当前欠款金额/延滞天数
,ba.DUE_CSTIME_RATIO                      --当前欠款金额/总催收天数
,ba.DUE_CONTACT_RATIO                     --当前欠款金额/可联次数
,ba.DUE_PTP_RATIO                         --当前欠款金额/PTP次数
,ba.AVG_ROLLSEQ                           --历史回退平均期数
--,ba.FINE10_SEQ_RATIO                      --还款时间距离10天滞纳金收取间隔3天以内的比例
,ba.IS_INSURE                             --是否购买保险
--,ba.IS_HOLIDAYS                           --是否节假日申请
--,substr(ba.QQNO,1,1)QQNO_INIT             --QQ号码第一位
,ba.ROLL_TIME                             --回退次数
,ba.ROLL_SEQ                              --累计回退期数
,ba.HIS_DELAYDAYS                         --所有期次的逾期停留天数之和
--,substr(ba.CERT_6_INITAL,1,4)CERT_4_INITAL--客户身份证前4位
--,ba.PAY_PRINCIPAL                         --累积还本金金额
--,ba.PAY_INTEREST                          --累积还利息金额
--,ba.PAY_SERVICE_FEE                       --累积还客服费用
--,ba.PAY_FINANCE_FEE                       --累积还财管费用
,ba.PAY_DELAY_NUM                         --累积还滞纳金次数
,ba.PAY_DELAY_FEE                         --累积还滞纳金金额
--,ba.PAY_TOTAL_FEE                         --累积还费用金额
--,ba.FINISH_SEQ                            --实全额还款期次
--,ba.RAW_SCORE                             --申请评分    
,co1.APR_CREDIT_AMT                       --通过总贷款金额
,ba.credit_amount_v0 CREDIT_AMOUNT        --贷款金额
--/*,ba.ptp_days HIS_PTPDAYS              --PTP复核天数总和*/
--,ba.over_due_value_v0 OVER_DUE_VALUE      --当前逾期金额
--sa1.PUTOUT_SAGROUP                       --SA分组_申请时间       这个变量可以取**
--,sa1.STATE_SAGROUP                        --SA分组_评分时间
,pa1.DELAY_TIMES                          --进入逾期状态的次数（cpd1天起算）
,pa1.MAX_CPD                              --历史最大逾期cs_cpd
,pa1.MAX_OVERDUE                          --历史最大逾期金额          
,round(oracle_decode(cs1.contact, 0, null, cs1.PTP/cs1.contact), 4)   PTP_RATIO                                  --PTP比率
,round(oracle_decode(cs1.PTP, 0, null, cs2.BPTP/cs1.PTP), 4)   BPTP_RATIO                                        --BPTP比率
,oracle_decode(co1.APR_PAYMENT_NUM,0,null,round(pa1.FINISH_PERIODS/co1.APR_PAYMENT_NUM,4))FINISH_PERIODS_RATIO   --实还期数比
,round(bi.dk_ratio,4)dk_ratio             --代扣失败比率
from 
  tmp_dcc.tm1m3_lf_xj_new_m1                     ba
  left join tmp_dcc.tm1m3_lf_xj_population_temp1 sa1 on ba.contract_no = sa1.contract_no and ba.state_date = sa1.state_date
  left join tmp_dcc.tm1m3_lf_xj_pay_info         pa1 on ba.contract_no = pa1.contract_no and ba.state_date = pa1.state_date
  left join tmp_dcc.tm1m3_lf_xj_contract_info_v1 co1 on ba.contract_no = co1.contract_no and ba.state_date = co1.state_date
  left join tmp_dcc.tm1m3_lf_xj_cuishou_info_v1  cs1 on ba.contract_no = cs1.contract_no and ba.state_date = cs1.state_date
  left join tmp_dcc.tm1m3_lf_xj_cuishou_info_v2  cs2 on ba.contract_no = cs2.contract_no and ba.state_date = cs2.state_date
  left join tmp_dcc.tm1m3_lf_xj_cuishou_info_v3  cs3 on ba.contract_no = cs3.contract_no and ba.state_date = cs3.state_date
  left join tmp_dcc.tm1m3_lf_xj_bank_information bi  on ba.contract_no = bi.contract_no  and ba.state_date = bi.state_date
where IS_FP='nFP'         --只筛选出nFP的客户群


----10.1tmp_dcc.tm1m3_lf_xj_base_m1_dcc
----根据CPD 天数，形成Y值
create table tmp_dcc.tm1m3_lf_xj_base_m1_dcc as
select *,
       case when cpd =31 then 1
            when cpd between 0 and 9 then 0
            else -999 end   as target
from tmp_dcc.tm1m3_lf_xj_base_m1_f1

select * from tmp_dcc.tm1m3_lf_xj_base_m1_dcc  where CONTRACT_NO in ('11777066004')

select substr(state_date,1,7) as month1,target,count(*) as num1 from tmp_dcc.tm1m3_lf_xj_base_m1_dcc group by substr(state_date,1,7),target order by month1,target

select substr(state_date,1,10) as day1,cpd,count(*) as num1 from tmp_dcc.tm1m3_lf_xj_base_m1_dcc where substr(state_date,1,7)='2017-07' group by substr(state_date,1,10),cpd order by day1,cpd













