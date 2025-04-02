--OBJECTIVE_ANALYSIS
--1
Select * from album;
Select * from artist;
Select Count(*) from customer
where company is NULL ;
Select Count(*) from customer
where state is NULL;
Select Count(*) from customer
where fax is NULL ; -- 49 company, 29 state, 47 fax values are null in the customer table
Select * from employee ;-- 1 reports_to is null in this table
Select * from genre;
Select * from invoice;
Select * from invoice_line;
Select * from media_type;
Select * from playlist;
Select * from playlist_track;
Select count(*) from track
where composer is NULL;

--2
--op-selling tracks and top artist in the USA and identify their most famous genres.
WITH TopTracks AS (
    SELECT 
        t.track_id, 
        t.name AS track_name,
        SUM(il.quantity) AS total_sales
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN customer c ON i.customer_id = c.customer_id
    WHERE c.country = 'USA'
    GROUP BY t.track_id
),
-- Find top artists in the USA
TopArtists AS (
    SELECT 
        a.artist_id, 
        a.name AS artist_name,
        SUM(il.quantity) AS total_sales
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN album al ON t.album_id = al.album_id
    JOIN artist a ON al.artist_id = a.artist_id
    JOIN customer c ON i.customer_id = c.customer_id
    WHERE c.country = 'USA'
    GROUP BY a.artist_id
)

-- Combine top-selling tracks and artists
SELECT 
    t.track_name, 
    a.artist_name, 
    g.name AS genre_name, 
    SUM(il.quantity) AS total_sales
FROM TopTracks t
JOIN invoice_line il ON t.track_id = il.track_id
JOIN track tr ON t.track_id = tr.track_id
JOIN genre g ON tr.genre_id = g.genre_id
JOIN TopArtists a ON tr.album_id = a.artist_id
GROUP BY t.track_name, a.artist_name, g.name
ORDER BY total_sales DESC
LIMIT 10;

--3
--grouped by country
select country,count(*) as customer_count
from customer
group by country;

--4
Select billing_country as country, billing_state as state, billing_city as city,   count(invoice_id) as number_of_invoices, sum(total) as total_revenue
from invoice
group by billing_country,billing_state,billing_city
order by total_revenue desc;

--5
WITH CustomerRevenue AS (
    SELECT 
        c.customer_id, 
        c.country, 
        SUM(il.quantity * il.unit_price) AS total_revenue
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id, c.country
)
SELECT 
    customer_id, 
    country, 
    total_revenue
FROM (
    SELECT 
        cr.customer_id, 
        cr.country, 
        cr.total_revenue, 
        ROW_NUMBER() OVER (PARTITION BY cr.country ORDER BY cr.total_revenue DESC) AS row_num
    FROM CustomerRevenue cr
) AS RankedCustomers
WHERE row_num <= 5
ORDER BY country, total_revenue DESC;

--6 Identify the top-selling track for each customer
Select concat(c.first_name, " " , c.last_name) as customer_name,
t.name as track_name, SUM(il.quantity) as total_sales
from customer c
left join invoice i on i.customer_id = c.customer_id
left join invoice_line il on il.invoice_id = i.invoice_id
left join track t on t.track_id = il.track_id
group by customer_name, track_name
order by total_sales desc;

--7
    SELECT 
    c.customer_id, 
    COUNT(i.invoice_id) AS purchase_frequency,
    AVG(i.total) AS avg_order_value, 
    i.billing_country, 
    i.billing_state
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, i.billing_country, i.billing_state
ORDER BY purchase_frequency ASC
LIMIT 1000;

--8
select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2018-01-01' and '2018-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2017-01-01' and '2017-12-31');
-- customers churned in 2018

select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2019-01-01' and '2019-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2018-01-01' and '2018-12-31');
-- customers churned in 2019

select count(distinct customer_id) as customer_count from invoice
where invoice_date between '2020-01-01' and '2020-12-31' and customer_id not in
(select distinct customer_id from invoice
where invoice_date between '2019-01-01' and '2019-12-31');
-- customers churned in 2020

select count(distinct customer_id) from invoice
where invoice_date between '2017-01-01' and '2017-12-31';
-- customers at the starting of 2018


select count(distinct customer_id) from invoice
where invoice_date between '2018-01-01' and '2018-12-31';
-- customers at the starting of 2019


