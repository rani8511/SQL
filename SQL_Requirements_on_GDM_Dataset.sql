--Q33.Calculate the average gestational age at delivery for GDM vs non-GDM pregnancies.

--To check the related columns in the related tables
select * from pregnancy_info;
select * from glucose_tests;
	
--updating 0, 1 values to GDM and non-GDM
select 
 case 
 when gdm_status=0 then 'non-GDM'
 when gdm_status=1 then 'GDM'
 else 'unknown'
 end as gdm_status,
 ROUND(avg(gest_age)::NUMERIC,2) as avg_gest_age
from 
--getting the required columns in the subquery
 (select p.participant_id as ID, (ga_delivery) as gest_age,
  diagnosed_gdm as gdm_status 
  from pregnancy_info as p
  join
  glucose_tests as g
  on p.participant_id=g.participant_id
  where g.diagnosed_gdm in (0,1)
  group by diagnosed_gdm, p.participant_id, p.ga_delivery) as G
group by gdm_status; 


-------------------------------------------------------------------------------------------------------------

--Q34.Calculate the Participants Mean arterial Pressure (MAP) for both Visit 1 and Visit 3.

--to view the related data
select * from vital_signs; 

--for faster execution
create index idx_map_visit_1
on vital_signs (systolic_bp_v1, diastolic_bp_v1);
create index idx_map_visit_3
on vital_signs (systolic_bp_v3, diastolic_bp_v3);

--calculate the values acc to requirement
select participant_id as id,
		((systolic_bp_v1+ 2*diastolic_bp_v1)/3) as MAP_visit_1,
       ((systolic_bp_v3+ 2*diastolic_bp_v3)/3) as MAP_visit_3
from vital_signs
group by participant_id,systolic_bp_v1,diastolic_bp_v1,systolic_bp_v3,diastolic_bp_v3
order by id;


--------------------------------------------------------------------------------------------------------------

--Q35.List pregnancies that exceeded the standard 40 weeks full term and calculate the number of days delayed.

--Viewing the related data
SELECT* FROM pregnancy_info;
SELECT * from documentation_track;


--using the logic as First Visit EDD is 40 weeks usually 
--and fetching the patients with EDD more than ultrasound EDD as delayed pregnancies
SELECT P.participant_id as Extended_Pregnancy_ID,
       D."US EDD", P.edd_v1, (P.edd_v1-D."US EDD") as delayed_days_diff
from pregnancy_info as P
JOIN
documentation_track as D
USING (participant_id)
where P.edd_v1 < D."US EDD" --exceeded pregnancies
order by P.participant_id;


--**************************************************************************************************************--

--Q36.Apply lookahead concept to transform medication data and generate new column in the glucose_tests table.

--Viewing the related data
SELECT * from glucose_tests;
SELECT * from demographics
order by participant_id;

--Adding new column 
ALTER table glucose_tests add column medications_intake Varchar (20);

--Transforming data in medications column from demographics table using REGEX function 
--and updating these data values to the new column in glucose_tests table
UPDATE glucose_tests as G
SET medications_intake= REGEXP_REPLACE(
                             REGEXP_REPLACE(CAST(medications as Varchar (20)),
							  '^0$', 'no'), 
                             '^1$', 'yes') 
from demographics as D
where G.participant_id= D.participant_id;

--For faster execution
create Index medications_intake_idx 
on glucose_tests (medications_intake);

--To check the final output
select * from glucose_tests;


--**************************************************************************************************************--

--Q37.Find the correlation between Vitamin D levels and GDM diagnosis.

--viewing relevant data
select * from biomarkers;
select * from glucose_tests;

--used vit D levels in visit 3 and used corr function
select
round(corr(
cast(B."25 OHD_V3" as double precision) , 
cast(G.diagnosed_gdm as double precision))
     ::numeric,2) as correlation
from biomarkers as B
inner join glucose_tests as G 
on B.participant_id = G.participant_id 
where B."25 OHD_V3" is not null 
and G.diagnosed_gdm is not null;

--observed correlation means there was no actual relationship between the Vitamin D levels and GDM diagnosis. 


--**************************************************************************************************************--

--Q38.Calculate the Cumulative percentage of Insulin medication consumption for gestational diabetic patients.

--viewing data
select * from glucose_tests
where diagnosed_gdm =1
order by participant_id;

