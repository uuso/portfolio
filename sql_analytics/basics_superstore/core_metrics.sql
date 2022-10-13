--postgres

--Overview (обзор ключевых метрик)
--Total Sales
--Total Profit
select sum(sales), sum(profit) from orders;

--Profit Ratio
with profit_stats as (
	select 
		(select count(*) cnt from orders where Profit >= 0) as Profitable		
		,(select count(*) cnt from orders where Profit < 0) as Improfitable
)
select 
	Profitable, Improfitable, ROUND(1.0*Profitable/Improfitable, 2) as "Profit Ratio"
	from profit_stats;


--Profit per Order
select order_id, sum(profit), count(profit) as items
from orders
group by order_id 
order by 2 desc;
	
--Sales per Customer
select customer_id, customer_name, sum(sales) "total sales"
from orders
group by 1,2
order by 3 desc;

--Avg. Discount
select round(avg(discount), 3) as "average_discount"
from orders;

--Monthly Sales by Segment ( табличка и график)
select 
	segment	
	,date_part('year', order_date) as year
	,date_part('month', order_date) as month	
	,sum(sales) as sales
from orders
group by segment, year, month
order by segment, year, month;
	

--Yearly Sales by Product Category (табличка и график)
select 
	category "Product Category"
	,date_part('year', order_date) as "Year"
	,round(sum(sales),0) as "Total sales"
from orders
group by 1, 2
order by 1, 2;