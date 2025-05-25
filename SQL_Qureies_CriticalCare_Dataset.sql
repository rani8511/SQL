--********************************************
--Q33.List all patients whose heart rate increased by over 30% from the previous reading and the time when it happened.List all occurences of heart rate increase. Use Windows functions to achieve this.

select * from 
(select 
(extract(hour from charttime)::text) ||':'||
(extract(minute from charttime)::text)||':'||
(extract(second from charttime)::text)as time, 
inp_no,
heart_rate, 
(heart_rate>72) as inc_heartrate,
round((100.0*heart_rate/SUM(heart_rate) over( partition by inp_no))) as percentage
from nursingchart) as h
where h.percentage > 0.3;

--********************************************
--Q34.List patients who had milk and soft food but produced no urine.//

select distinct n.inp_no,
milk,
soft_food,  
urine_volume,
patient_id
from 
nursingchart as n
inner join
baseline  as b
on n.inp_no= b.inp_no
where urine_volume = 0
group by n.inp_no,patient_id,milk,soft_food,urine_volume
having milk is not null or soft_food is not null;

--**************************************************
--//Q35.Using crosstab, show number of times each patient was transferred to each department.//

create view transfer_view as
select count(transferdept) as numberoftimes,
 patient_id bigint,
 transferdept
from transfer
group by transferdept,patient_id
having count(transferdept)>1;

create table if not exists transfer_table 
        ( patient_id BIGINT,
        transferdept varchar (50),
        numberoftimes bigint);

