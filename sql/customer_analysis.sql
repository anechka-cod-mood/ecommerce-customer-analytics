
select c.customer_unique_id, 
    count(o.order_id) 
    as order_count
from customers as c 
join orders as o on o.customer_id=c.customer_id
group by c.customer_unique_id
having order_count>1;

select c.customer_unique_id, 
    count(o.order_id) as order_count
from customers as c  
join orders as o on o.customer_id=c.customer_id
group by c.customer_unique_id
order by order_count DESC
limit 10;

with tab1 as
(select c.customer_unique_id, 
    count(o.order_id) as order_count
from customers as c 
join orders as o on o.customer_id=c.customer_id
group by c.customer_unique_id)

select avg(order_count) AS avg_orders_per_customer
from tab1;

with tab1 as
(select c.customer_unique_id, 
    count(o.order_id) as order_count
from customers as c 
join orders as o on o.customer_id=c.customer_id
group by c.customer_unique_id)

select count(*) as all_customers,
    count(case when order_count>1 then 1 end) as repeat_customers,
    count(case when order_count>1 then 1 end)*100.0/count(*) as percent_
from tab1;

select * from customers;
select * from order_items;
select * from orders;

SELECT c.customer_unique_id, 
       SUM(oi.price) AS total_spent
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_spent DESC
LIMIT 10;

SELECT c.customer_unique_id, 
       SUM(oi.price + oi.freight_value) AS total_spent_freight
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id
ORDER BY total_spent_freight DESC
LIMIT 10;


with total_tab as (
select order_id, sum(price) as
total_order_value
from order_items
group by order_id)

select avg(total_order_value) 
as avg_order
from total_tab;

select strftime('%Y-%m', 
    order_purchase_timestamp) as month, sum(price)
    as revenue
from orders as o 
join order_items as oi ON
        o.order_id=oi.order_id
group by month;

select strftime('%Y-%m', 
    order_purchase_timestamp) as month, sum(price)
    as revenue
from orders as o 
join order_items as oi ON
        o.order_id=oi.order_id
group by month
order by revenue desc
limit 1;

/*feature table-orders_count*/
select customer_unique_id, 
       count(order_id) as orders_count
from customers as c 
join orders as o on o.customer_id=c.customer_id
group by customer_unique_id;

/*total_spent*/
SELECT c.customer_unique_id, count(DISTINCT o.order_id) as orders_count,
       SUM(oi.price + oi.freight_value) AS total_spent_freight
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;

/*avg_order_value*/
with tab1 as (SELECT c.customer_unique_id, count(DISTINCT o.order_id) as orders_count,
       SUM(oi.price + oi.freight_value) AS total_spent_freight
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id)

select customer_unique_id,
        total_spent_freight,
        orders_count,
        total_spent_freight/orders_count as avg_order_value
from tab1;

/*days_since_last_order*/
select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
GROUP by customer_unique_id; 

select max(order_purchase_timestamp)
    as last_order_date
from orders;

/*days_since_last_order*/
with tab1 as (select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
GROUP by customer_unique_id),
tab2 as (
    select max(order_purchase_timestamp)
    as last_order_date
    from orders
)

SELECT customer_unique_id,
       tab1.last_order_date,
       round(julianday(tab2.last_order_date) - julianday(tab1.last_order_date))
           AS days_since_last_order
FROM tab1
CROSS JOIN tab2;

/*churn*/
with tab1 as (select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
GROUP by customer_unique_id),
tab2 as (
    select max(order_purchase_timestamp)
    as last_order_date
    from orders
)

SELECT customer_unique_id,
       tab1.last_order_date,
       round(julianday(tab2.last_order_date) - julianday(tab1.last_order_date))
           AS days_since_last_order
FROM tab1
CROSS JOIN tab2;

/*customer_lifetime_days*/
with tab1 as (select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date,
    MIN(order_purchase_timestamp) 
    as first_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
GROUP by customer_unique_id)

SELECT customer_unique_id,
       last_order_date, first_order_date,
       round(julianday(last_order_date) - julianday(first_order_date))
           AS customer_lifetime_days
