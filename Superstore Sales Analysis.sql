-- Table Creation
-- For the primary key, we are going to consider (Order ID,Product ID) combination which is in turn going to become a composite key.
-- We included the 'not null' constraint as we dont want to include the rows that have any null values in any column.

create table superstore_sales (Row_ID int not null,
							   Order_ID varchar(40),
                               Order_Date date not null,
                               Ship_Date date not null,
                               Ship_Mode varchar(30) not null,
                               Customer_ID varchar(10) not null,
                               Customer_Name varchar(60) not null,
                               Segment varchar(60) not null,
                               Country varchar(60) not null,
                               City varchar(60) not null,
                               State varchar(60) not null,
                               Postal_Code int not null,
                               Region varchar(60) not null,
                               Product_ID varchar(40),
                               Category varchar(60) not null,
                               Sub_Category varchar(60) not null,
                               Product_Name varchar(130) not null,
                               Sales float(7,2) not null,
                               Quantity int not null,
                               Discount float(7,1) not null,
                               Profit float(7,2) not null,
                               primary key (Order_ID,Product_ID));
                               
# Check table
describe superstore_sales;

select * from superstore_sales;

-- Delete Row_ID from the table as it is not required for our analysis
alter table superstore_sales drop row_id;

-- ---------- FEATURE ENGINEERING ----------

-- 1) Create a new column to get the unit price of each product
/*
	First get discounted unit price -> Total Sales / Quantity
    Then get original unit price -> Discounted Unit Price / (1 - Discount)
*/
select round(((sales / quantity) / (1 - Discount)),2) from superstore_sales;
alter table superstore_sales add column Unit_Price float(7,2) not null;
update superstore_sales set Unit_Price = round(((sales / quantity) / (1 - Discount)),2);

-- 2) Create a new column for the dayname of each order date
select dayname(order_date) from superstore_sales;
alter table superstore_sales add column Order_Day varchar(10) not null;
update superstore_sales set Order_Day = dayname(Order_Date);

-- 3) Create a column to check whether the day is a weekday or a weekend
select (case when weekday(Order_Date) in (0,4) then true else false end) from superstore_sales;
alter table superstore_sales add column isWeekday bool not null;
update superstore_sales set isWeekday = (case when weekday(Order_Date) in (0,1,2,3,4) then true else false end);



-- _______ EXPLORATORY DATA ANALYSIS ____________
-- ______ _____________ _________________

-- 1) TOTAL SALES AND TOTAL PROFIT EACH YEAR
select year(order_date),sum(sales) total_sales,sum(profit) total_profit from superstore_sales group by year(order_date) order by year(order_date);
-- From the results, it is exciting to say that the total sales and profit have increased drastically over the years


-- 2) TOTAL REVENUE GENERATED BY EACH STATE
select state,sum(sales) total_sales from superstore_sales group by state order by total_sales desc;
-- Seems like California had the highest sales of around 450k


-- 3) TOTAL REVENUE BY EACH REGION
select region,sum(sales) total_sales from superstore_sales group by region order by total_sales desc;
-- West region had the highest revenue generated


-- 4) MOST EXPENSIVE PRODUCT BOUGHT BY A CUSTOMER
select customer_name,product_name,unit_price from superstore_sales order by unit_price desc limit 1;
-- Sean Miller bought a video-conferencing unit that costed around 7.5k dollars


-- 5) ON WHICH DAYS DO CUSTOMER PREFER TO BUY THE MOST PRODUCTS ?
select isWeekday,sum(sales) total_sales from superstore_sales group by isWeekday order by total_sales desc;
-- So it seems customers prefer to buy the most on weekdays rather than on weekends


-- 6) TOTAL SALES IN ALL DAYS OF THE WEEK
select order_day,sum(sales) total_sales from superstore_sales group by order_day order by total_sales desc;
-- People tend to buy the most on Monday


-- 7) WHICH STATES RECEIVED THE HIGHEST PROFIT ?
select state,sum(profit) total_profit from superstore_sales group by state order by total_profit desc;
-- California, New York and Washington are among the top states that received the highest profit


-- 8) LISTING EACH CATEGORY AND THEIR AVERAGE PROFIT
select category,avg(profit) total_profit from superstore_sales group by category order by total_profit desc;
-- The 'Technology' category received the highest average profit

-- 9) WHICH CUSTOMERS GAVE THE HIGHEST PROFIT ?
select customer_name,sum(profit) total_profit from superstore_sales group by customer_name order by total_profit desc;
-- 'Tamara Chand' was the person who gave the highest profit


-- 10) AVERAGE NUMBER OF DAYS BETWEEN ORDER AND SHIP DATE FOR EACH REGION
select region,round(avg(datediff(ship_date,order_date))) avg_days from superstore_sales group by region;
-- Seems like for each region the avg days between order and shipping is 4 and is same for all the regions


-- 11) WHAT SUBCATEGORIES DO PEOPLE LIKE TO BUY THE MOST ?
select sub_category,sum(sales) total_sales from superstore_sales group by sub_category order by total_sales desc;
-- People like to buy phones the most


-- 12) ON WHICH PRODUCTS IS THE MIN AND MAX DISCOUNT GIVEN
(select sub_category,discount from superstore_sales where discount <> 0 order by discount limit 1)
union
(select sub_category,discount from superstore_sales order by discount desc limit  1);
-- Min discount was given on 'Chairs' and max discount was given on 'Appliances'


-- 13) REGIONS WITH EACH CUSTOMER COUNT
select region,count(customer_id) total_customers from superstore_sales group by region order by total_customers desc;
-- The 'West' region has the highest customers who order


-- 14) WHICH PRODUCT WAS ORDERED THE LEAST AND THE MOST
(select product_name,sum(quantity) total_quantity from superstore_sales group by product_name order by total_quantity limit 1)
union
(select product_name,sum(quantity) total_quantity from superstore_sales group by product_name order by total_quantity desc limit 1);
/* 'Electric Pencil Sharpener' was the least bought product and 'Staples' was the highest bought product so it seems like
    the stores must increase the supply of 'Staples' to gain more profit */


-- 15) TOP 5 SELLING PRODUCTS OVER THE YEARS FOR EACH REGION

/*
with cte as (select year(order_date) order_year,region,product_name,sum(sales) total_sales,rank() over(partition by year(order_date),region order by sum(sales) desc) rankSales
			 from superstore_sales group by order_year,region,product_name)
select * from cte where rankSales <= 5;
*/