
select * from city;
select * from products;
select * from customers;
select * from sales;


--                                  Coffee Consumers Count
#1 How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
    city_name, round(population/1000000,2)as population_in_millions,
    ROUND((0.25 * population / 1000000), 2) AS coffee_consumers_in_millions,
    city_rank
FROM
    city
ORDER BY 2 DESC;


--                          Total Revenue from Coffee Sales
#2 What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
    ci.city_name, SUM(s.total) AS total_revenue
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
WHERE
    s.sale_date >= '2023-10-01'
        AND s.sale_date < '2024-01-01'
GROUP BY ci.city_name
ORDER BY total_revenue DESC;


--              Sales Count for Each Product
#3 How many units of each coffee product have been sold?

SELECT 
    p.product_name, COUNT(s.sale_id) AS total_units_sold
FROM
    products p
        LEFT JOIN
    sales s ON p.product_id = s.product_id
GROUP BY 1
ORDER BY 2 DESC;

--               Average Sales Amount per City
#4 What is the average sales amount per customer in each city?

SELECT 
    ci.city_name,
    ROUND((SUM(s.total) / COUNT(DISTINCT s.customer_id)),2) AS avg_amt_per_customer
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;


--  				City Population and Coffee Consumers
#5 Provide a list of cities along with their populations and estimated coffee consumers.

SELECT 
    ci.city_name,
    ROUND((0.25 * ci.population / 1000000), 2) AS estimate_consumers_in_millions,
    COUNT(DISTINCT s.customer_id) AS actual_consumers
FROM
	sales s
        JOIN
	customers c ON s.customer_id = c.customer_id
        JOIN
	city ci ON ci.city_id = c.city_id
GROUP BY 1 , 2
ORDER BY 3 DESC;


--                Top Selling Products by City
#6 What are the top 3 selling products in each city based on sales volume?

WITH t1 as (select ci.city_name, p.product_name,
 COUNT(s.sale_id) as total_sales,
 DENSE_RANK() OVER(partition by ci.city_name order by count(s.sale_id) desc) as rnk
FROM
	sales s
        JOIN
	customers c ON s.customer_id = c.customer_id
        JOIN
	city ci ON ci.city_id = c.city_id
		join
	products p on p.product_id = s.product_id
GROUP BY 1,2
ORDER BY 1,3 DESC)

SELECT * FROM t1
WHERE rnk <= 3;
    
    
-- 					Customer Segmentation by City
#7 How many unique customers are there in each city who have purchased coffee products?

show indexes from sales;
create index product_id_idx on sales(product_id);
SELECT 
    ci.city_name,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM
    sales s
        JOIN
    customers c ON s.customer_id = c.customer_id
        JOIN
    city ci ON ci.city_id = c.city_id
WHERE
    s.product_id <= 14
GROUP BY 1
ORDER BY 2 DESC;


-- 					Average Sale vs Rent
#8 Find each city and their average sale per customer and avg rent per customer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_customers,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_customer
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT 
	city_name, 
	estimated_rent
FROM city
)
SELECT 
	cr.city_name,
	cr.estimated_rent,
	ct.total_customers,
	ct.avg_sale_pr_customer,
	ROUND(cr.estimated_rent/ct.total_customers, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 5 DESC;


-- Monthly Sales Growth
#9 Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly).

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	coalesce(last_month_sale,'-'),
	coalesce(round(((cr_month_sale-last_month_sale)/last_month_sale* 100),2),'-') as growth_rate
FROM growth_ratio;


-- Market Potential Analysis
#10 Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(SUM(s.total)/COUNT(DISTINCT s.customer_id),2) as avg_sale_pr_cx
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 3) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC








