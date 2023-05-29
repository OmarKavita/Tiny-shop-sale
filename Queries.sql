-- 1. Which product has the highest price? Only return a single row.
/*Solution1:*/
select product_name from products
where price = (select max(price) from products);

/* Solution 2:*/
select product_name from products
order by price desc
limit 1;

-- 2. Which customer has made the most orders?
select customer_id, count(order_id) as order_count from orders
group by customer_id
order by order_count
limit 1;

-- 3. What’s the total revenue per product?
with product_qntt as(
select product_id, sum(quantity) as total_qntt from order_items
group by product_id
)
select p.product_name, p.price*pq.total_qntt 
from products p left join product_qntt pq
on p.product_id = pq.product_id;

-- 4. Find the day with the highest revenue.
with order_revenue as (
select order_id, sum(quantity* price) as revenue from
(select o.order_id, o.product_id, o.quantity, p.price
from order_items o left join products p
on o.product_id = p.product_id) as new
group by order_id
)
select o.order_date, r.revenue 
from orders o left join order_revenue r
on o.order_id = r.order_id
order by r.revenue desc
limit 1;

-- 5. Find the first order (by date) for each customer.
with first_orders as (
select * from(
select customer_id, order_id, 
row_number() over(partition by customer_id order by order_date) as rn
from orders) as new_orders
where rn =1
)
select c.first_name as customer_name, f.order_id
from first_orders f left join customers c 
on f.customer_id = c.customer_id;

-- 6. Find the top 3 customers who have ordered the most distinct products
with cte as (
select order_id, count(distinct product_id) as num_products
from order_items
group by order_id)
select o.customer_id, sum(c.num_products) as num_product_ordered
from orders o left join cte c 
on o.order_id = c.order_id
group by customer_id
order by num_product_ordered desc
limit 3;

-- 7. Which product has been bought the least in terms of quantity?
with product_counts as(
select product_id, sum(quantity) as quantity from order_items
group by product_id
)
select p.product_name, c.quantity 
from products p left join product_counts c 
on p.product_id = c.product_id
where quantity = (select min(quantity) from product_counts);

-- 8. What is the median order total?
WITH ordered_orders AS (
  SELECT
    o.order_id,
    SUM(p.price * o.quantity) AS order_total
  FROM
    order_items o
  JOIN
    products p ON o.product_id = p.product_id
  GROUP BY
    order_id
  ORDER BY
    order_total
)
SELECT
  AVG(order_total) AS median_order_total
FROM (
  SELECT
    order_total,
    ROW_NUMBER() OVER (ORDER BY order_total) AS row_num,
    COUNT(*) OVER () AS total_rows
  FROM
    ordered_orders
) subquery
WHERE
  row_num IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2));

-- 9. For each order, determine if it was ‘Expensive’ (total over 300), ‘Affordable’ (total over 100), or ‘Cheap’.
with order_price as(
select o.order_id, sum(o.quantity* p.price) as total_price
from order_items o left join products p 
on o.product_id = p.product_id
group by o.order_id
)
select order_id, case
	when total_price>300 then 'Expensive'
    when total_price >100 then 'Affordable'
    else 'Cheap'
    end as 'category'
from order_price;

-- 10. Find customers who have ordered the product with the highest price.
select o.customer_id as `customers with costliest order` from order_items oi
join products p
on oi.product_id = p.product_id
join orders o
on oi.order_id = o.order_id
where price = (select max(price) from products)


