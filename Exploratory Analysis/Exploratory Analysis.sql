

select *
from [dbo].[credit_applications]

select *
from [dbo].[transactions_fintech]

select *
from [dbo].[user_activity_retention]

select *
from user_events_funnel

Select *
from [dbo].[users_cohort]


/* duplicate check */


Select c.user_id,
count (*) as dup
from [dbo].[users_cohort] as c
group by c.user_id
having count (*) > 1


Select event_id,
count (*) as dup
from user_events_funnel
group by event_id
having count (*) > 1


Select activity_id,
count (*) as dup
from [dbo].[user_activity_retention]
group by activity_id
having count (*) > 1


Select transaction_id,
count (*) as dup
from [dbo].[transactions_fintech]
group by transaction_id
having count (*) > 1



Select application_id,
count (*) as dup
from [dbo].[credit_applications]
group by application_id
having count (*) > 1

/* outliers check */

Select
Count(*) as total_rows
from [dbo].[credit_applications]
where annual_income <= 0


Select
Count(*) as total_rows
from [dbo].[credit_applications]
where requested_amount <= 0

Select
Count(*) as total_rows
from [dbo].[transactions_fintech]
where amount <= 0


Select
Count(*) as total_rows
from [dbo].[user_activity_retention]
where session_duration_minutes <= 0 or pages_viewed <= 0 or actions_taken < 0


Select
Count(*) as total_rows
from [dbo].[users_cohort]
where age_group = 'na' or total_lifetime_value <= 0


/* General inforamtion */


with dataset_summary as  ( 
select count (*) as total_records, 
count (distinct user_id) as unique_costumers,
min (application_date) as frist_application,
max (application_date) as last_application,
max (requested_amount) as max_requested,
min (requested_amount) as min_requested
from [dbo].[credit_applications])

Select * from dataset_summary


/* General financial information */

Select
employment_status,
loan_purpose,
credit_score,
count (*) as total_applications,
sum(annual_income) as total_annual_income,
round(avg(annual_income),2) as average_annual_income,
round(avg(requested_amount),2) as average_requested_amount,
round (avg (credit_score), 2) as average_credit_score
from [dbo].[credit_applications]
group by employment_status, loan_purpose, credit_score
order by total_applications desc


/* 7-day rolling average of transaction volume and amount */

with daily_transactions as (
    select 
    [transaction_type],
        cast(timestamp as date) as transaction_date,
        count(*) as daily_count,
        sum(amount) as daily_amount,
        avg(amount) as avg_transaction_amount
    from [dbo].[transactions_fintech]
    where status = 'completed' and is_fraud = 0 
    group by cast(timestamp as date) , [transaction_type]
)
select 
[transaction_type],
    transaction_date,
    daily_count,
    daily_amount,
    avg_transaction_amount,
    -- 7-day rolling average
    avg(daily_count) over (order by transaction_date 
                           rows between 6 preceding and current row) as rolling_avg_count_7d,
    avg(daily_amount) over (order by transaction_date 
                             rows between 6 preceding and current row) as rolling_avg_revenue_7d,
    -- 30-day rolling average
    avg(daily_count) over (order by transaction_date 
                           rows between 29 preceding and current row) as rolling_avg_count_30d,
    avg(daily_amount) over (order by transaction_date 
                             rows between 29 preceding and current row) as rolling_avg_revenue_30d
from daily_transactions
order by transaction_date;



/* Monthly application trends */

select month (application_date) as 'Month',
count (*) as credit_applications,
round (sum(requested_amount), 2) as requested_amount,
round(avg(requested_amount),2) as average_requested_amount,
count (distinct user_id) as unique_costumers
from [dbo].[credit_applications]
group by month (application_date)
order by requested_amount desc;


/* calculate mom growth for transactions */

with monthly_metrics as (
    select 
        year(timestamp) as year,
        month(timestamp) as month,
        count(*) as total_transactions,
        sum(amount) as total_revenue,
        count(distinct user_id) as unique_users
    from [dbo].[transactions_fintech]
    where status = 'completed' and is_fraud = 0
    group by year(timestamp), month(timestamp)
)
select 
    year,
    month,
    total_transactions,
    total_revenue,
    unique_users,
    -- previous month values
    lag(total_transactions, 1) over (order by year, month) as prev_month_transactions,
    lag(total_revenue, 1) over (order by year, month) as prev_month_revenue,
    -- mom growth rates
    round(((total_transactions * 1.0 / lag(total_transactions, 1) over (order by year, month)) - 1) * 100, 2) as mom_transaction_growth_pct,
    round(((total_revenue / lag(total_revenue, 1) over (order by year, month)) - 1) * 100, 2) as mom_revenue_growth_pct,
    -- year-over-year comparison
    lag(total_transactions, 12) over (order by year, month) as yoy_transactions,
    round(((total_transactions * 1.0 / lag(total_transactions, 12) over (order by year, month)) - 1) * 100, 2) as yoy_growth_pct