--calculating the cumulative % of GDM patients taking Insulin as individual or combined form row wise.
select participant_id as ID,row_number() OVER (ORDER BY participant_id) as rn,
round(row_number() OVER (ORDER BY participant_id) * 100.0 / count(*) OVER (),2) as CumulativePercentage
from glucose_tests as G
where insulin_metformnin ~* 'insulin' -- '~*' matches insulin text row wise and is case insensitive 
and diagnosed_gdm = 1;



--**************************************************************************************************************--

--Q39.Count the Patient based on "BMI" category using "Width_bucket" function	

--viewing relevant data
select * from demographics
order by bmi_kgm2_v1 DESC;

--categorised the bmi into categories using width_bucket and labelled them
SELECT 
 case bucket_number
when 1 then 'underweight'
when 2 then 'normal'
when 3 then 'overweight'
when 4 then 'class 1 obesity'
when 5 then 'class 2 obesity'
else 'severe obesity'
end as BMI_category, 
bucket_number, count(ID) as patient_count
from
(SELECT
  participant_id as ID,
  bmi_kgm2_v1 as BMI,
  WIDTH_BUCKET(bmi_kgm2_v1, 15.67, 57, 6) as bucket_number
 FROM
 demographics as D) as W
group by bucket_number
ORDER by bucket_number;

--**************************************************************************************************************--

--Q40.Transform the values of edd_estimation_method to replace the abbreviations and handle nulls.

--viewing the data
select * from pregnancy_info;

create index EDD_idx 
on pregnancy_info (edd_estimation_method);

--replace the values of the column with understandable terms and handled null values

SELECT edd_estimation_method as edd_method,
       COALESCE( case edd_estimation_method
                 when 'CRL' then 'fetal body length'
                 when 'BPD' then 'fetal head diameter'
                 else null
				 end , 'unavailable')as new_edd_method
FROM pregnancy_info ;






--**************************************************************************************************************--
--Q41.Analyze the impact of GDM on infant outcomes using a composite score

--viewing data
select * from infant_outcomes;

--computing composite scores and calculating the effect of gdm_status on the composite scores of infants
SELECT gdm_status,
       round(stddev(composite_score),2) as impact_of_GDM_composite_score
from
 (select  diagnosed_gdm as gdm_status,
   round((birth_weight/4 + 
   apgar_1_min/10 +
   apgar_3_min/10-
   birth_injury_fracture -
   "Fetal hypoglycaemia 10" -
   "Fetal jaundice 10")::numeric,2)as composite_score
  from infant_outcomes as I
  JOIN
  glucose_tests as G
  using (participant_id)
  order by I.participant_id) as X
where X.gdm_status is not null
group by X.gdm_status;
--Analysis: Patients with GDM had infants with low composite score and 
--          Patients without GDM had infants with higher composite score.

--**************************************************************************************************************--

--Q42.Retrieve a list of participants who share the same estimated delivery due date 
--with at least one other participant.

--viewing the data
select * from pregnancy_info ;

--using array function to get the list of participants and fetching the count that has more than 1
select  array_agg(participant_id) as paticipants_list, edd_v1 as EDD
from pregnancy_info
group by edd_v1
having  count(participant_id)>1
order by edd_v1;

--**************************************************************************************************************--

--Q43.Of all miscarriages records what percentage were currently using tobacco or drinking and what % were not?

--viewing the data
select * from pregnancy_info ;
select * from demographics;

--calculated the counts of miscarriages first, then count of pts with habits and without habits, finally %
select round(patients_with_T_alcohol *100.00/total_miscarriages,2) as miscarriages_pt_percentage_with_T_alcohol,
       round(patients_without_T_alcohol *100.00/total_miscarriages,2) as miscarriages_pt_percentage_without_T_alcohol 
FROM
 (select 
  count(*) as total_miscarriages,
  count(participant_id) filter (where smoking='Current' or alcohol_intake=1)as patients_with_T_alcohol ,
  count(*)- count(participant_id) filter (where smoking='Current' or alcohol_intake=1) as patients_without_T_alcohol 
  from pregnancy_info as P
  JOIN
  demographics as D
  using (participant_id)
  where "Miscarried 10" =1 
  and smoking is not null 
  and alcohol_intake is not null
  );

--**************************************************************************************************************--

--Q44. Using window functions, identify all participants whose pulsation significantly considered an outlier. 
--Hint: Threshold greater than 20 bpm 

--calculating average pulse rate 
create or replace view pulse_vw as
select participant_id,
(case when pulse_v1 is null then 0 else pulse_v1 end  
	 +
 case when pulse_v3 is  null then 0 else pulse_v3 end)
	  /