select count(distinct customer_id) from invoice
where invoice_date between '2019-01-01' and '2019-12-31';
-- customers at the starting of 2020
--9
WITH GenreSales AS (
    SELECT 
        g.name AS genre_name,
        SUM(il.quantity * il.unit_price) AS total_sales
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    JOIN customer c ON i.customer_id = c.customer_id
    WHERE c.country = 'USA'
    GROUP BY g.genre_id
),
TotalSales AS (
    SELECT SUM(il.quantity * il.unit_price) AS total_sales
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON i.customer_id = c.customer_id
    WHERE c.country = 'USA'
)
SELECT 
    gs.genre_name,
    gs.total_sales,
    (gs.total_sales / ts.total_sales) * 100 AS percentage_of_total_sales
FROM GenreSales gs, TotalSales ts
ORDER BY gs.total_sales DESC;


--10
 SELECT 
c.customer_id,
COUNT(DISTINCT t.genre_id) AS genre_count
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
JOIN track t ON il.track_id = t.track_id
GROUP BY c.customer_id
HAVING genre_count >= 3
order by genre_count desc;


--11
SELECT 
 g.name AS genre_name,
 SUM(il.quantity * il.unit_price) AS total_sales
 FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN customer c ON i.customer_id = c.customer_id
WHERE c.country = 'USA'
GROUP BY g.genre_id
ORDER BY total_sales DESC;

--12
select c.customer_id, concat(c.first_name, " " , c.last_name) as customer_name, max(i.invoice_date) as last_purchase_date
from customer c
join invoice i on c.customer_id = i.customer_idS
group by c.customer_id
having last_purchase_date < DATE_SUB((Select max(invoice_date) from invoice), interval 3 month);


--subjective analysis
--1

SELECT a.album_id, a.title, g.name AS genre, SUM(il.quantity * il.unit_price) AS total_sales
FROM album a
JOIN track t ON a.album_id = t.album_id
JOIN genre g ON t.genre_id = g.genre_id
JOIN invoice_line il ON t.track_id = il.track_id
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
WHERE c.country = 'USA'
GROUP BY a.album_id, a.title, g.name
ORDER BY total_sales DESC
LIMIT 3;


--2
SELECT c.country, g.name AS genre, SUM(il.quantity * il.unit_price) AS total_sales
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN customer c ON i.customer_id = c.customer_id
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
WHERE c.country != 'USA'
GROUP BY c.country, g.name
ORDER BY total_sales DESC;

--3
with month_difference as(Select i.customer_id, max(invoice_date), min(invoice_date), 
ABS(TIMESTAMPDIFF(MONTH, max(invoice_date), min(invoice_date))) time_for_each_customer, 
sum(total) sales, sum(quantity) items, count(invoice_date) frequency 
from invoice i
left join customer c on c.customer_id = i.customer_id
left join invoice_line il on il.invoice_id = i.invoice_id
group by i.customer_id
order by time_for_each_customer desc),
average_time as(Select avg(time_for_each_customer) as average from month_difference),
customer_category as(Select *,
Case
when time_for_each_customer > (Select average from average_time) then "Long-term Customer"
else "New Customer"
end as category
from month_difference)
Select category, sum(sales) total_spending, sum(items) basket_size, count(frequency) frequency_count 
from customer_category
group by category;


--4
SELECT 
    g.name AS genre,
    a.title AS album,
    COUNT(DISTINCT i.invoice_id) AS times_purchased_together,
    SUM(il.quantity * il.unit_price) AS total_sales
FROM invoice_line il
JOIN invoice i ON il.invoice_id = i.invoice_id
JOIN track t ON il.track_id = t.track_id
JOIN album a ON t.album_id = a.album_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY g.name, a.title
ORDER BY times_purchased_together DESC, total_sales DESC;


--5
 WITH CustomerPurchases AS (
    SELECT 
        c.customer_id,
        c.city,
        COUNT(i.invoice_id) AS purchase_frequency,
        SUM(il.quantity * il.unit_price) AS total_spending,
        MIN(i.invoice_date) AS first_purchase_date,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id, c.city
),
ChurnAnalysis AS (
    SELECT 
        cp.customer_id,
        cp.city,
        CASE 
            WHEN DATEDIFF(CURDATE(), MAX(i.invoice_date)) > 90 THEN 'Churned'
            ELSE 'Active'
        END AS churn_status
    FROM CustomerPurchases cp
    JOIN invoice i ON cp.customer_id = i.customer_id
    GROUP BY cp.customer_id, cp.city
)
SELECT 
    ca.city,
    COUNT(DISTINCT ca.customer_id) AS total_customers,
    SUM(CASE WHEN ca.churn_status = 'Churned' THEN 1 ELSE 0 END) AS churned_customers,
    AVG(cp.purchase_frequency) AS avg_purchase_frequency,
    AVG(cp.total_spending) AS avg_total_spending
