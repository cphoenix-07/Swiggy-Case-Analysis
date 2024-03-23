USE swiggy;
SELECT count(distinct id) FROM order_details;


-- 1. Find customers who have never ordered
-- METHOD 1 
SELECT *
FROM users
WHERE user_id NOT IN (SELECT DISTINCT user_id FROM orders);

-- METHOD 2
SELECT t1.user_id, name
FROM users t1
LEFT JOIN orders t2 ON t1.user_id=t2.user_id
WHERE t2.order_id IS NULL;

-- 2. Average Price/dish

SELECT f_name, AVG(price) AS avg_price
from food t1
JOIN menu t2 ON t1.f_id=t2.f_id
GROUP BY f_name;

-- 3. Find the top restaurant in terms of the number of orders for a given month
SELECT t2.r_name, COUNT(*) AS total_orders
FROM orders t1
JOIN restaurants t2 ON t1.r_id=t2.r_id
WHERE  MONTHNAME(t1.date)='June'
GROUP BY t2.r_id, t2.r_name
ORDER BY total_orders DESC;

-- 4. restaurants with monthly sales greater than x for 
SELECT t1.r_id, t2.r_name, SUM(amount) AS revenue
FROM orders t1
JOIN restaurants t2 ON t1.r_id=t2.r_id
WHERE MONTHNAME(t1.date) LIKE 'JUNE'
GROUP BY t1.r_id, t2.r_name
HAVING revenue > 500;

-- 5. Show all orders with order details for a particular customer in a particular date range
SELECT *
FROM orders t1
JOIN order_details t2 ON t1.order_id=t2.order_id
JOIN users t3 ON t3.user_id=t1.user_id
WHERE t1.date BETWEEN '2022-01-01' AND '2022-10-01';


-- 6. Find restaurants with max repeated customers 
WITH repeated_customer AS (
SELECT t2.r_name, t1.user_id, COUNT(t1.user_id) AS count_of_repeated_customers
FROM orders t1
JOIN restaurants t2 ON t1.r_id=t2.r_id
GROUP BY t2.r_name, t1.user_id
HAVING count_of_repeated_customers>2
ORDER BY count_of_repeated_customers DESC)
SELECT DISTINCT r_name FROM repeated_customer;


-- 7. Month over month revenue growth of swiggy
SELECT 
    month_name,
    total_amount,
    LAG(total_amount) OVER (ORDER BY month_number) AS previous_month_amount,
    CASE
        WHEN LAG(total_amount) OVER (ORDER BY month_number) IS NULL THEN 0
        ELSE (total_amount - LAG(total_amount) OVER (ORDER BY month_number)) / LAG(total_amount) OVER (ORDER BY month_number) * 100
    END AS month_over_month_growth
FROM (
    SELECT 
        MONTHNAME(`date`) AS month_name,
        MONTH(`date`) AS month_number,
        SUM(amount) AS total_amount
    FROM 
        orders
    GROUP BY 
        month_name, month_number
) AS subquery_alias;


-- 8. Customer - favorite food

WITH CTE AS (SELECT t3.name AS customer_name, t4.f_name AS food_item, COUNT(t2.f_id) AS order_freq,
DENSE_RANK() OVER(PARTITION BY t3.name ORDER BY COUNT(t2.f_id) DESC) AS food_rank
FROM orders t1
JOIN order_details t2 ON t1.order_id=t2.order_id
JOIN users t3 ON t3.user_id=t1.user_id
JOIN food t4 ON t2.f_id=t4.f_id
GROUP BY t3.name, t4.f_name
) 
SELECT customer_name, food_item, order_freq FROM CTE
WHERE food_rank<=1;

