-- 1.	Show all customers whose last names start with T. Order them by first name from A-Z.

select concat (first_name,' ', last_name) as customers from customer
where last_name LIKE 'T%'
order by first_name;

-- 2.	Show all rentals returned from 5/28/2005 to 6/1/2005

select * from rental
where return_date between '2005/05/28' AND '2005/06/01';

-- 3.	How would you determine which movies are rented the most?
select f.title, count(r.inventory_id) AS no_of_times_rented 
from rental AS r
JOIN inventory as i
USING (inventory_id) 
JOIN film as f
USING (film_id)
group by f.title
order by no_of_times_rented DESC;

	
-- 4.	Show how much each customer spent on movies (for all time) . Order them from least to most.
select concat(first_name,' ', last_name) as customer_name, customer_id, sum(amount) as total_expenditure
from payment as p
join customer as c
using (customer_id)
group by customer_id
order by total_expenditure;

-- 5.	Which actor was in the most movies in 2006 (based on this dataset)? Be sure to alias the actor name and count as a more descriptive name. Order the results from most to least.
select concat(first_name,' ', last_name) as actor_name, count(film_id) as no_of_films
from film_actor
JOIN actor
USING (actor_id)
group by actor_id
order by no_of_films DESC;

-- 6.	Write an explain plan for 4 and 5. Show the queries and explain what is happening in each one. Use the following link to understand how this works http://postgresguide.com/performance/explain.html

	-- Explain plan for #4
		EXPLAIN (FORMAT JSON) 
		select concat(first_name,' ', last_name) as customer_name, customer_id, sum(amount) as total_expenditure
		-- Sorts the columns selected and aggregate amount column 
		from payment as p
		join customer as c
		using (customer_id)
		-- inner joins payment and customer tables on customer_id by sequentiall scans on both tables
		group by customer_id
		order by sum(amount);
		-- groups the result by key customer_id and orders by aggregate sum(amount)
		
		-- QUERY PLAN
		/*
		1.	Sort (cost=423.12..424.62 rows=599 width=49)	
		2.	Aggregate (cost=388..395.49 rows=599 width=49)	
		3.	Hash Inner Join (cost=22.48..315.02 rows=14596 width=23)
		Hash Cond: (p.customer_id = c.customer_id)
		4.	Seq Scan on payment as p (cost=0..253.96 rows=14596 width=8)	
		5.	Hash (cost=14.99..14.99 rows=599 width=17)
		6.	Seq Scan on customer as c (cost=0..14.99 rows=599 width=17)
		*/
		
	-- Explain plan for #5

		EXPLAIN (FORMAT JSON)
		select concat(first_name,' ', last_name) as actor_name, count(film_id) as no_of_films
		-- sorts and aggregates select columns 
		from film_actor
		JOIN actor
		USING (actor_id)
		-- inner join on film_actor and acot on actor_id by seq scan on both tables
		group by actor_id
		order by count(film_id) DESC;
		-- groups the result by actor_id and orders in descending order by agg count(film_id)
		
		-- QUERY PLAN
		/*1.	Sort (cost=143.21..143.71 rows=200 width=44)	
		2.	Aggregate (cost=133.07..135.57 rows=200 width=44)
		3.	Hash Inner Join (cost=6.5..105.76 rows=5462 width=19)
		Hash Cond: (film_actor.actor_id = actor.actor_id)
		4.	Seq Scan on film_actor as film_actor (cost=0..84.62 rows=5462 width=4)	
		5.	Hash (cost=4..4 rows=200 width=17)	
		6.	Seq Scan on actor as actor (cost=0..4 rows=200 width=17)
		*/

-- 7.	What is the average rental rate per genre?
select name AS genre, avg(rental_rate) as avg_rental_rate
from film
join film_category
using (film_id)
join category
using (category_id)
group by genre;

-- 8.	How many films were returned late? Early? On time?

CREATE VIEW exp_return_date as
select inventory_id, rental_date, (rental_date + INTERVAL'1 day'*rental_duration) as expected_return_date, return_date,
	CASE WHEN (rental_date + INTERVAL'1 day'*rental_duration) < return_date THEN 'Early'
	WHEN (rental_date + INTERVAL'1 day'*rental_duration) = return_date THEN 'On Time'
	ELSE 'LATE' END as timing
from rental
join inventory
using (inventory_id)
join film
using (film_id)
group by inventory_id, rental_date, rental_duration, return_date;

select timing, count(inventory_id) as num_of_films
from exp_return_date
group by timing;

-- 9.	What categories are the most rented and what are their total sales?

select category, count(rental_id) as times_rented, total_sales
from rental
inner join inventory
using (inventory_id)
inner join film_category
using (film_id)
inner join category as c
using(category_id)
inner join sales_by_film_category as s
on c.name = s.category
group by category, total_sales
order by count(rental_id) DESC;

-- 10.	Create a view for 8 and a view for 9. Be sure to name them appropriately. 

/* View for # 8 */

CREATE VIEW early_ontime_late_returns AS
	select inventory_id, rental_date, (rental_date + INTERVAL'1 day'*rental_duration) as expected_return_date, return_date,
		CASE WHEN (rental_date + INTERVAL'1 day'*rental_duration) < return_date THEN 'Early'
		WHEN (rental_date + INTERVAL'1 day'*rental_duration) = return_date THEN 'On Time'
		ELSE 'LATE' END as timing
	from rental
	join inventory
	using (inventory_id)
	join film
	using (film_id)
	group by inventory_id, rental_date, rental_duration, return_date;
	select timing, count(inventory_id) as num_of_films
	from return_time
	group by timing;

/* View for # 9 */

CREATE VIEW top_category_sales AS
	select category, count(rental_id) as times_rented, total_sales
	from rental
	inner join inventory
	using (inventory_id)
	inner join film_category
	using (film_id)
	inner join category as c
	using(category_id)
	inner join sales_by_film_category as s
	on c.name = s.category
	group by category, total_sales
	order by count(rental_id) DESC;
	
	
-- Bonus: Write a query that shows how many films were rented each month. Group them by category and month. 
select EXTRACT(MONTH FROM rental_date) as month, name as category, count(inventory_id) as num_of_films_rented
from rental
inner join inventory
using (inventory_id)
inner join film_category
using (film_id)
inner join category as c
using(category_id) 
group by month, category
order by month;
