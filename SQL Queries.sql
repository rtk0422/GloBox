SQL Query

Que2. What type of join should we use to join the users table to the activity table?
Ans: Left join (since we want all data from user table)

Que3. What SQL function can we use to fill in NULL values?
Ans: Coalesce function.

Que4. What are the start and end dates of the experiment?
Ans: start date = 2023-01-25 and End date = 2023-02-06
      
     Query:    select min(activity.dt)as start_date,max(activity.dt) as end_date
               from activity;

Que5. How many total users were in the experiment?
Ans: total_users in experiment=48943
     
     Query:    select count(uid)as total_users
               from groups;

Que6.  How many users were in the control and treatment groups?
Ans:    Control(A):24343 and  Treatment(B):24600

     Query:   
                      select g.group, count(uid) as total_users
                         From groups g
                        group by g.group


Que7. What was the conversion rate of all users?
Ans: 4.28%

     Query:   
select Round (cast(count(distinct uid) as decimal)/cast(count(distinct id) as     decimal)*100,2) as Conversion_rate 
from users u left join activity a on u.id = a.uid

Que8. What is the user conversion rate for the control and treatment groups?
Ans: Control(A): 3.92%  and  Treatment(B): 4.63%

Query:    
select g.group,
Round(cast(count(distinct a.uid) as decimal)/cast(count(distinct u.id) as decimal)*100,2) as Conversion_rate
                from users u
                left join activity a on u.id = a.uid
               left join groups g on u.id=g.uid
group by g.group




Que9. What is the average amount spent per user for the control and treatment groups, including   users who did not convert?
Ans: Control(A): 3.37  and  Treatment(B): 3.39

  
 Query:  

with users spent as(
              select 
              u.id as userid,
              sum (COALESCE (a. spent,0)) as total_spent
              from activity a 
              right join users u on a.uid = u.id
              group by u.id
              )

              select
              g.group,
              round(avg(total_spent),2) as avg_spent
              from users_spent u left join groups g on u.userid=g.uid
              group by g.group


Que10. Why does it matter to include users who did not convert when     calculating the average amount spent per user? (this data used to calculate the Hypothesis test in excel spreadsheet)
QUERY:   
       SELECT u.id AS user_id, u.country, u.gender, g.device,g.group,
                     SUM (COALESCE (a.spent, 0)) AS total_spent_usd
      FROM users AS u
      LEFT JOIN groups AS g ON u.id = g.uid
      LEFT JOIN activity AS a ON u.id = a.uid
     GROUP BY u.id, u.country, u.gender, g.device, g.group;









* This data used for the Tableau visualisation: (4 tables viz., Globox, Globox 2, Globox 3, Globox 4)

1. Globox: (used to visualize the conversion_rate, avg amount spent, avg amount distribution per user , gender wise, device wise, country wise distribution)
  Query: 
 Select
 distinct groups.uid as user_id, users.country,coalesce(users.gender,'Unknown')    as gender, coalesce(groups.device,'Unknown') as device, groups.group sum(coalesce(activity.spent,0)) as total_spent_usd, sum(round(coalesce(activity.spent,0) - mod(coalesce(activity.spent,0),10),0)) total_spent, Round(round(cast(count(distinct activity.uid) as decimal))/round(cast(count(distinct users.id)as decimal),2)*100,2) as conversion_rate
from groups 	
      left join activity on groups.uid=activity.uid
left join users on groups.uid=users.id.
group by
 groups.uid, users.country,  users.gender, groups.device, groups.group


















Novelty Effect Analysis:

2. Globox 2: (used to visualise Novelty Effect : AVG Amount Spent over time )

Query: 
select 
                                               distinct groups.uid as user_id,
       groups.join_dt as Join_date,
       users.country,
       coalesce(users.gender,'Unknown') as gender,
       coalesce(groups.device,'Unknown') as device,
       groups.group,
       sum (coalesce (activity. spent,0)) as total_spent_usd,
  sum (round (coalesce (activity. spent,0) -   mod (coalesce (activity. spent,0),10),0)) total_spent,
case when sum (coalesce (activity. spent,0)) =0 then 0 else 1 end as        Converted
from groups
left join activity on 
groups.uid=activity.uid
left join users on
groups.uid=users.id
group by 
 groups.uid,
   			 users.country,
 			 users.gender,
 groups.device,
 groups.group




3. Globox 3: (used to visualise Novelty Effect: Conversion rate over time and converted users average amount spent over time):

Query:
select 
g.join_dt,g.group,
count (distinct u.id) as Total_Users,
count (distinct a.uid) as Paid_user,
SUM(a.spent) as Total_Spent,
CAST (count (distinct a.uid) as Decimal)/CAST(count(distinct u.id) as Decimal) as Conversion_Rate,
CAST(SUM(a.spent) as Decimal)/CAST(count(distinct u.id) as Decimal) as Average_Amount_Spent,
CAST(SUM(a.spent) as Decimal)/CAST(count(distinct a.uid) as Decimal) as Converted_Average_Spent
from users u 
left join activity a on u.id = a.uid
join groups g on u.id = g.uid
group by
       g.join_dt,g.group




4. Globox 4: (used to visualise Novelty Effect: Number of converted users after joining the experiment):
Query:
select 
min(g.join_dt) as Join_date,
       min(a.dt) as date_converted,
case when min(a.dt)-min(g.join_dt) =0 then 'Same Day'
 when min(a.dt)-min(g.join_dt) =1 then '1 day'
        else concat(min(a.dt)-min(g.join_dt),' days') end as date_diff,
  g.group,
  g.uid as user_id,
  sum(a.spent) as Total_spent
