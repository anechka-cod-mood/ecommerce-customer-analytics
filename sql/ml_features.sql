/*first order*/
with first_order as (
    select 
        c.customer_unique_id,
        o.order_id as first_order_id,
        o.order_purchase_timestamp as order_date, 
        
        row_number() over (
        PARTITION by c.customer_unique_id 
        order by o.order_purchase_timestamp) 
        as order_rank

    from orders as o
    join customers as c 
        on c.customer_id=o.customer_id
),
first_order_features as (
    SELECT 
        fo.customer_unique_id,
        fo.first_order_id,
        fo.order_date,
        sum(oi.price) as first_order_value,
        count(oi.order_item_id)as first_order_items,
        sum(oi.freight_value) as first_order_freight

    from first_order as fo
    join order_items as oi 
        on oi.order_id= fo.first_order_id
    where order_rank=1
    group by customer_unique_id ,first_order_id, order_date
)
select 
    customer_unique_id,
    first_order_id,
    order_date,
    first_order_value,
    first_order_items,
    first_order_freight, 
 from first_order_features;

/*first_order_payment*/
/* ML FEATURES */

WITH first_order AS (
    SELECT 
        c.customer_id,
        c.customer_unique_id,
        o.order_id AS first_order_id,
        o.order_purchase_timestamp AS first_order_date,

        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.order_purchase_timestamp
        ) AS order_rank

    FROM orders AS o
    JOIN customers AS c 
        ON c.customer_id = o.customer_id
),

first_order_features AS (
    SELECT 
        fo.customer_unique_id,
        fo.first_order_id,
        fo.first_order_date,

        SUM(oi.price) AS first_order_value,
        COUNT(oi.order_item_id) AS first_order_items,
        SUM(oi.freight_value) AS first_order_freight,

        -- new features
        SUM(oi.price) / COUNT(oi.order_item_id) AS avg_item_price,

        SUM(oi.freight_value) / NULLIF(SUM(oi.price), 0) AS freight_ratio,

        julianday(o.order_estimated_delivery_date)
            - julianday(fo.first_order_date) AS estimated_delivery_days,

        COUNT(DISTINCT oi.product_id) AS unique_products,

        COUNT(DISTINCT p.product_category_name) AS unique_categories

    FROM first_order AS fo

    JOIN order_items AS oi 
        ON oi.order_id = fo.first_order_id

    JOIN orders AS o
        ON o.order_id = fo.first_order_id

    LEFT JOIN products AS p
        ON p.product_id = oi.product_id

    WHERE fo.order_rank = 1

    GROUP BY 
        fo.customer_unique_id,
        fo.first_order_id,
        fo.first_order_date,
        o.order_estimated_delivery_date
),

payment_features AS (
    SELECT 
        fo.first_order_id,

        SUM(p.payment_value) AS first_order_payment,
        MAX(p.payment_installments) AS first_order_installments

    FROM first_order AS fo

    JOIN payments AS p 
        ON p.order_id = fo.first_order_id

    WHERE fo.order_rank = 1

    GROUP BY fo.first_order_id
),
repeat_behavior as (
    select 
        fo.customer_unique_id,
        MAX(
            case 
                when julianday(o.order_purchase_timestamp)-julianday(fo.first_order_date) > 0 and 
                julianday(o.order_purchase_timestamp)-julianday(fo.first_order_date) <= 180 
                then 1
                else 0 
            END
    ) as repeat_customer
from first_order as fo 

LEFT JOIN customers AS c
    ON c.customer_unique_id = fo.customer_unique_id

left join orders as o on o.customer_id=c.customer_id
where fo.order_rank=1

group by fo.customer_unique_id
),
eligible_customers AS (
    SELECT
        rb.customer_unique_id,
        rb.repeat_customer
    FROM repeat_behavior AS rb
    JOIN first_order_features AS fof
        ON fof.customer_unique_id = rb.customer_unique_id
    WHERE julianday(
        (SELECT MAX(order_purchase_timestamp) FROM orders)
    ) - julianday(fof.first_order_date) >= 180
),
ml_dataset AS (
    SELECT
    fof.customer_unique_id,
    fof.first_order_id,
    fof.first_order_date,

    -- original features
    fof.first_order_value,
    fof.first_order_items,
    fof.first_order_freight,

    -- new features
    fof.avg_item_price,
    fof.freight_ratio,
    fof.estimated_delivery_days,
    fof.unique_products,
    fof.unique_categories,

    -- payment features
    pf.first_order_payment,
    pf.first_order_installments,

    -- target
    ec.repeat_customer

FROM first_order_features AS fof

JOIN payment_features AS pf
    ON pf.first_order_id = fof.first_order_id

JOIN eligible_customers AS ec
    ON ec.customer_unique_id = fof.customer_unique_id
)
SELECT *
FROM ml_dataset;

