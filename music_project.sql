
use Music;

/*	Question Set 1 - Easy */

/* Q1: Who is the senior most employee based on job title? */

select title, last_name, first_name 
from employee
order by levels desc
limit 1;

/* Q2: Which countries have the most Invoices? */

select billing_country, count(invoice_id) from invoice group by billing_country ;

/* Q3: What are top 3 values of total invoice? */

select * from invoice order by total desc limit 3;

/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city, sum(total)as s from invoice group by billing_city order by s desc limit 4;

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

with cte as (select customer_id,sum(total) as sum from invoice  group by customer_id order by sum desc limit 4)
select *from customer inner join cte on customer.customer_id=cte.customer_id limit 1;

/* Question Set 2 - Moderate */

/* Q1: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */


select distinct email,first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
	select track_id from track
	join genre on track.genre_id = genre.genre_id
	where genre.name like 'Rock'
    
)
order by email;

/* Q2: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select t3.id,t3.name,t3.cnt from artist inner join
(select t2.id,t2.name,count(t2.id) as cnt from 
(select artist.artist_id as id , artist.name , album2.album_id from album2 inner join artist 
on artist.artist_id=album2.artist_id) as t2
inner join (select track.album_id , track.track_id from track inner join genre 
on track.genre_id=genre.genre_id where genre.name ='Rock')as t1 
on t1.album_id=t2.album_id group by  t2.id ,t2.name) as t3 
on t3.id=artist.artist_id 
order by t3.cnt desc;

/* Q3: Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

with cte as (select avg(milliseconds) from track)
select name , milliseconds from track where milliseconds > 
(select avg(milliseconds) from track) 
order by milliseconds desc;

/* Question Set 3 - Advance */

/* Q1: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */


with best_selling_artist as (
    select
        artist.artist_id as artist_id, 
        artist.name as artist_name, 
        sum(invoice.total) as total_sales
    from
        invoice_line
    join
        track on track.track_id = invoice_line.track_id
    join 
        album2 on album2.album_id = track.album_id  -- Assuming 'album' is the correct table name instead of 'album2'
    join
        artist on artist.artist_id = album2.artist_id
    join
        invoice on invoice.invoice_id = invoice_line.invoice_id  -- Assuming invoice table is needed for invoice.total
    group by
        artist.artist_id, artist.name
    order by 
        total_sales desc
    
)

select c.customer_id, c.first_name, c.last_name, bsa.artist_name, sum(il.unit_price*il.quantity) as amount_spent
from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album2 alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;

/* Q2: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */


with cte as (select i4.name as genre_name,i1.billing_country,i1.total from invoice as i1
inner join invoice_line i2 on i1.invoice_id=i2.invoice_id
inner join track as i3 on i2.track_id=i3.track_id
inner join genre as i4 on i4.genre_id=i3.genre_id)
, cte1 as (select genre_name,billing_country,count(total) as total_spent from cte 
group by genre_name,billing_country 
order by total_spent desc)

select t1.genre_name,t1.billing_country,t2.max_spent from cte1 as t1 inner join 
(select  billing_country, max(total_spent)as max_spent from cte1 
group by billing_country 
order by 2 desc) as t2 
on t2.max_spent=t1.total_spent 
where t1.billing_country=t2.billing_country;

/* alternate query */

with popular_genre as 
(
    select count(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	dense_rank() over(partition by customer.country order by count(invoice_line.quantity) desc) as RowNo 
    from invoice_line 
	join invoice on invoice.invoice_id = invoice_line.invoice_id
	join customer on customer.customer_id = invoice.customer_id
	join track on track.track_id = invoice_line.track_id
	join genre on genre.genre_id = track.genre_id
	group by 2,3,4
	order by 1 desc
)
select * from popular_genre where RowNo <= 1;

/* Q3: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

with cte as (
select concat(i2.first_name,' ',i2.last_name) as name ,i2.country,sum(i1.total)as total from invoice as i1 
inner join customer as i2
on i1.customer_id=i2.customer_id
group by 1,2
order by 3 desc)
select row_number() over() as row_no,t1.name,t1.country,t1.total from cte as t1 inner join 
(select country, max(total)as total from cte group by 1) as t2 on t1.total=t2.total order by 3;
 
 /* alternate query */
 
with Customter_with_country as (
		select customer.customer_id,first_name,last_name,billing_country,sum(total) as total_spending,
	    dense_rank() over(partition by billing_country order by sum(total) desc) as RowNo 
		from invoice
		join customer on customer.customer_id = invoice.customer_id
		group by 1,2,3,4
		order by 4 asc,5 desc)
select * from Customter_with_country where RowNo <= 1