insert into transfer_table values
       (5983030,'ICU',2),
       (6013186,'ICU',2),
       (5877819,'ICU',2),
       (5410644,'Medical Specilties',2),
       (5861909,'ICU',2),
       (5842247,'surgery',2),
       (5887393,'ICU',2),
       (5612349,'ICU',2),
       (6208487,'Medical Specialties',2),
       (5399882,'ICU',2),
       (6016256,'ICU',2),
       (5406548,'ICU',3),
	  (6072952,'ICU',3),
	  (6061989,'ICU',3),
	  (5559397,'ICU',3),
	  (5979784,'ICU',3),
	  (6351520,'ICU',3),
	  (5773429,'Surgery',3),
	  (6310530,'ICU',3),
	  (6110606,'ICU',3),
	  (6014980,'ICU',3),
	  (5793248,'ICU',3),
	  (3929103,'ICU',3),
	  (5431262,'ICU',3),
	  (6142027,'Surgery',3),
	  (6001697,'ICU',3),
	  (5632914,'ICU',3),
	  (5329897,'Surgery',3),
	  (4011004,'Surgery',3),
	  (6256220,'ICU',3),
	  (5672124,'ICU',3),
	  (5877899,'ICU',3),
                 (6328174,'Medical Specialties',3),
                (6357027,'ICU',3),
                (5773429,'ICU',3),
	  (6165482,'ICU',3),	
                 (5970230,'ICU',3),
                 (6245877,'ICU',3),
  	  (2991870,'ICU',3),
	  (6146516,'ICU',3),
	  (5809356,'ICU',3),
	  (5423379,'ICU',3),
	  (6328174,'ICU',3),
	  (5401681,'ICU',3),
	  (5410800,'ICU',3),
	  (5988495,'ICU',3),
	  (4011004,'ICU',4),
	  (6279927,'Medical Specialties',4),
	  (5406548,'Medical Specialties',4),
	  (5401681,'Surgery',4),
	  (6151627,'ICU',4),
	  (6069640,'Medical Specialties',4),
	  (5329897,'ICU',4),
	  (6080643,'ICU',4),
	  (3098919,'ICU',4),
	  (6249716,'ICU',4),
	  (6039999,'ICU',4),
	  (5864125,'Medical Specialties',4),
	  (3687082,'ICU',4),
	  (6069640,'ICU',4),
	  (5886596,'Surgery',4),
	  (5864125,'ICU',4),
	  (6291268,'ICU',4),
	  (6001697,'Medical Specialties',4),
	  (2991870,'Medical Specialties',4),
	  (3256204,'ICU',4),
	  (5410644,'ICU',4),
	  (6351520,'Medical Specialties',4),
	  (5809356,'Medical Specialties',4),
	  (5855790,'ICU',4),
	  (6146516,'Medical Specialties',4),
	  (5528379,'ICU',4),
	  (6130245,'ICU',4),
	  (5399882,'Surgery',4),
	  (6319884,'ICU',4),
	  (3687082,'Medical Specialties',4),
	  (6208487,'ICU',4),
	  (6299684,'ICU',4),
	  (6119940,'ICU',4),
	  (6020523,'Medical Specialties',4),
	  (6072952,'Medical Specialties',4),
	  (6020523,'ICU',4),
	  (5839911,'ICU',4),
	  (5941974,'ICU',4),
	  (5776624,'ICU',4),
	  (5979219,'ICU',4),
	  (5672124,'Medical Specialties',4),
	  (5811429,'ICU',4),
	  (5431262,'Medical Specialties',4),
	  (6142500,'Surgery',4),
	  (5766298,'ICU',4),
	  (6142500,'ICU',4),
	  (5632914,'Medical Specialties',4),
	  (6299684,'Medical Specialties',4),
	  (3219303,'ICU',5),
	  (5985458,'Medical Specialties',5),
	  (6279927,'ICU',5),
	  (6062925,'ICU',5),
	  (5655676,'ICU',5),
	  (5769399,'Medical Specialties',5),
	  (5821751,'ICU',5),
	  (6330660,'ICU',5),
	  (3879653,'ICU',5),
	  (6288893,'ICU',5),
	  (5764124,'ICU',5),
	  (5398127,'ICU',5),
	  (3098919,'Medical Specialties',5),
	  (6081394,'Surgery',5),
	  (6256220,'Medical Specialties',5),
	  (5932837,'ICU',5),
	  (6080643,'Medical Specialties',5),
	  (5769399,'ICU',5),
	  (6090388,'ICU',5),
	  (3256204,'Medical Specialties',5),
	  (6081394,'ICU',5),
	  (5471195,'ICU',5),
	  (6062925,'Medical Specialties',5),
	  (6130245,'Medical Specialties',5),
	  (6049698,'ICU',6),
	  (5766298,'Medical Specialties',6),
	  (5979784,'Medical Specialties',6),
	  (6072952,'Surgery',6),
	  (5329897,'Medical Specialties',6),
	  (6205900,'ICU',6),
	  (5647048,'ICU',6),
	  (5961069,'Surgery',6),
	  (6323819,'ICU',6),
	  (5793248,'Surgery',6),
	  (4149023,'ICU',6),
	  (5783757,'ICU',6),
	  (5430400,'ICU',6),
	  (5842247,'ICU',6),
	  (5877899,'Medical Specialties',6),
	  (6245877,'Medical Specialties',6),
	  (1895783,'ICU',6),
	  (5528379,'Medical Specialties',6),
	  (6203247,'ICU',6),
	  (5941974,'Medical Specialties',6),
	  (6142027,'ICU',6),
	  (5985458,'ICU',6),
	  (5660496,'ICU',6),
	  (6319884,'Medical Specialties',7),
	  (5961069,'ICU',7),
	  (6014980,'Medical Specialties',7),
	  (5988495,'Medical Specialties',7), 
	  (1895783,'Medical Specialties',7),
	  (3929103,'Medical Specialties',7),
	  (3818433,'ICU',7),
	  (6330660,'Surgery',7),
	  (5979219,'Medical Specialties',7),
	  (5660496,'Surgery',8),
	  (5886596,'ICU',8),
	  (6165482,'Medical Specialties',8),
	  (5410800,'Surgery',8),
	  (5776624,'Medical Specialties',8),
	  (6356499,'Medical Specialties',8),
	  (6356499,'ICU',8),
	  (6205900,'Surgery',9),
	  (5970230,'Medical Specialties',9),
	  (6151627,'Medical Specialties',9),
	  (6016256,'Medical Specialties',9),
	  (5821751,'Medical Specialties',9),
	  (6021124,'ICU',10),
	  (6021124,'Medical Specialties',11),
	  (5559397,'Medical Specialties',11),
	  (3256204,'Surgery',11),
	  (6039999,'Medical Specialties',12),
	  (5612349,'Surgery',12),
	  (5887393,'Medical Specialties',13),
	  (5423379,'Medical Specialties',13),
	  (5941974,'Surgery',14),
	  (6357027,'Medical Specialties',14),
	  (6288893,'Medical Specialties',15),
	  (6061989,'Medical Specialties',16),
	  (3818433,'Medical Specialties',18),
	  (3219303,'Medical Specialties',19),
	  (6110606,'Surgery',29),
	  (5985458,'Surgery',43)
	  
	  
