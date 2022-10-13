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


--Sales and Profit by Customer
select customer_name "Customer", round(sum(sales), 2) "Total Sales"
from orders
group by 1
order by 2 desc;


--Customer Ranking
-- из табличек сумм продаж и выручки с агрегацией по клиенту
-- получаем ранки и объединяем две ранковых таблицы по имени клиента 
with sales_sum as (
    select customer_name, round(sum(sales), 2) total_sales
    from orders
    group by customer_name
), profit_sum as (
    select customer_name, round(sum(profit), 2) total_profit
    from orders
    group by customer_name
)
select
    customer_name "Customer Name"
    ,sales_ranking.rnk "Rank by Total Sales"
    ,sales_ranking.total_sales "Total Sales"
    ,profit_ranking.rnk "Rank by Total Profit"
    ,profit_ranking.total_profit "Total Profit"
from 
    (select 
        customer_name
        ,rank() over(order by total_sales DESC) rnk
        ,total_sales
    from sales_sum) sales_ranking
    join
    (select 
        customer_name
        ,rank() over(order by total_profit DESC) rnk
        ,total_profit
    from profit_sum) profit_ranking
    using (customer_name)
order by "Rank by Total Profit"
    

--Sales per region
-- добавлю отдельную строку итогов
with separate_values as 
(
    select region "Region"
        ,sum(sales) "Total Sales"
        ,sum(sales)/(select sum(sales) from orders) * 100 "Percentage"
    from orders
    group by 1
)
select "Region"
    ,round("Total Sales", 2) "Total Sales"
    ,round("Percentage", 1) "Percentage"
from separate_values
union
select 'All'
    ,round(sum("Total Sales"), 2)
    ,sum("Percentage")
from separate_values;