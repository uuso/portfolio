

--    Полученные данные не были окончательно загружены в разработанную модель данных. Остановился на загрузке ключевой части - fact_sales
--          Замеченные особенности датасета:
--    - в поле postal_code присутствуют null значения (1)
--    - поле product_id не определяет товар product_name однозначно, присутствуют дублирующиеся значения product_id (32)
--    - неясно как формируется total_discount у конкретного заказчика. Возможно по product_name
--    + за customer_name однозначно закреплены segment
--    + один и тот же город (country, region, state, city) может обладать разными postal_codes
--    + subcategory подчиняются category и не повторяются
--    ? неправильно описал dim_customers.customer_id - он присутствует в оригинальной таблице и следует использовать его
--    ? что делать с дубликатами product_id и как их джойнить для заполнения fact_sales


-- fill dim_customers_segments
insert into superstore_schema.dim_customers_segments
select row_number() over() + 100 cust_segment_id, segment segment_name
from (select distinct segment from public.orders) o;



-- fill dim_customers
insert into superstore_schema.dim_customers (customer_name, cust_segment_id)
with cust_seg as (
    select distinct customer_name, segment
    from public.orders
)
select customer_name, cust_segment_id
from cust_seg join
    superstore_schema.dim_customers_segments on (segment = segment_name);

    
    
-- insert values into dim_ship_mode
insert into superstore_schema.dim_ship_mode 
select row_number() over() + 200 shipmode_id, ship_mode shipmode_name
from (select distinct ship_mode from public.orders) o;



-- ALTER TABLE dim_ship_geo ALTER COLUMN postal DROP NOT NULL;

-- fill up dim_ship_geo table
-- !!! has NULL (1) in postal_code s
insert into superstore_schema.dim_ship_geo 
select 
    row_number() over() + 300 geo_id
    ,country
    ,state
    ,city
    ,postal_code postal
    ,region
from (
    select distinct country, state, city, postal_code, region
    from public.orders
    ) o;

    
-- truncate table dim_ship cascade;
    
-- insert values into dim_ship
insert into superstore_schema.dim_ship (shipmode_id, geo_id, address)
select distinct
    shipmode_id
    ,geo_id
    ,concat(dsg.country, ' ', dsg.postal, ', ', dsg.city, ', ', dsg.state) description
from public.orders o join
    superstore_schema.dim_ship_mode dsm on shipmode_name = ship_mode join
    superstore_schema.dim_ship_geo dsg on 
                dsg.country = o.country and 
                dsg.state = o.state and 
                dsg.city = o.city and 
                dsg.postal = o.postal_code::varchar(10) and 
                dsg.region = o.region;


-- insert all the dates                
insert into superstore_schema.dim_calendar      
with all_dates as (
    select order_date my_date from public.orders
    union select ship_date my_date from public.orders
)
select 
    my_date "date"
    ,date_part('year', my_date) "year"
    ,date_part('quarter', my_date) "quarter"
    ,date_part('month', my_date) "month"
    ,date_part('week', my_date) "week"
    ,date_part('dow', my_date) "week_day"
from (select distinct * from all_dates) o;


insert into superstore_schema.dim_prod_cat 
select row_number() over() + 400 cat_id, cats.category cat_name 
from (select distinct category from public.orders) cats;


insert into superstore_schema.dim_prod_subcat
with cat_sub as (select distinct subcategory, category from public.orders)
select row_number() over() + 500 subcat_id, subcategory subcat_name, cat_id
from cat_sub join superstore_schema.dim_prod_cat on cat_name = category;



-- !!! has duplicates in product_id ()
with pid as (select distinct product_name, product_id from public.orders)
select product_id, count(*), string_agg(product_name, '  --  '), (array_agg(product_name))[1] change_id_name
from pid
group by 1
having count(*) > 1;


-- change duplicated product_id to $product_id+'D'
insert into superstore_schema.dim_prod (product_id, subcat_id, product_name)
with 
    id_name_pairs as (
        select distinct product_name, product_id from public.orders
    ),
    first_duplicates_names as (
        select (array_agg(product_name))[1] prodname
        from id_name_pairs
        group by product_id 
        having count(*) > 1
    ),
    subcat as (
        select distinct subcat_name, subcat_id 
        from superstore_schema.dim_prod_subcat
    )
select distinct 
    case
        when product_name in (select prodname from first_duplicates_names)
            then concat(product_id, 'D')
        else product_id 
        end as product_id
    ,subcat_id
    ,product_name
from public.orders join
    subcat on subcat_name = subcategory;






--insert into fact_sales
select 
    row_id
    ,order_id
    ,shipping_id
    ,product_id
    ,customer_id 
    ,ship_date 
    ,order_date 
    ,sales_amount
    ,profit
    ,quantity
    ,total_discount
from 
    public.orders o 
    join dim_ship_mode       on shipmode_name = ship_mode     
    join dim_ship            using(shipmode_id)              
    join dim_ship_geo        on    dim_ship_geo.geo_id  = dim_ship.geo_id 
                                  and dim_ship_geo.country = o.country
                                  and dim_ship_geo.state   = o.state
                                  and dim_ship_geo.city    = o.city
                                  and dim_ship_geo.postal  = o.postal_code::varchar(10)
                                  and dim_ship_geo.region  = o.region 
    join dim_customers      using(customer_name)
--    join dim_customers_segments using(cust_segment_id) -- свойство клиента, уникально, уже установлено соответтсвие
    join dim_prod           using(product_id, product_name) -- не учитывает дубликаты, пропущены
--    join dim_prod_subcat    using(subcat_id) -- уже установлено соответствие
--    join dim_prod_cat       using(cat_id) -- уже установлено соответствие
    







    