nullif(case when pulse_v1 is null then 0 else 1 end
     +
 case when pulse_v3 is null then 0 else 1 end,0) as avg_pulse

from vital_signs;

-- writing CTE for ranking all the patients acc to avg_pulse
with ranked_table as  (
    select
        participant_id,
        avg_pulse,
        Dense_RANK() OVER (ORDER BY avg_pulse DESC) as final_pulse_rank
    from
        pulse_vw
)
-- Main query to retrieve data with the rank 1 as that patient is considered to be the major outlier
select participant_id,
       avg_pulse, 
	   final_pulse_rank
from
ranked_table
where avg_pulse>20; -- Threshold greater than 20 bpm 

--**************************************************************************************************************--
--Q45. Display the participant_id from 100 to 200 without using where condition.

--faster exceution
create index id_idx on screening (participant_id)


SELECT  participant_id
FROM screening as s
group by s.participant_id
having participant_id>= 100 and participant_id <=200
order by s.participant_id;

drop index id_idx;
--**************************************************************************************************************--

--Q46.Create a Backup table  by using existing demographics table.
--List the differences observed between backup table and Base table

CREATE TABLE Backup_table as SELECT * FROM demographics;

--check the data
select * from Backup_table
WHERE participant_id = 222;


--drop table Backup_table_1;
UPDATE demographics
SET ethnicity = 'Asian'
WHERE participant_id = 222;

SELECT * FROM demographics
WHERE participant_id = 222

Differences:
1. Primary key seen only in the Base TABLE but not in backup table

2. data is not updated dynalically into backup when base table is updated


--**************************************************************************************************************--

--Q47.Create function and input the participant id, 
--generate a 16-digit code with characters or digits until it reaches a total length of 16. 
--Also, display the number of characters added during this process.


--creating a function that returns table
CREATE OR REPLACE FUNCTION generate_code_func(participant_id INT)
returns table(
participant_code text,
characters_count int
)
LANGUAGE plpgsql
AS
$$
--declaring  and initialising the variables
Declare
code text := participant_id::text;
charac_to_be_added text := 'ABCDEFGHIJKLMnopqrstuvwxyz';
code_length int := 16;
charac_count int := 0;

-- logic according to the requirement i.e (code||substr) appending the substring containing characters to the participant_id 
Begin
while length(code)< code_length loop
 code := code || substr
        (charac_to_be_added,
		 floor(random() *length (charac_to_be_added)+1)::int,1);-- takes the first character according to the randomly calculated & numbered character
 
 charac_count := charac_count +1; -- gives us the count of chracters added for every loop it runs 
                                  -- before it reaches the total length i.e 16
END loop;

--returning the code and the count of characters added values as a row in the table
return query select code, charac_count;

end;

$$;

--final query for the output
select * from generate_code_func(4);

--Datacleanup
Drop FUNCTION IF EXISTS generate_code_func(INT);

--**************************************************************************************************************--
--Q48. Display the last inserted row in demographics table without using limit.

select * from demographics;

alter table demographics 
add column row_insertion_time timestamp not null default now();

select *
from demographics
where row_insertion_time = (select max(row_insertion_time) 
                            from demographics);

insert into demographics (participant_id ,
                          ethnicity ,
                          age_above_30 ,
                          height_m,
                          bmi_kgm2_v1 ,
                          smoking ,
                          alcohol_intake ,
                          family_history ,
                          highrisk ,
                          medications ,
                          nutritional_counselling)
values (611,'Asian',0,1.93,26.2,'Ex',0,0,0,0,0);
   
Delete from demographics 
where participant_id= 611;

alter table demographics
drop column row_insertion_time;

--**************************************************************************************************************--
--1Q. Display the duplicate participant_id and total number of duplicate records, 
--if present in any table. Delete the duplicate records from that table.

CREATE TABLE BC_Backup_table as SELECT * FROM body_compositions;

select * from BC_Backup_table
order by participant_id;

Delete from  BC_Backup_table as m
using (select ctid,  
       ROW_NUMBER() OVER( PARTITION BY participant_id ORDER BY participant_id ) as row_num 
	   from BC_Backup_table) as d
where m.ctid =d.ctid 
and d.row_num = 2;

--main query
Delete from  body_compositions as m
using (select ctid,  
       ROW_NUMBER() OVER( PARTITION BY participant_id ORDER BY participant_id ) as row_num 
	   from body_compositions) as d
