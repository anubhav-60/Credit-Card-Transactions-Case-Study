select * from cc.transactions

-- Write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends.
with cte as ( 
	select sum(Amount) as total from cc.transactions
)
select City, max(Amount), round(sum(Amount/cte.total)*100,2) as per_cont from cc.transactions
join cte on 1=1
group by City
order by per_cont desc
limit 5

-- Write a query to print highest spend month and amount spent in that month for each card type.
with cte as (select monthname(Date) as Month, sum(Amount) as Spent from cc.transactions
group by monthname(Date)
order by sum(Amount) desc
limit 1
)
select Card_type, sum(Amount) as Spent from cc.transactions t
join cte on 1=1
where monthname(Date)=cte.Month
group by Card_type

-- Write a query to print the transaction details (all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends
with cte1 as (
select *, sum(Amount) over (partition by Card_type order by Date) as cum_sum
from cc.transactions
),
cte2 as (
select *, row_number() over (partition by Card_type order by Date) as ra_nk
from cte1
where cum_sum>=1000000
)
select * from cte2
where ra_nk=1

-- Write a query to find city which had lowest percentage spend for gold card type.
with cte1 as (select City, sum(Amount) as gold_spent
from cc.transactions
where Card_type='Gold'
group by City),
cte2 as (
select City, sum(Amount) as Total_spent from cc.transactions
group by City
)
select cte1.City, (cte1.gold_spent/cte2.Total_spent)*100 as percentage from cte1
join cte2 on cte2.City=cte1.City
order by percentage asc

-- Write a query to print 3 columns: city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel).
with expense_summary as (
    select city, exp_type, sum(amount) as total_spent,
        row_number() over (partition by city order by sum(amount) desc) as rn_highest,
        row_number() over (partition by city order by sum(amount) asc) as rn_lowest
    from cc.transactions
    group by city, exp_type
)
select city, max(case when rn_highest = 1 then exp_type end) as highest_expense_type, max(case when rn_lowest = 1 then exp_type end) as lowest_expense_type
from  expense_summary
group by city;


-- Write a query to find percentage contribution of spends by females for each expense type.
with female as 
(select Gender, Exp_type, sum(Amount) as Amount from cc.transactions
where gender='F'
group by Gender, Exp_type),
total as (
select Exp_type, sum(Amount) as Amount from cc.transactions
group by Exp_type
)
select female.Exp_type, (female.Amount/total.Amount)*100 as Percentage_contri
from female 
join total on female.Exp_type=total.Exp_type

-- Which card and expense type combination saw highest month over month growth in Jan-2014(Means from Dec-2013 to Jan-2014).
with cte1 as 
(select Card_type, Exp_type, Date_format(date, "%Y-%m") as month_year, sum(Amount) as t_amount from cc.transactions
where Date_format(date, "%Y-%m")='2013-12'
group by Card_type, Exp_type, month_year
),
cte2 as (
select Card_type, Exp_type, Date_format(date, "%Y-%m") as month_year, sum(Amount) as t_amount from cc.transactions
where Date_format(date, "%Y-%m")='2014-01'
group by Card_type, Exp_type, month_year
)
select cte1.Card_type, cte1.Exp_type, ((cte2.t_amount-cte1.t_amount)/ cte1.t_amount)*100 as growth_percentage
from cte1
join cte2 on cte1.Card_type=cte2.Card_type and cte1.Exp_type=cte2.Exp_type
order by growth_percentage desc

-- During weekends which city has highest total spend to total no of transaction’s ratio?
select City, sum(Amount)/count(Amount) as ratio from cc.transactions
where dayofweek(Date) in (1,7)
group by City
order by sum(Amount)/count(Amount) desc
limit 1

-- Which city took least number of days to reach its 500th transaction after first transaction in that city?
with cte1 as (
    select city, date, row_number() over (partition by city order by date) as rnk
    from transactions
),
cte2 as (
    select city, min(case when rnk = 1 then date end) as first_date, min(case when rnk = 500 then date end) as dateof500th
    from cte1
    group by city
    having count(*) >= 500
)
select city, datediff(dateof500th, first_date) as daystoreach500
from cte2
order by daystoreach500 asc
limit 1