FROM ChurnAnalysis ca
JOIN CustomerPurchases cp ON ca.customer_id = cp.customer_id
GROUP BY ca.city
ORDER BY churned_customers DESC;


--6
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    c.state,
    c.country,
    SUM(il.quantity * il.unit_price) AS total_spending,
    COUNT(i.invoice_id) AS purchase_frequency,
    DATEDIFF(CURDATE(), MAX(i.invoice_date)) AS days_since_last_purchase,
    CASE
        WHEN SUM(il.quantity * il.unit_price) < 100 THEN 'Low Spender'
        WHEN COUNT(i.invoice_id) < 5 THEN 'Infrequent Shopper'
        WHEN DATEDIFF(CURDATE(), MAX(i.invoice_date)) > 90 THEN 'At Risk'
        ELSE 'Active'
    END AS risk_profile
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
JOIN invoice_line il ON i.invoice_id = il.invoice_id
GROUP BY c.customer_id
HAVING risk_profile IN ('At Risk', 'Low Spender', 'Infrequent Shopper')
ORDER BY total_spending DESC;


--7
--CLV = (Average Purchase Value) * (Purchase Frequency) * (Customer Lifespan)
WITH CustomerLifetime AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        c.city,
        c.state,
        c.country,
        SUM(il.quantity * il.unit_price) AS total_spending,
        COUNT(i.invoice_id) AS purchase_frequency,
        DATEDIFF(CURDATE(), MIN(i.invoice_date)) AS customer_tenure, -- Customer tenure in days
        DATEDIFF(CURDATE(), MAX(i.invoice_date)) AS days_since_last_purchase,
        MIN(i.invoice_date) AS first_purchase_date,
        MAX(i.invoice_date) AS last_purchase_date
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id, c.city, c.state, c.country -- Include city, state, country here
),
CLVPrediction AS (
    SELECT 
        customer_id,
        total_spending,
        purchase_frequency,
        customer_tenure,
        (total_spending / purchase_frequency) AS avg_purchase_value,  -- Average value per purchase
        (customer_tenure / 365) AS customer_lifespan_years,  -- Approximate customer lifespan in years
        CASE 
            WHEN days_since_last_purchase > 90 THEN 'At Risk'
            ELSE 'Active'
        END AS churn_status,
        city,
        state,
        country
    FROM CustomerLifetime
)
SELECT 
    customer_id,
    avg_purchase_value * purchase_frequency * customer_lifespan_years AS predicted_clv, -- CLV prediction
    churn_status,
    city,
    state,
    country,
    total_spending,
    purchase_frequency,
    customer_tenure
FROM CLVPrediction
ORDER BY predicted_clv DESC;

--10
Alter table album
Add column release_year INT DEFAULT 0;
DESC album;

--11
SELECT 
    customer_summary.country,
    COUNT(DISTINCT customer_summary.customer_id) AS num_customers,
    AVG(customer_summary.total_spent) AS avg_total_spent,
    AVG(customer_summary.total_tracks) AS avg_tracks_purchased
FROM (
    SELECT 
        c.customer_id, 
        c.country,
        SUM(il.quantity * il.unit_price) AS total_spent,
        SUM(il.quantity) AS total_tracks
    FROM customer c
    JOIN invoice i ON c.customer_id = i.customer_id
    JOIN invoice_line il ON i.invoice_id = il.invoice_id
    GROUP BY c.customer_id, c.country
) AS customer_summary
GROUP BY customer_summary.country;


--
/*
Argentina: 1 customer, average total spent of 39.60, average tracks purchased 40.
Australia: 1 customer, average total spent of 81.18, average tracks purchased 82.
Brazil: 5 customers, average total spent of 85.54, average tracks purchased 86.4.
USA: 13 customers, average total spent of 80.04, average tracks purchased 80.85.
*/

    











