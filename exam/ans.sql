-- COMP3311 21T1 Exam SQL Answer Template
--
-- * Don't change view names and view arguments;
-- * Only change the SQL code for view as commented below;
-- * and do not remove the ending semicolon of course.
--
-- * You may create additional views, if you wish;
-- * but you are not allowed to create tables.
--


-- Q1. Find the brewers whose beers John likes.

create or replace view Q1(brewer) as
-- replace the SQL code below:
select b1.name
from brewers b1
         left join beers b2 on b1.id = b2.brewer
         left join likes l on b2.id = l.beer
         left join drinkers d on l.drinker = d.id
where d.name like 'John'
order by b1.name asc
;


-- Q2. How many beers does each brewer make?

create or replace view Q2(brewer, nbeers) as
-- replace the SQL code below:
select b1.name brewer, count(1) nbeers
from brewers b1
         left join beers b2 on b1.id = b2.brewer
group by b1.name
order by b1.name
;


-- Q3. Beers sold at bars where John drinks.

create or replace view Q3(beer) as
-- replace the SQL code below:
select distinct b.name beer
from beers b
         left join sells s on b.id = s.beer
         left join bars b2 on s.bar = b2.id
         left join frequents f on b2.id = f.bar
         left join drinkers d on f.drinker = d.id
where d.name like 'John'
order by b.name asc
;


-- Q4. What is the most expensive beer?

create or replace view Q4(beer) as
-- replace the SQL code below:
select distinct b.name
from beers b
         left join sells s on b.id = s.beer
where s.price in (select max(sells.price) from sells)
order by b.name asc
;


-- Q5. Find the average price of common beers
--      ("common" = served in more than two hotels).

create or replace view Q5(beer, "AvgPrice") as
-- replace the SQL code below:
select b.name, avg(s.price)::numeric(5,2)
from beers b
         left join sells s on b.id = s.beer
where s.beer in (select s.beer
                 from sells s
                 group by s.beer
                 having count(s.bar) > 2)
group by b.name order by b.name
;

create or replace view Bar_min_price as
select b.id, b.name as bar, min(s.price)::numeric(5,2) as min_price
from   Bars b
         join Sells s on (b.id=s.bar)
group  by b.id, b.name
;

-- Q6. Name of cheapest beer at each bar?

create or replace view Q6(bar, beer) as
-- replace the SQL code below:
with a1 as (select b.id, b.name as bar, min(s.price) as min_price
            from Bars b
                     join Sells s on (b.id = s.bar)
            group by b.id, b.name)
select a1.bar, be.name
from beers be
         left join sells s2 on be.id = s2.beer
         left join bars b2 on s2.bar = b2.id
         left join a1 on a1.id = s2.bar
where a1.min_price = s2.price
  and a1.id = s2.bar
group by a1.bar, be.name
order by a1.bar, be.name
;