from monthly_metrics
order by year, month;


/* weekly trend analysis for credit applications */

with weekly_applications as (
    select 
        datepart(year, application_date) as year,
        datepart(week, application_date) as week,
        count(*) as total_applications,
        sum(case when is_approved = 'TRUE' then 1 else 0 end) as approved_count,
        avg(requested_amount) as avg_requested,
        avg(case when is_approved = 'TRUE' then requested_amount else null end) as avg_approved_amount
    from [dbo].[credit_applications]
    group by datepart(year, application_date), datepart(week, application_date)
)
select 
    year,
    week,
    total_applications,
    approved_count,
    round((approved_count * 100.0 / total_applications), 2) as approval_rate,
    round(avg_requested, 2) as avg_requested,
    -- 4-week moving average
    round(avg(total_applications) over (order by year, week 
                                        rows between 3 preceding and current row), 2) as moving_avg_4w,
    -- week-over-week change
    total_applications - lag(total_applications, 1) over (order by year, week) as wow_change,
    -- cumulative applications
    sum(total_applications) over (partition by year order by week) as ytd_applications
from weekly_applications
order by year, week;



/* identify day of week and hour patterns */

with transaction_patterns as (
    select 
        datename(weekday, timestamp) as day_of_week,
        datepart(weekday, timestamp) as day_num,
        datepart(hour, timestamp) as hour_of_day,
        count(*) as transaction_count,
        sum(amount) as total_amount,
        avg(amount) as avg_amount
    from [dbo].[transactions_fintech]
    where status = 'completed' and is_fraud = 0
    group by datename(weekday, timestamp), datepart(weekday, timestamp), datepart(hour, timestamp)
)
select 
    day_of_week,
    hour_of_day,
    transaction_count,
    round(avg_amount, 2) as avg_amount,
    -- compare to overall average
    round((avg_amount / avg(avg_amount) over () - 1) * 100, 2) as pct_diff_from_avg,
    -- rank busiest hours per day
    rank() over (partition by day_of_week order by transaction_count desc) as hour_rank_by_day
from transaction_patterns
order by day_num, hour_of_day;



/* Costumer segmentation */

with customer_metrics as ( 
select USER_ID,
avg(DATEDIFF (day, application_date, approval_date)) as avg_approval_time,
count (*) as frequency,
sum (requested_amount) as requested_value,
round(avg(requested_amount), 2) as average_requested_amount
from [dbo].[credit_applications]
group by user_id
)
select 
case when avg_approval_time <= 5 and frequency >= 2 then 'vip'	
	 when  avg_approval_time <= 10 and frequency >= 1 then 'good client'
	 when avg_approval_time <= 20 and frequency >= 1 then 'normal client'
		  else 'bad client'
end as customer_segment,
count (*) as customer_count,
round(avg(average_requested_amount),2) as average_requested_value,
round(avg(avg_approval_time),1) as avg_days_to_approval
from customer_metrics
group by case when avg_approval_time <= 5 and frequency >= 2 then 'vip'	
	 when  avg_approval_time <= 10 and frequency >= 1 then 'good client'
	 when avg_approval_time <= 20 and frequency >= 1 then 'normal client'
		  else 'bad client'
		  end;



/* Number & amount transaction per hour*/

select datepart(hour,[timestamp]) as hour,
transaction_type,
round (avg(amount),2) as average_ammount,
count (*) as total_transactions
from [dbo].[transactions_fintech]
where status = 'completed'
group by datepart(hour,[timestamp]), transaction_type
order by average_ammount desc;


/* Number & amount transactions per day*/


select datepart(day,[timestamp]) as day,
transaction_type,
round (avg(amount),2) as average_ammount,
count (*) as total_transactions
from [dbo].[transactions_fintech]
where status = 'completed'
group by datepart(day,[timestamp]) , transaction_type
order by average_ammount desc;