FROM tab1;



/*general tab*/

with tab1 as (SELECT c.customer_unique_id, count(DISTINCT o.order_id) as orders_count,
       SUM(oi.price + oi.freight_value) AS total_spent
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id),

tab3 as (
    select max(order_purchase_timestamp)
    as last_order_date
    from orders
),

tab4 as (select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date,
    MIN(order_purchase_timestamp) 
    as first_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
GROUP by customer_unique_id),

feature_table as (
select tab1.customer_unique_id,
        tab1.total_spent,
        tab1.orders_count,
        tab1.total_spent/tab1.orders_count as avg_order_value,
        ROUND(
           julianday(tab3.last_order_date) 
           - julianday(tab4.last_order_date)
       ) AS days_since_last_order,

        round(
        julianday(tab4.last_order_date) 
        - julianday(tab4.first_order_date)
        )AS customer_lifetime_days,
        case when ROUND(
           julianday(tab3.last_order_date) 
           - julianday(tab4.last_order_date)
       )>90 then 1
       else 0
       end as churn
from tab1
join tab4 
    on tab1.customer_unique_id=tab4.customer_unique_id 
cross join tab3)

select * from feature_table;

SELECT COUNT(*) AS customers_without_items
FROM tab4
LEFT JOIN tab1
    ON tab4.customer_unique_id = tab1.customer_unique_id
WHERE tab1.customer_unique_id IS NULL;


SELECT MIN(order_purchase_timestamp),
       MAX(order_purchase_timestamp)
from orders;

select *
from orders
where order_purchase_timestamp<'2018-07-01';

/*general tab cutoff*/


with tab1 as (SELECT c.customer_unique_id, count(DISTINCT o.order_id) as orders_count,
       SUM(oi.price + oi.freight_value) AS total_spent
FROM order_items AS oi
JOIN orders AS o 
    ON o.order_id = oi.order_id
JOIN customers AS c 
    ON c.customer_id = o.customer_id
where order_purchase_timestamp<'2018-03-01'
GROUP BY c.customer_unique_id),

tab3 as (
    select '2018-03-01'
    as cutoff_data
),

tab4 as (select customer_unique_id, 
    MAX(order_purchase_timestamp) 
    as last_order_date,
    MIN(order_purchase_timestamp) 
    as first_order_date
from customers as c
join orders as o 
    on o.customer_id=c.customer_id
where order_purchase_timestamp<'2018-03-01'
GROUP by customer_unique_id),

feature_table as (
select tab1.customer_unique_id,
        tab1.total_spent,
        tab1.orders_count,
        tab1.total_spent/tab1.orders_count as avg_order_value,
        ROUND(
           julianday(tab3.cutoff_data) 
           - julianday(tab4.last_order_date)
       ) AS days_since_last_order,

        round(
        julianday(tab4.last_order_date) 
        - julianday(tab4.first_order_date)
        )AS customer_lifetime_days
from tab1
join tab4 
    on tab1.customer_unique_id=tab4.customer_unique_id 
cross join tab3
),
target_table as (

    SELECT 
        c.customer_unique_id, 
        count(order_id) as future_orders_count,

    case 
        when count(order_id)>0 then 0 
        else 1
        end as churn

    from customers as c

    left join orders as o 
    on c.customer_id=o.customer_id
    and 
    o.order_purchase_timestamp>'2018-03-01' and
    o.order_purchase_timestamp<'2018-05-30'

GROUP by customer_unique_id
)
SELECT tt.churn, COUNT(DISTINCT tt.customer_unique_id)
FROM target_table AS tt
JOIN feature_table AS ft
    ON tt.customer_unique_id = ft.customer_unique_id
GROUP by tt.churn;



/*select 
    ft.customer_unique_id,
    ft.total_spent,
    ft.orders_count, 
    ft.avg_order_value, 
    ft.days_since_last_order,
    ft.customer_lifetime_days,
    tt.churn

from feature_table as ft
left join target_table as tt 
on ft.customer_unique_id=tt.customer_unique_id;*/