from groups g
left join users u on g.uid=u.id
join activity a on g.uid=a.uid
group by 
      g.uid, g.group
Confidence Interval

Query: 1. for Average Spent Confidence Interval
      
with cte as(
SELECT
      u.id AS user_id, u.country, u.gender, g.device,g.group,
      SUM(COALESCE(a.spent, 0)) AS total_spent_usd,
                                                          CASE WHEN SUM(a.spent) > 0 then 1 else 0 end as converted
FROM users AS u
LEFT JOIN groups AS g ON u.id = g.uid
LEFT JOIN activity AS a ON u.id = a.uid
GROUP BY
        u.id, u.country, u.gender, g.device, g.group
),
groupA_cte as(
select 
AVG(a.total_spent_usd) as groupA_avg_spent,
count(a.total_spent_usd) as groupA_total_spent,
sum(converted) as groupA_total_converted,
ROUND(STDDEV(a.total_spent_usd),2) as groupA_std_dev_spent,
ROUND(CAST(SQRT(COUNT(a.total_spent_usd))AS numeric),2) as groupA_sqrt_spent,
ROUND(STDDEV(a.total_spent_usd),2) / ROUND(CAST(SQRT(COUNT(a.total_spent_usd))AS numeric),2) as groupA_standard_error
from cte a
where 
a.group='A'),
groupB_cte as(
  select 
AVG(a.total_spent_usd) as groupB_avg_spent,
count(a.total_spent_usd) as groupB_total_spent,
ROUND(STDDEV(a.total_spent_usd),2) as groupB_std_dev_spent,
ROUND(CAST(SQRT(COUNT(a.total_spent_usd))AS numeric),2) as groupB_sqrt_spent,
ROUND(ROUND(STDDEV(a.total_spent_usd),2) / ROUND(CAST(SQRT(COUNT(a.total_spent_usd))AS numeric),2),3) as groupB_standard_error
from cte a
where 
      a.group='B')


select 
ROUND(groupA_avg_spent,2) as groupA_avg_spent,
groupA_total_spent as groupA_total_users,
groupA_std_dev_spent,
groupA_sqrt_spent,
ROUND(groupA_standard_error,2) as groupA_standard_error ,
ROUND(groupB_avg_spent,2) as groupA_avg_spent,
groupB_total_spent as groupA_total_users,
groupB_std_dev_spent,
groupB_sqrt_spent,
ROUND(groupB_standard_error,2) as groupB_standard_error,
ROUND(CAST(SQRT((POWER(groupB_std_dev_spent,2)/groupB_total_spent)+(POWER(groupA_std_dev_spent,2)/groupA_total_spent))AS numeric),3) AS Standared_Error
,ROUND((groupB_avg_spent-groupA_avg_spent),3) as "mean differnece"
,1.96 as "critical value",
ROUND((ROUND((groupB_avg_spent-groupA_avg_spent),3)) - (1.96*SQRT((POWER(groupA_standard_error,2)+POWER(groupB_standard_error,2)))),3) AS lower_bound,
ROUND((ROUND((groupB_avg_spent-groupA_avg_spent),3)) + (1.96*SQRT((POWER(groupA_standard_error,2)+POWER(groupB_standard_error,2)))),3) AS upper_bound
from  groupA_cte,groupB_cte



Query: 2. For Conversion Rate Confidence Interval

with cte as(
SELECT
u.id AS user_id, u.country, u.gender,    g.device,g.group,
                                                                  SUM(COALESCE(a.spent, 0)) AS total_spent_usd,
  CASE WHEN SUM(a.spent) > 0 then 1 else 0 end as converted
FROM
          users AS u
LEFT JOIN groups AS g ON u.id = g.uid
LEFT JOIN activity AS a ON u.id = a.uid
GROUP BY
              u.id, u.country, u.gender, g.device, g.group
),
groupA_convt_cte AS (
select 
count(converted) groupA_total_users,
sum(converted) as groupA_total_converted,
cast(sum(converted) as decimal)/cast(count(a.total_spent_usd) as decimal)*100 AS groupA_converion_Rate
from cte a
where 
a.group='A'),
groupB_convt_cte AS (
select 
count(converted) groupB_total_users,
sum(converted) as groupB_total_converted,
cast(sum(converted) as decimal)/cast(count(a.total_spent_usd) as decimal)*100 AS groupB_converion_Rate
from cte a
where
             a.group='B'),cte_se as(
select 
groupA_total_users,ROUND(groupA_converion_Rate,2) as groupA_converion_Rate,
 groupB_total_users,ROUND(groupB_converion_Rate,2) as groupB_converion_Rate,
ROUND(cast((groupA_total_converted+groupB_total_converted) as decimal)/cast((groupA_total_users+groupB_total_users) as decimal),4) AS Total_Converted_Rate,
ROUND((groupB_converion_Rate-groupA_converion_Rate)/100,4) as conversion_difference,
ROUND(sqrt(cast((groupA_total_converted+groupB_total_converted) as decimal)/cast((groupA_total_users+groupB_total_users) as decimal)
      *(1-(cast((groupA_total_converted+groupB_total_converted) as decimal))/cast((groupA_total_users+groupB_total_users) as decimal))
*((1/cast(groupA_total_users as decimal))+(1/cast(groupB_total_users as decimal))) ),4)  Total_standard_error 
from 
             groupA_convt_cte,groupB_convt_cte)

select
*,
ROUND((conversion_difference-(1.95*Total_standard_error))*100,2) AS lower_bound,
ROUND((conversion_difference+(1.95*Total_standard_error))*100,2) AS upper_bound
from cte_se