/* Number & amount transactions per day by merchant*/

select datepart(day,[timestamp]) as day,
merchant_category,
round (avg(amount),2) as average_ammount,
count (*) as total_transactions
from [dbo].[transactions_fintech]
where status = 'completed'
group by datepart(day,[timestamp]), merchant_category
order by average_ammount desc;


/* Number & amount transactions per day by payment method*/


Select transaction_type,
payment_method,
count (*) as total_transactions,
sum (amount) as total_amount
from [dbo].[transactions_fintech]
where status = 'completed'
group by transaction_type, payment_method
order by transaction_type asc, total_amount desc;



/* Fraudulent transactions*/


select payment_method,
sum ( amount) as total_amount,
Transaction_type,
Count (*) as total_transactions
from [dbo].[transactions_fintech]
where is_fraud = 1 and status = 'failed'
group by payment_method , transaction_type
order by payment_method asc, total_amount desc;




/* fraudulent transactions value*/

with fraudulent_revenue as (
select f.payment_method,
year (c.approval_date) as year,
sum (f.amount) as total_amount,
f.Transaction_type,
Count (*) as total_transactions
from [dbo].[transactions_fintech] as f
join [dbo].[credit_applications] as c
on c.user_id = f.user_id
where is_fraud = 1 and status = 'completed'
group by f.payment_method, f.transaction_type , c.approval_date
)
Select YEAR,
sum (total_amount) as total_fraudulent_transactions_value
from fraudulent_revenue
group by YEAR
order by total_fraudulent_transactions_value desc


/* potential fraudulent transactions*/


select payment_method,
sum ( amount) as total_amount,
Transaction_type,
Count (*) as total_transactions
from [dbo].[transactions_fintech]
where is_fraud = 1 and status = 'failed'
group by payment_method , transaction_type
order by payment_method asc, total_amount desc;


/* did longer sections generate fraudulent transactions?*/


select f.payment_method,
sum (f.amount) as total_amount,
f.transaction_type,
sum(r.session_duration_minutes) as total_time_in_session,
Count (*) as total_transactions
from [dbo].[transactions_fintech] as f
join [dbo].[user_activity_retention] as r
on f.user_id = r.user_id
where f.is_fraud = 1 and status = 'completed'
group by f.payment_method , f.transaction_type
order by payment_method asc, total_amount desc;


select f.payment_method,
sum (f.amount) as total_amount,
f.transaction_type,
sum(r.session_duration_minutes) as total_time_in_session,
Count (*) as total_transactions
from [dbo].[transactions_fintech] as f
join [dbo].[user_activity_retention] as r
on f.user_id = r.user_id
where f.is_fraud = 0 and status = 'completed'
group by f.payment_method , f.transaction_type
order by payment_method asc, total_amount desc;



/* track fraud rate trends over time */

with daily_fraud_metrics as (
    select 
        cast(timestamp as date) as date,
        count(*) as total_transactions,
        sum(case when is_fraud = 1 then 1 else 0 end) as fraud_count,
        sum(case when is_fraud = 1 then amount else 0 end) as fraud_amount,
        sum(amount) as total_amount
    from [dbo].[transactions_fintech]
    where status = 'completed'
    group by cast(timestamp as date)
)
select 
    date,
    fraud_count,
    total_transactions,
    round((fraud_count * 100.0 / total_transactions), 2) as fraud_rate_pct,
    round(fraud_amount, 2) as fraud_amount,
    -- 7-day rolling fraud rate
    round(avg(fraud_count * 100.0 / total_transactions) over (
        order by date rows between 6 preceding and current row), 2) as rolling_fraud_rate_7d,
    -- detect spikes (fraud rate > 2x rolling average)
    case 
        when (fraud_count * 100.0 / total_transactions) > 
             2 * avg(fraud_count * 100.0 / total_transactions) over (
                 order by date rows between 6 preceding and current row)
        then 'SPIKE'
        else 'NORMAL'
    end as fraud_alert
from daily_fraud_metrics
order by date;


/* fraud analysis by time, amount, and payment method combinations */