where m.ctid =d.ctid 
and d.row_num = 2;

/**DELETE FROM
    basket a
        USING basket b
WHERE
    a.id < b.id
    AND a.fruit = b.fruit;**/


/DELETE FROM body_compositions WHERE id IN 
(SELECT participant_id FROM 
              (SELECT participant_id, ROW_NUMBER() OVER( PARTITION BY participant_id ORDER BY participant_id ) AS row_num 
               FROM body_compositions ) t 
 WHERE t. row_num > 1 );

Drop table BC_Backup_table
--**************************************************************************************************************--
--Q76.Postgres supports extensibility for JSON querying. Prove it.

/*Explanation: PostgreSQL has supported a native JSON data type since version 9.2. 
This addition allows PostgreSQL to store and manipulate JSON data efficiently.
PostgreSQL offers numerous functions and operators for handling JSON data, 
making it an efficient tool to work with JSON.*/

--Creating a table, inserting JSON DATA and viewing the table
Create Table orders ( ID serial NOT NULL PRIMARY KEY,
                      data json NOT NULL
);

Insert into orders (data) values
    (
        '{ "customer": "Raj Kumar", "items": {"product": "coffee", "qty": 6}}'
    ),
	(
        '{ "customer": "Simba", "items": {"product": "Tea", "qty": 5}}'
    ),
	(
        '{ "customer": "Rocky", "items": {"product":["soup","cake"] , "qty": 2}}'
    )
	;

select data from orders;


--Extracting the customer names from the JSON data.
--We can use the ->> operator as shown in the below PostgreSQL query for Extracting Data from JSON.
select data ->> 'customer' AS customer_name
from orders;


--filtering rows based on the content of the JSON data. 
--we can find the orders where the product is "Tea":
select data
from orders
where data -> 'items' ->> 'product' = 'Tea';


--updating a value which indicates manipulation of JSON DATA
update orders
SET data = jsonb_set(data::jsonb, '{items,product}', '"Limejuice"')
where id = 1;


--to check if the array has the given value 
select *
from orders
where (data::jsonb->'items' ->'product') ? 'soup';


--If we have an array of products, to extract the first product,
--we can use json_typeof to detect whether it is a string or an array and "0" fetches the first product

select
case
when json_typeof (data -> 'items' -> 'product') = 'string' then
                  data -> 'items' ->> 'product'
when  json_typeof(data -> 'items' -> 'product') = 'array' then
                 (data -> 'items' -> 'product') ->> 0 
else null
end as product
from orders;

--JSON data in PostgreSQL can be indexed using GIN (Generalized Inverted Index)
--significantly improving query performance for JSON data.

CREATE INDEX idx_orders_data on orders using GIN ((data::jsonb));

--JSON data in PostgreSQL can be indexed using B-tree
CREATE INDEX idx_orders_customer ON orders ((data->>'customer'));

SELECT * FROM orders
WHERE data->>'customer' = 'Raj Kumar';


drop index idx_orders_customer


--to delete the table
drop table orders;
drop index idx_orders_data;
--**************************************************************************************************************--
--**************************************************************************************************************--

--Q75. Display preeclampsia occurrence across different gestational hypertension statuses using cross tab.

--viewing the DATA
select * from maternal_health_info;
select * from screening;

--creating the extension for crosstab
CREATE EXTENSION IF NOT EXISTS tablefunc;

--creating aview to work on and filter the wanted data
create or replace VIEW GHP_vw as
select participant_id,
"Pre-eclampsia",ghp as gestational_hypertension 
from maternal_health_info m
join
screening s
using(participant_id)
where ghp is not null and "Pre-eclampsia"=1
order by participant_id;

--select * from GHP_vw 
--order by participant_id;

---- Creating 'sub' as the alias for this derived table and get the list of all the ids 
select string_agg('"' || participant_id || '" INT', ', ')
from GHP_vw as sub; 