Select * from transfer_table;	
Create extension tablefunc; 	
Select * from
  crosstab ('select patient_id,transferdept,numberoftimes from transfer_table 
  order by patient_id,transferdept','VALUES (''ICU''), (''Medical Specialties''), (''Surgery'')')
  as transfer_table
      (patient_id bigint,ICU integer,"Medical Specialties" integer,Surgery integer);


drop view transfer_view;--for data cleanup
drop table transfer_table;-- for data cleanup
--**************************************************
--//36.Produce a list of 100 normally distributed age values. Set the mean as the 3rd lowest     age in the table, and assume the standard deviation from the mean is 3.//

select age,
(1 / (3 * SQRT(2 * PI()))) * 
exp(-0.5 * POW((age:: numeric- 29) / 3, 2)) as normal_distribution_age_values
from baseline
order by age;

--**************************************************
--37.Display the patients who engage in vigorous physical activity and have no body pain.//

create view activity_view as
select patient_id,
       SF36_ActivityLimit_VigorousActivity as vigorous_physical_activity,
       SF36_Pain_BodyPainPast4wk as BodyPain_Past4wk, 
       SF36_Pain_BodyPainPast4wkInterHousework as BodyPain_Past4wk_InterHousework
from outcome 
where SF36_ActivityLimit_VigorousActivity is Not Null and SF36_Pain_BodyPainPast4wk is not Null and
SF36_Pain_BodyPainPast4wkInterHousework is not Null  ;

create view  nopain_view as
select * from
(select case 
  when vigorous_physical_activity= '3_not limited at all' then 'more_Vactivity'
  when vigorous_physical_activity= '2_limited a little' then 'medium_Vactivity'
  when vigorous_physical_activity= '1_limited a lot' then 'less_Vactivity'
  End as activity_range,patient_id,BodyPain_Past4wk, BodyPain_Past4wk_InterHousework
  from activity_view
  where BodyPain_Past4wk='1_None' and BodyPain_Past4wk_InterHousework='1_Not at all'
  )b
 group by b.patient_id,b.BodyPain_Past4wk,b.BodyPain_Past4wk_InterHousework,activity_range ;

select * from nopain_view ; 

or

select * from nopain_view
where activity_range not in('medium_Vactivity','less_Vactivity');

drop view nopain_view;--for data cleanup
drop view activity_view; --for data cleanup
--********************************************
--//38.Create a view on outcome table to show patients with poor health.//

create view poorhealth_view as
select patient_id, 
 SF36_GH_SickerEasierThanOthers as sick, 
 SF36_GH_GetWorse as verysick 
from outcome
WHERE 
SF36_GH_SickerEasierThanOthers <>'5_Definitely false' 
and  
SF36_GH_GetWorse <>'5_Definitely false';

select * from poorhealth_view;

drop view poorhealth_view;--data cleanup
--********************************************
--//39.Create a procedure to check if a disease code exists.//

select * from icd;

create or replace procedure diseasecode_exists_check(
    icd_code VARCHAR (100)
)
LANGUAGE plpgsql
AS $$

declare
disease_exists BOOLEAN; 

BEGIN
    select exists(
        select 1
        from icd
        where icd.icd_code = diseasecode_exists_check.icd_code
    ) into disease_exists;

    if disease_exists then
        RAISE NOTICE 'Disease code "%" exists.', icd_code;
    else
        RAISE NOTICE 'Disease code "%" does not exist.', icd_code;
    end if;
END;
$$;

CALL diseasecode_exists_check('K76.807');

drop procedure diseasecode_exists_check(icd_code varchar(100));--data cleanup

--********************************************
--//40.Which drug was most administered among patients who have never been intubated?//

create view drug_view as
select  distinct B.patient_id,Endotracheal_intubation, DrugName, Drug_time
from nursingchart as NC
inner join
baseline as B on NC.inp_no = B.inp_no
inner join
drugs as D on B.patient_id=D.patient_id;

select Distinct Drugname, count(drugname) as most_used_drug,patient_id, Endotracheal_intubation
from drug_view 
where Endotracheal_intubation is Null
group by patient_id, Endotracheal_intubation,Drugname
order by most_used_drug desc
Limit 1; 

drop view drug_view;--data cleanup

--********************************************
--//41.Add a column birthyear to baseline column based on age.

select * from baseline;

create view year_view as
select patient_id, inp_no, 
extract (year from current_date)-age as birthyear
from baseline;

select * from year_view

alter table baseline
add column birth_year double precision;

update baseline
set birth_year=
(select birthyear from year_view 
where baseline.patient_id= year_view.patient_id)
where birth_year is null;

drop view year_view;--data cleanup


--********************************************
--//42.Use regular expression to find disease names that end in 'itis'.

select icd_desc from icd;

SELECT icd_desc as disease
FROM icd 
WHERE
icd_desc ~* 'itis$'--case insensitive
or
icd_desc ~ 'itis$';--case sensitive

--********************************************
--//43.Write a stored procedure to generate a summary report for a patient ID 
--specified by user, including blood sugar, temperature, heart rate and drug administration.//

create view report_view as
select distinct B.patient_id, blood_sugar, temperature, heart_rate, drugname
from NursingChart as N 
inner join 
Baseline as B on N.inp_no=B.inp_no
inner join
Drugs as D on B.patient_id= D. patient_id
where  B.patient_id is not null;

create or replace procedure summary_report_procedure(patient_id_input bigint)

language plpgsql
AS $$

Declare record record;
  
BEGIN
   
        Create table if  not exists patientreport (
            patient_id bigint,
            bloodsugar double precision,
            patient_temp numeric,
            heartrate double precision,
            drug text
        );
   
	insert into patientreport( patient_id,bloodsugar,patient_temp,heartrate,drug )	
	
	Select  RV.patient_id , 
	        RV.blood_sugar,
		    RV.temperature, 
		    RV.heart_rate, 
		    RV.drugname 
    from report_view RV
	where RV. patient_id= patient_id_input;
	

for record in 
        Select patient_id, bloodsugar, patient_temp, heartrate, drug
        from patientreport
        where patient_id = patient_id_input
    loop
        RAISE NOTICE 'Patient ID: %, Blood Sugar: %, Temperature: %, Heart Rate: %, Drug: %', 
            record.patient_id, record.bloodsugar, record.patient_temp, record.heartrate, record.drug;
    end loop;
	
END;
	
$$;

call summary_report_procedure(1895783);

drop table patientreport;--data cleanup
drop procedure summary_report_procedure(patient_id_input bigint);--data cleanup

--********************************************
--//44.Create an index on any column in outcome table and also write a query to delete that index.//

CREATE INDEX discharge_index
ON outcome (discharge_dept);---creating index

select patient_id, discharge_dept 
from outcome 
where discharge_dept = 'Surgery';--- to see the execution

drop index discharge_index;---deleting the index
or
drop index if exists discharge_index;

--********************************************
--//45. Display the sf36_generalhealth of all patients whose blood sugar has a standard deviation of more than 2 from the average.//

Create view stdev_view as
select N.inp_no,agg.avg,
       Sqrt(sum(power(cast(blood_sugar as Float)-agg.avg,2))/agg.ct) as manual_std
from nursingchart as N
inner join
(select inp_no, 
        count(blood_sugar) as ct,
        avg(blood_sugar) as avg 
from nursingchart as N
group by N.inp_no)as agg on N.inp_no=agg.inp_no
group by N.inp_no,agg.avg,agg.ct;

create view health_view as
select S.inp_no, 
       S.avg, sf36_generalhealth as general_health, 
	   S.manual_std
from stdev_view as S
inner join
baseline as b on S.inp_no=B.inp_no
inner join 
outcome as O on B. patient_id = O.patient_id
group by S.inp_no,S.avg,S.manual_std,general_health;

select inp_no,general_health 
from health_view
where (avg-manual_std) > 2
group by inp_no,general_health
having general_health is not null;

drop view stdev_view;--data cleanup
drop view health_view;--data cleanup
--********************************************
 --//46.Show the average time spent across different departments among alive patients, and among dead patients.//

select T.patient_id, transferdept as different_depts , O.follow_vital,
round(avg(extract (epoch from (stoptime-starttime))/3600)) as avg_time_spent_hrs 
from transfer as T
inner join
outcome as O on T.patient_id = O. patient_id
group by T. patient_id, T.transferdept,O.follow_vital
having O.follow_vital is not null
order by O.follow_vital;

--********************************************
--//47.Write a query to list all the users in the database.

select datname, 
count(usesysid) as users
from pg_stat_activity
group by 1;

or

select datname, 
usename, 
count(*)
from pg_stat_activity
group by datname, usename
having usename is not null;

--********************************************
--//48.For each patient, find their maximum blood oxygen saturation while they were in the ICU , 
--and display if it is above or below the average value among all patients.

select inp_no,
blood_oxygen_saturation as saturation from nursingchart;

select n.inp_no,
max(blood_oxygen_saturation) as max_saturation,
avg(blood_oxygen_saturation) as avg_value,
case 
when max(blood_oxygen_saturation) > avg(blood_oxygen_saturation) then 'above'
when max(blood_oxygen_saturation) < avg(blood_oxygen_saturation) then 'below'
when max(blood_oxygen_saturation) = avg(blood_oxygen_saturation) then 'equal'
	 end as saturation_range,
transferdept from 
nursingchart as n
inner join
transfer as t
on n.inp_no=t.inp_no
where transferdept='ICU'
group by  n.inp_no,transferdept;

--********************************************  