select 
    case 
        when datepart(hour, timestamp) between 0 and 5 then 'late_night'
        when datepart(hour, timestamp) between 6 and 11 then 'morning'
        when datepart(hour, timestamp) between 12 and 17 then 'afternoon'
        when datepart(hour, timestamp) between 18 and 21 then 'evening'
        else 'night'
    end as time_period,
    
    case 
        when amount < 100 then 'small'
        when amount < 500 then 'medium'
        when amount < 1000 then 'large'
        else 'very_large'
    end as amount_category,
    
    payment_method,
    merchant_category,
    
    count(*) as total_transactions,
    count(case when is_fraud = 1 then 1 end) as fraud_transactions,
    round(count(case when is_fraud = 1 then 1 end) * 100.0 / count(*), 2) as fraud_rate_pct,
    round(avg(amount), 2) as avg_amount,
    round(sum(case when is_fraud = 1 then amount else 0 end), 2) as total_fraud_amount

from [dbo].[transactions_fintech]
where status = 'completed'
group by 
    case 
        when datepart(hour, timestamp) between 0 and 5 then 'late_night'
        when datepart(hour, timestamp) between 6 and 11 then 'morning'
        when datepart(hour, timestamp) between 12 and 17 then 'afternoon'
        when datepart(hour, timestamp) between 18 and 21 then 'evening'
        else 'night'
    end,
    case 
        when amount < 100 then 'small'
        when amount < 500 then 'medium'
        when amount < 1000 then 'large'
        else 'very_large'
    end,
    payment_method,
    merchant_category
having count(*) > 10
order by fraud_rate_pct desc;


/* more time in session generates more actions ? */

select r.pages_viewed,
r.device_type,
sum(r.session_duration_minutes) as total_time_in_session,
Count (r.actions_taken) as total_actions_taken
from [dbo].[user_activity_retention] as r
group by r.pages_viewed, r.device_type
order by total_actions_taken desc;

/* what events caused the bigger sessions ? */


select r.pages_viewed,
r.device_type,
f.event_type,
sum(r.session_duration_minutes) as total_time_in_session,
Count (r.actions_taken) as total_actions_taken
from [dbo].[user_activity_retention] as r
join [dbo].[user_events_funnel] as f
on r.user_id = f.user_id
group by r.pages_viewed, r.device_type ,f.event_type
order by  total_time_in_session desc;


/* monthly cohort retention analysis frist 4 months */

with user_cohorts as (
    select 
        user_id,
        datefromparts(year(signup_date), month(signup_date), 1) as cohort_month
    from [dbo].[users_cohort]
),
user_activity as (
    select distinct
        user_id,
        datefromparts(year(activity_date), month(activity_date), 1) as activity_month
    from [dbo].[user_activity_retention]
)
select 
    c.cohort_month,
    count(distinct c.user_id) as cohort_size,
    -- month 0 (signup month)
    count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 0 
          then c.user_id end) as month_0,
    -- month 1
    count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 1 
          then c.user_id end) as month_1,
    -- month 2
    count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 2 
          then c.user_id end) as month_2,
    -- month 3
    count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 3 
          then c.user_id end) as month_3,
    -- retention rates
    round(count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 1 
          then c.user_id end) * 100.0 / count(distinct c.user_id), 2) as month_1_retention_pct,
    round(count(distinct case when datediff(month, c.cohort_month, a.activity_month) = 3 
          then c.user_id end) * 100.0 / count(distinct c.user_id), 2) as month_3_retention_pct
from user_cohorts c
left join user_activity a on c.user_id = a.user_id
group by c.cohort_month
order by c.cohort_month;


/* what age group generated ask for bigger values ? */

select c.age_group,
a.requested_amount,
a.annual_income
from [dbo].[credit_applications] as a
join [dbo].[users_cohort] as c
on a.user_id = c.user_id
group by c.age_group , a.requested_amount, a.annual_income
order by a.requested_amount desc;

/* The clients that ask for more money are the ones that have the most transactions in value and number? */

select c.loan_purpose,
t.merchant_category,
t.transaction_type,
sum (c.requested_amount) as total_requested,
sum (t.amount) as  total_amount_transacted,
count (distinct t.transaction_id) as total_transactions
from [dbo].[credit_applications] as c
join [dbo].[transactions_fintech] as t
on c.user_id = t.user_id
where t.is_fraud = 0 
group by c.loan_purpose, t.merchant_category, t.transaction_type
order by t.transaction_type asc, total_requested desc


/* complete user journey: signup → activity → funnel → transactions → credit */

