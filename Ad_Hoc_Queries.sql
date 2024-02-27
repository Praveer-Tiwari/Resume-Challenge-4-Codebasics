#1 Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.
SELECT market, region, customer FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";

#2 What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields: unique_products_2020, unique_products_2021, percentage_chg.
 SELECT up1.pc1 AS unique_products_2020, 
        up2.pc2 AS unique_products_2021,
        ROUND((pc2-pc1)*100/pc1, 2) AS percentage_chg
 FROM (
      (SELECT COUNT(DISTINCT (product_code)) AS pc1
              FROM fact_sales_monthly
			  WHERE fiscal_year = 2020) up1,
      (SELECT COUNT(DISTINCT (product_code)) AS pc2
              FROM fact_sales_monthly
              WHERE fiscal_year = 2021) up2
      );

#3 Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields: segment, product_count.
SELECT COUNT(DISTINCT(product)) AS product_count, segment
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

#4 Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields: segment, product_count_2020, product_count_2021, difference.
WITH cte1 AS (SELECT p.segment AS s1, COUNT(DISTINCT(s.product_code)) AS pc1
              FROM dim_product p
              JOIN fact_sales_monthly s
              ON p.product_code = s.product_code
              WHERE s.fiscal_year =  2020
              GROUP BY s.fiscal_year, p.segment),
	 cte2 AS (SELECT p.segment AS s2, COUNT(DISTINCT(s.product_code)) AS pc2
              FROM dim_product p
              JOIN fact_sales_monthly s
              ON p.product_code = s.product_code
              WHERE s.fiscal_year =  2021
              GROUP BY s.fiscal_year, p.segment)
SELECT cte1.s1 AS segment, cte1.pc1 AS product_count_2020,
       cte2.pc2 AS product_count_2021, 
       (cte2.pc2 - cte1.pc1) AS difference  
FROM cte1, cte2
WHERE cte1.s1 = cte2.s2;

#5 Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields: product_code, product manufacturing_cost.
SELECT dp.product_code, mc.manufacturing_cost
FROM dim_product dp
JOIN fact_manufacturing_cost mc
ON dp.product_code = mc.product_code
WHERE manufacturing_cost IN 
                        (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
                        UNION
                        SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;

#6 Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. The final output contains these fields: customer_code, customer, average_discount_percentage
WITH cte1 AS (SELECT customer_code AS cc1,
			  ROUND(AVG(pre_invoice_discount_pct),4) AS pct
             FROM fact_pre_invoice_deductions
             WHERE fiscal_year = 2021
             GROUP BY customer_code),
	cte2 AS (SELECT customer_code AS cc2, customer AS c
             FROM dim_customer
             WHERE market = "India")
SELECT cte2.cc2 AS customer_code, 
       cte2.c AS customer,
       cte1.pct AS average_discount_percentage
FROM cte1
JOIN cte2 ON cte1.cc1 = cte2.cc2
ORDER BY average_discount_percentage DESC
LIMIT 5;

#7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: Month, Year, Gross sales Amount
SELECT  c.customer, CONCAT(MONTHNAME(fs.date), YEAR(fs.date)) AS Month, fs.fiscal_year,
       ROUND(SUM(gp.gross_price * fs.sold_quantity),2) AS gross_sales_amount
FROM fact_sales_monthly fs
JOIN dim_customer c ON fs.customer_code = c.customer_code
JOIN fact_gross_price gp ON fs.product_code = gp.product_code
WHERE c.customer = "Atliq Exclusive"
GROUP BY Month, fs.fiscal_year
ORDER BY fs.fiscal_year;

#8 In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the : total_sold_quantity, Quarter, total_sold_quantity 9.
SELECT
CASE
     WHEN DATE BETWEEN "2019-09-01" AND "2019-11-01" THEN 1
     WHEN DATE BETWEEN "2019-12-01" AND "2020-02-01" THEN 2
     WHEN DATE BETWEEN "2020-03-01" AND "2020-05-01" THEN 3
     WHEN DATE BETWEEN "2020-06-01" AND "20-08-01" THEN 4
END AS Quarter,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

#9 Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, channel gross_sales_mln percentage
WITH cte1 AS (SELECT c.channel, ROUND(SUM(gp.gross_price * fs.sold_quantity/1000000),2) AS Gross_sales_mln
FROM dim_customer c 
JOIN fact_sales_monthly fs ON fs.customer_code = c.customer_code
JOIN fact_gross_price gp ON gp.product_code = fs.product_code
WHERE gp.fiscal_year = 2021
GROUP BY c.channel)

SELECT channel, CONCAT(Gross_sales_mln,' M') AS Gross_sales_mln , CONCAT(ROUND(Gross_sales_mln*100/total , 2), ' %') AS Percentage
FROM
(
(SELECT SUM(Gross_sales_mln) AS total FROM cte1) A,
(SELECT * FROM cte1) B
)
ORDER BY Percentage DESC;

#10 Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields: division, product_code, product, total_sold_quantity, rank_order
WITH cte1 AS (SELECT dp.division, dp.product_code, dp.product, SUM(fs.sold_quantity) AS total_sold_quantity
			  FROM dim_product dp
              JOIN fact_sales_monthly fs
              ON fs.product_code = dp.product_code
              WHERE fiscal_year = 2021
              GROUP BY dp.division, dp.product_code, dp.product),
              
     cte2 AS (SELECT division, product_code, product, total_sold_quantity,
              RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
              FROM cte1)

SELECT cte1.division, cte1.product_code, cte1.product, cte1.total_sold_quantity, cte2.rank_order
FROM cte1 
JOIN cte2
ON cte1.product_code = cte2.product_code
WHERE cte2.rank_order IN (1,2,3);