-- for ghp it is different preeclampsia status values across all the pt idsw derived from the above sub 
select *
from crosstab($$select gestational_hypertension, participant_id, "Pre-eclampsia"
              from GHP_vw
              order by 1, 2$$, 
			  $$SELECT DISTINCT participant_id FROM GHP_vw ORDER BY 1$$) 
			  as ct (gestational_hypertension INT,
"1" INT, "2" INT, "3" INT, "4" INT, "5" INT, "6" INT, "7" INT,"8" INT, 
"10" INT, "11" INT, "12" INT, "13" INT, "14" INT, "15" INT, "16" INT, 
"18" INT, "19" INT, "20" INT, "21" INT, "22" INT, "23" INT, "24" INT, 
"25" INT, "27" INT, "28" INT, "29" INT, "30" INT, "31" INT, "32" INT, 
"33" INT, "34" INT, "36" INT, "37" INT, "38" INT, "39" INT, "40" INT, 
"41" INT, "42" INT, "44" INT, "45" INT, "46" INT, "47" INT, "49" INT, 
"51" INT, "52" INT, "53" INT, "54" INT, "55" INT, "56" INT, "57" INT, 
"58" INT, "59" INT, "60" INT, "61" INT, "62" INT, "63" INT, "64" INT, 
"65" INT, "66" INT, "67" INT, "68" INT, "69" INT, "70" INT, "71" INT, 
"72" INT, "73" INT, "74" INT, "75" INT, "76" INT, "77" INT, "78" INT, 
"79" INT, "80" INT, "81" INT, "82" INT, "85" INT, "86" INT, "87" INT, 
"88" INT, "89" INT, "90" INT, "91" INT, "92" INT, "93" INT, "94" INT, 
"95" INT, "96" INT, "97" INT, "98" INT, "99" INT, "100" INT, "101" INT, 
"102" INT, "104" INT, "105" INT, "106" INT, "107" INT, "108" INT, "109" INT, 
"110" INT, "111" INT, "112" INT, "113" INT, "114" INT, "115" INT, "116" INT, 
"117" INT, "118" INT, "119" INT, "120" INT, "121" INT, "122" INT, "123" INT, 
"124" INT, "125" INT, "126" INT, "127" INT, "128" INT, "129" INT, "130" INT, 
"131" INT, "132" INT, "133" INT, "134" INT, "135" INT, "136" INT, "137" INT, 
"138" INT, "140" INT, "141" INT, "142" INT, "143" INT, "144" INT, "145" INT,
"146" INT, "147" INT, "148" INT, "149" INT, "150" INT, "151" INT, "152" INT, 
"153" INT, "154" INT, "155" INT, "156" INT, "158" INT, "159" INT, "160" INT, 
"161" INT, "162" INT, "163" INT, "164" INT, "165" INT, "166" INT, "167" INT, 
"168" INT, "169" INT, "170" INT, "171" INT, "172" INT, "173" INT, "174" INT, 
"176" INT, "177" INT, "178" INT, "179" INT, "180" INT, "181" INT, "182" INT, 
"183" INT, "184" INT, "185" INT, "186" INT, "187" INT, "188" INT, "189" INT, 
"190" INT, "191" INT, "192" INT, "193" INT, "194" INT, "195" INT, "196" INT, 
"197" INT, "199" INT, "200" INT, "202" INT, "204" INT, "205" INT, "206" INT, 
"207" INT, "209" INT, "210" INT, "211" INT, "212" INT, "213" INT, "214" INT, 
"215" INT, "216" INT, "217" INT, "218" INT, "219" INT, "220" INT, "221" INT, 
"222" INT, "223" INT, "224" INT, "225" INT, "226" INT, "227" INT, "228" INT, 
"229" INT, "230" INT, "231" INT, "232" INT, "233" INT, "234" INT, "235" INT, 
"236" INT, "237" INT, "238" INT, "239" INT, "241" INT, "242" INT, "243" INT, 
"244" INT, "245" INT, "246" INT, "247" INT, "248" INT, "249" INT, "250" INT, 
"251" INT, "252" INT, "253" INT, "254" INT, "255" INT, "256" INT, "257" INT, 
"258" INT, "259" INT, "260" INT, "261" INT, "262" INT, "263" INT, "264" INT, 
"265" INT, "266" INT, "267" INT, "268" INT, "270" INT, "271" INT, "272" INT, 
"273" INT, "274" INT, "275" INT, "276" INT, "277" INT, "278" INT, "279" INT, 
"280" INT, "281" INT, "282" INT, "283" INT, "284" INT, "285" INT, "286" INT, 
"287" INT, "288" INT, "289" INT, "291" INT, "292" INT, "293" INT, "294" INT, 
"297" INT, "299" INT, "300" INT, "301" INT, "302" INT, "303" INT, "304" INT, 
"305" INT, "307" INT, "308" INT, "309" INT, "310" INT, "311" INT, "312" INT, 
"313" INT, "315" INT, "316" INT, "317" INT, "318" INT, "319" INT, "320" INT, 
"321" INT, "322" INT, "323" INT, "324" INT, "325" INT, "327" INT, "328" INT, 
"329" INT, "330" INT, "331" INT, "332" INT, "333" INT, "334" INT, "335" INT, 
"336" INT, "337" INT, "338" INT, "339" INT, "340" INT, "341" INT, "342" INT, 
"344" INT, "346" INT, "347" INT, "348" INT, "349" INT, "350" INT, "351" INT, 
"352" INT, "353" INT, "354" INT, "355" INT, "356" INT, "357" INT, "358" INT, 
"359" INT, "360" INT, "361" INT, "362" INT, "364" INT, "365" INT, "366" INT, 
"367" INT, "368" INT, "369" INT, "371" INT, "372" INT, "373" INT, "374" INT, 
"376" INT, "377" INT, "378" INT, "379" INT, "380" INT, "381" INT, "382" INT, 
"383" INT, "384" INT, "385" INT, "386" INT, "388" INT, "389" INT, "391" INT, 
"392" INT, "393" INT, "394" INT, "395" INT, "396" INT, "397" INT, "398" INT, 
"399" INT, "400" INT, "402" INT, "403" INT, "406" INT, "407" INT, "408" INT, 
"409" INT, "410" INT, "411" INT, "412" INT, "413" INT, "414" INT, "415" INT, 
"416" INT, "417" INT, "418" INT, "419" INT, "420" INT, "421" INT, "422" INT, 
"423" INT, "424" INT, "425" INT, "426" INT, "427" INT, "428" INT, "429" INT, 
"430" INT, "431" INT, "432" INT, "433" INT, "435" INT, "436" INT, "437" INT, 
"438" INT, "439" INT, "440" INT, "441" INT, "442" INT, "443" INT, "444" INT, 
"445" INT, "446" INT, "447" INT, "448" INT, "449" INT, "450" INT, "451" INT, 
"452" INT, "454" INT, "455" INT, "456" INT, "457" INT, "459" INT, "460" INT, 
"461" INT, "462" INT, "463" INT, "464" INT, "465" INT, "466" INT, "467" INT, 
"468" INT, "469" INT, "470" INT, "471" INT, "472" INT, "473" INT, "474" INT, 
"475" INT, "476" INT, "477" INT, "478" INT, "479" INT, "480" INT, "481" INT, 
"482" INT, "483" INT, "484" INT, "485" INT, "486" INT, "487" INT, "488" INT, 
"489" INT, "490" INT, "491" INT, "492" INT, "493" INT, "495" INT, "496" INT, 
"497" INT, "498" INT, "499" INT, "500" INT, "501" INT, "502" INT, "503" INT, 
"504" INT, "505" INT, "506" INT, "507" INT, "508" INT, "509" INT, "510" INT, 
"511" INT, "512" INT, "513" INT, "514" INT, "515" INT, "516" INT, "517" INT, 
"518" INT, "519" INT, "520" INT, "521" INT, "522" INT, "523" INT, "524" INT, 
"525" INT, "526" INT, "528" INT, "529" INT, "530" INT, "531" INT, "532" INT, 
"533" INT, "534" INT, "535" INT, "537" INT, "538" INT, "539" INT, "540" INT, 
"541" INT, "542" INT, "543" INT, "545" INT, "546" INT, "547" INT, "548" INT, 
"549" INT, "550" INT, "551" INT, "552" INT, "553" INT, "554" INT, "555" INT, 
"556" INT, "557" INT, "558" INT, "559" INT, "560" INT, "561" INT, "562" INT, 
"563" INT, "564" INT, "565" INT, "566" INT, "567" INT, "568" INT, "569" INT, 
"570" INT, "571" INT, "572" INT, "573" INT, "574" INT, "575" INT, "576" INT, 
"577" INT, "578" INT, "579" INT, "580" INT, "581" INT, "582" INT, "583" INT, 
"584" INT, "585" INT, "586" INT, "587" INT, "588" INT, "589" INT, "590" INT, 
"591" INT, "592" INT, "593" INT, "594" INT, "595" INT, "596" INT, "597" INT, 
"598" INT, "600" INT
);


SELECT * FROM SCREENING
where ghp =1

select * from maternal_health_info
where "Pre-eclampsia"=1


Drop view GHP_vw;	