with user_base as (
    select 
        u.user_id,
        u.signup_date,
        u.signup_channel,
        u.country,
        u.age_group,
        u.account_type,
        u.is_verified,
        u.total_lifetime_value,
        datediff(day, u.signup_date, getdate()) as days_since_signup
    from [dbo].[users_cohort] u
),
user_activity_metrics as (
    select 
        user_id,
        count(distinct activity_date) as total_active_days,
        sum(session_duration_minutes) as total_session_minutes,
        avg(session_duration_minutes) as avg_session_minutes,
        sum(pages_viewed) as total_pages_viewed,
        sum(actions_taken) as total_actions_taken,
        min(activity_date) as first_activity_date,
        max(activity_date) as last_activity_date,
        datediff(day, min(activity_date), max(activity_date)) as activity_span_days
    from [dbo].[user_activity_retention]
    group by user_id
),
funnel_metrics as (
    select 
        user_id,
        count(distinct session_id) as total_sessions,
        count(distinct case when event_type = 'app_open' then session_id end) as app_opens,
        count(distinct case when event_type = 'view_homepage' then session_id end) as homepage_views,
        count(distinct case when event_type = 'view_product' then session_id end) as product_views,
        count(distinct case when event_type = 'add_to_cart' then session_id end) as add_to_carts,
        count(distinct case when event_type = 'begin_checkout' then session_id end) as checkouts_started,
        count(distinct case when event_type = 'add_payment_method' then session_id end) as payment_methods_added,
        count(distinct case when event_type = 'submit_order' then session_id end) as orders_submitted,
        count(distinct case when event_type = 'order_confirmed' then session_id end) as orders_confirmed,
        min(timestamp) as first_event_date,
        max(timestamp) as last_event_date
    from [dbo].[user_events_funnel]
    group by user_id
),
transaction_metrics as (
    select 
        user_id,
        count(*) as total_transactions,
        count(case when status = 'completed' then 1 end) as completed_transactions,
        count(case when status = 'failed' then 1 end) as failed_transactions,
        count(case when is_fraud = 1 then 1 end) as fraud_transactions,
        sum(case when status = 'completed' and is_fraud = 0 then amount else 0 end) as total_transaction_amount,
        avg(case when status = 'completed' and is_fraud = 0 then amount end) as avg_transaction_amount,
        min(timestamp) as first_transaction_date,
        max(timestamp) as last_transaction_date
    from [dbo].[transactions_fintech]
    group by user_id
),
credit_metrics as (
    select 
        user_id,
        count(*) as total_applications,
        count(case when is_approved = 'TRUE' then 1 end) as approved_applications,
        sum(requested_amount) as total_requested_amount,
        avg(requested_amount) as avg_requested_amount,
        avg(credit_score) as avg_credit_score,
        count(case when default_flag = 'TRUE' then 1 end) as defaults,
        min(application_date) as first_application_date,
        max(application_date) as last_application_date,
        avg(datediff(day, application_date, approval_date)) as avg_approval_days
    from [dbo].[credit_applications]
    group by user_id
)
select 
    ub.user_id,
    ub.signup_date,
    ub.signup_channel,
    ub.country,
    ub.age_group,
    ub.account_type,
    ub.is_verified,
    ub.total_lifetime_value,
    ub.days_since_signup,
    
    -- activity metrics
    coalesce(ua.total_active_days, 0) as active_days,
    coalesce(ua.avg_session_minutes, 0) as avg_session_minutes,
    coalesce(ua.total_pages_viewed, 0) as total_pages_viewed,
    coalesce(ua.total_actions_taken, 0) as total_actions_taken,
    datediff(day, ub.signup_date, ua.first_activity_date) as days_to_first_activity,
    datediff(day, ua.last_activity_date, getdate()) as days_since_last_activity,
    
    -- funnel metrics
    coalesce(fm.total_sessions, 0) as total_sessions,
    coalesce(fm.orders_confirmed, 0) as orders_confirmed,
    case 
        when fm.app_opens > 0 then round(fm.orders_confirmed * 100.0 / fm.app_opens, 2)
        else 0 
    end as conversion_rate,
    datediff(day, ub.signup_date, fm.first_event_date) as days_to_first_event,
    
    -- transaction metrics
    coalesce(tm.total_transactions, 0) as total_transactions,
    coalesce(tm.completed_transactions, 0) as completed_transactions,
    coalesce(tm.total_transaction_amount, 0) as total_spent,
    coalesce(tm.avg_transaction_amount, 0) as avg_transaction_amount,
    coalesce(tm.fraud_transactions, 0) as fraud_count,
    datediff(day, ub.signup_date, tm.first_transaction_date) as days_to_first_transaction,
    
    -- credit metrics
    coalesce(cm.total_applications, 0) as credit_applications,
    coalesce(cm.approved_applications, 0) as approved_credits,
    coalesce(cm.total_requested_amount, 0) as total_credit_requested,
    coalesce(cm.avg_credit_score, 0) as avg_credit_score,
    coalesce(cm.defaults, 0) as credit_defaults,
    
    -- user classification
    case 
        when ua.last_activity_date < dateadd(day, -30, getdate()) then 'churned'
        when ua.last_activity_date >= dateadd(day, -7, getdate()) then 'active'
        when ua.last_activity_date >= dateadd(day, -30, getdate()) then 'at_risk'
        else 'inactive'
    end as user_status,
    
    case 
        when tm.completed_transactions >= 10 and ub.total_lifetime_value >= 1000 then 'high_value'
        when tm.completed_transactions >= 5 and ub.total_lifetime_value >= 500 then 'medium_value'
        when tm.completed_transactions >= 1 then 'low_value'
        else 'no_transactions'
    end as value_segment,
    
    case 
        when ua.total_active_days >= 30 and tm.completed_transactions >= 5 then 'engaged'
        when ua.total_active_days >= 10 and tm.completed_transactions >= 1 then 'moderate'
        when ua.total_active_days >= 1 then 'low_engagement'
        else 'no_engagement'
    end as engagement_level

