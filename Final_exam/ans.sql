-- COMP3311 21T1 Exam SQL Answer Template
--
-- * Don't change view/function names and view/function arguments;
-- * Only change the SQL code for view/function bodies as commented below;
-- * and do not remove the ending semicolon of course.
--
-- * You may create additional views, if you wish;
-- * but you are NOT allowed to create tables.
--


-- Q1. 

create or replace view Q1(name, total) as
-- replace the SQL code below:
select 'ABC', 1

;


-- Q2. 

create or replace view Q2(year, name) as
-- replace the SQL code below:
select 1, 'ABC'

;


-- Q3. 

create or replace view Q3 (title, name) as
-- replace the SQL code below:
select 'ABC', 'DEF'

;


-- Q4. 

create or replace view Q4 (name) as
-- replace the SQL code below:
select 'ABC'

;


-- Q5. 

create or replace view Q5(actor1, actor2) as
-- replace the SQL code below:
select 'ABC', 'DEF'

;


-- Q6. 

create or replace function
    experiencedActor(_m int, _n int) returns setof actor
as $$ 
declare
    -- fill in any declaration
begin
    -- fill in the body
end;
$$ language plpgsql;


-- Q7.
-- Define your trigger (or triggers) below



