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
select 'ABC'

;


-- Q2. How many beers does each brewer make?

create or replace view Q2(brewer, nbeers) as
-- replace the SQL code below:
select 'ABC', 1

;


-- Q3. Beers sold at bars where John drinks.

create or replace view Q3(beer) as
-- replace the SQL code below:
select 'ABC'

;


-- Q4. What is the most expensive beer?

create or replace view Q4(beer) as
-- replace the SQL code below:
select 'ABC'

;


-- Q5. Find the average price of common beers
--      ("common" = served in more than two hotels).

create or replace view Q5(beer, "AvgPrice") as
-- replace the SQL code below:
select 'ABC', 1.00

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
select 'ABC', 'DEF'

;