from user_base ub
left join user_activity_metrics ua on ub.user_id = ua.user_id
left join funnel_metrics fm on ub.user_id = fm.user_id
left join transaction_metrics tm on ub.user_id = tm.user_id
left join credit_metrics cm on ub.user_id = cm.user_id
order by ub.total_lifetime_value desc;


/* compare successful vs churned users to identify key drivers */

with user_journey as (
    select 
        ub.user_id,
        ub.signup_channel,
        ub.country,
        ub.age_group,
        ub.account_type,
        ub.total_lifetime_value,
        coalesce(ua.total_active_days, 0) as active_days,
        coalesce(ua.avg_session_minutes, 0) as avg_session_minutes,
        coalesce(fm.orders_confirmed, 0) as orders_confirmed,
        coalesce(tm.completed_transactions, 0) as completed_transactions,
        coalesce(tm.total_transaction_amount, 0) as total_spent,
        case 
            when ua.last_activity_date < dateadd(day, -30, getdate()) or ua.last_activity_date is null then 'churned'
            else 'active'
        end as user_status
    from [dbo].[users_cohort] ub
    left join (select user_id, count(distinct activity_date) as total_active_days, 
                      avg(session_duration_minutes) as avg_session_minutes,
                      max(activity_date) as last_activity_date
               from [dbo].[user_activity_retention] group by user_id) ua on ub.user_id = ua.user_id
    left join (select user_id, count(distinct case when event_type = 'order_confirmed' then session_id end) as orders_confirmed
               from [dbo].[user_events_funnel] group by user_id) fm on ub.user_id = fm.user_id
    left join (select user_id, count(case when status = 'completed' then 1 end) as completed_transactions,
                      sum(case when status = 'completed' and is_fraud = 0 then amount else 0 end) as total_transaction_amount
               from [dbo].[transactions_fintech] group by user_id) tm on ub.user_id = tm.user_id
)
select 
    user_status,
    count(*) as user_count,
    round(avg(total_lifetime_value), 2) as avg_ltv,
    round(avg(active_days), 2) as avg_active_days,
    round(avg(avg_session_minutes), 2) as avg_session_duration,
    round(avg(orders_confirmed), 2) as avg_orders,
    round(avg(completed_transactions), 2) as avg_transactions,
    round(avg(total_spent), 2) as avg_total_spent,
    
    -- channel distribution
    count(case when signup_channel = 'organic' then 1 end) as organic_count,
    count(case when signup_channel = 'paid_search' then 1 end) as paid_search_count,
    count(case when signup_channel = 'referral' then 1 end) as referral_count,
    count(case when signup_channel = 'social' then 1 end) as social_count,
    
    -- account type distribution
    count(case when account_type = 'premium' then 1 end) as premium_count,
    count(case when account_type = 'enterprise' then 1 end) as enterprise_count,
    count(case when account_type = 'free' then 1 end) as free_count

from user_journey
group by user_status
order by user_status;
