 #SQL II - Mini Project
use sql2_proj
#Composite data of a business organisation, confined to ‘sales and delivery’domain is given for the period of last decade. From the given data retrievesolutions for the given scenario.
1. Join all the tables and create a new table called combined_table.(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)
CREATE TABLE combined_table2 AS
SELECT distinct 
	market.Ord_id, market.Prod_id, market.Ship_id, market.Cust_id, Sales, Discount, Order_Quantity, 
    Profit, Shipping_Cost, Product_Base_Margin, cust.Customer_Name, cust.Province, 
    cust.Region, cust.Customer_Segment, orders.Order_Date, orders.Order_Priority, 
    prod.Product_Category, prod.Product_Sub_Category, orders.Order_ID, ship.Ship_Mode, ship.Ship_Date
FROM
    market_fact AS market
        LEFT JOIN
	cust_dimen AS cust ON market.Cust_id = cust.Cust_id
        LEFT JOIN
	orders_dimen AS orders ON orders.Ord_id = market.Ord_id
		LEFT JOIN
	prod_dimen AS prod ON prod.Prod_id = market.Prod_id
		LEFT JOIN
	shipping_dimen AS ship ON ship.Ship_id = market.Ship_id;
select * from combined_table2

2. Find the top 3 customers who have the maximum number of orders

select c.customer_name,c.cust_id,count( distinct mf.ord_id) as Count_Orders
from cust_dimen c inner join market_fact mf on c.cust_id=mf.cust_id
group by c.customer_name,c.cust_id
order by Count_Orders desc
limit 3

3. Create a new column DaysTakenForDelivery that contains the date difference
of Order_Date and Ship_Date.

select o.order_id,order_date,ship_date,datediff(ship_date,order_date) as Days_taken_for_delivery
from shipping_dimen s inner join market_fact mf on s.ship_id=mf.ship_id
inner join orders_dimen o on mf.ord_id=o.ord_id

4. Find the customer whose order took the maximum time to get delivered.

select customer_name,c.cust_id,order_date,ship_date,datediff(ship_date,order_date) as Days_taken_for_delivery
from shipping_dimen s inner join market_fact mf on s.ship_id=mf.ship_id
inner join orders_dimen o on mf.ord_id=o.ord_id
inner join cust_dimen c on c.cust_id=mf.cust_id
order by Days_taken_for_delivery desc 
limit 1


5. Retrieve total sales made by each product from the data (use Windows
function)
select   pd.product_category,pd.product_sub_category,mf.prod_id,
sum(round(mf.sales,2))
over(partition by mf.prod_id ) as Total_sales_productwise
from market_fact mf inner join prod_dimen pd on mf.prod_id=pd.prod_id
order by Total_sales_productwise desc

6. Retrieve total profit made from each product from the data (use windows
function)
select   pd.product_category,pd.product_sub_category,mf.prod_id,
sum(round(mf.profit,2))
over(partition by mf.prod_id ) as Total_profit_productwise
from market_fact mf inner join prod_dimen pd on mf.prod_id=pd.prod_id
order by Total_profit_productwise desc
7. Count the total number of unique customers in January and how many of them
came back every month over the entire year in 2011
 
SELECT distinct Year(order_date), Month(order_date), count(cust_id) OVER (PARTITION BY month(order_date) 
order by month(order_date)) AS Total_Unique_Customers
FROM combined_table2
WHERE year(order_date)=2011 AND cust_id 
IN (SELECT DISTINCT cust_id
	FROM combined_table2
	WHERE month(order_date)=1
	AND year(order_date)=2011);

8. Retrieve month-by-month customer retention rate since the start of the
business.(using views)
Tips:
#1: Create a view where each user’s visits are logged by month, allowing for
#the possibility that these will have occurred over multiple # years since
#whenever business started operations

create view user_visit as 
	select  cust_id,month(order_Date) as Month,count(*) as Count_in_month from combined_table2 
	group by 1,2



# 2: Identify the time lapse between each visit. So, for each person and for each
#month, we see when the next visit is.

    
create view Time_lapse_vw as 
select  * ,lead(month)over(partition by cust_id order by month) as Next_month_visit
from user_visit 

select * from   time_lapse_vw
    
    
# 3: Calculate the time gaps between visits
create view  time_gap_vw as 
select *,
Next_month_visit- month as Time_gap from time_lapse_vw

select * from time_gap_vw


# 4: categorise the customer with time gap 1 as retained, >1 as irregular and
#NULL as churned
create view Customer_value_vw as 
select distinct cust_id,
avg(time_gap)over(partition by cust_id) as Average_time_gap,
case 
	when (avg(time_gap)over(partition by cust_id))<=1 then 'Retained'
    when (avg(time_gap)over(partition by cust_id))>1 then 'Irregular'
    when (avg(time_gap)over(partition by cust_id)) is null then 'Churned'
    else 'Unknown data'
end  as  'Customer_Value'
from time_gap_vw

select * from customer_value_vw

# 5: calculate the retention month wise

create view retention_vw as 
select distinct next_month_visit as Retention_month,
sum(time_gap)over(partition by next_month_visit ) as Retention_Sum_monthly
from time_gap_vw
where time_gap=1

select * from retention_vw

