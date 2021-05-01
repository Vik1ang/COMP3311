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
select a1.name, count(a1.id) c1
from actor a1
         left join acting a on a1.id = a.actor_id
         left join movie m on a.movie_id = m.id
group by a1.name
order by c1 desc, a1.name
;


-- Q2. 

create or replace view Q2(year, name) as
-- replace the SQL code below:
with a1 as (select m.year, max(r.imdb_score) max_score
            from rating r
                     left join movie m on r.movie_id = m.id
                     left join director d2 on m.director_id = d2.id
            where year is not null
              and r.num_voted_users >= 100000
              and d2.id is not null
            group by m.year
            order by m.year)
select m.year, d.name
from a1
         inner join movie m on a1.year = a1.year
         inner join director d on m.director_id = d.id
         inner join rating r2 on m.id = r2.movie_id
where m.year = a1.year
  and r2.imdb_score = a1.max_score
  and d.id is not null
  and r2.num_voted_users >= 100000
  and m.year is not null
group by m.year, d.name
order by m.year, d.name
;


-- Q3. 

create or replace view Q3 (title, name) as
    -- replace the SQL code below:
select m.title, d.name
from movie m
         left join director d on m.director_id = d.id
where d.name in (select a2.name
                 from acting a1
                          left join actor a2 on a1.actor_id = a2.id
                 where a1.movie_id = m.id)
order by m.title, d.name;
;


-- Q4. 

create or replace view Q4 (name) as
-- replace the SQL code below:
with a1 as (select distinct on (d.id) d.id, d.name, m.year
            from director d
                     left join movie m on d.id = m.director_id
            group by d.id, m.year
            order by d.id, m.year)
select a1.name
from a1
where (select count(1)
       from movie m2
                left join acting a on m2.id = a.movie_id
                left join actor a2 on a.actor_id = a2.id
       where a2.name = a1.name
         and m2.year < a1.year) > 0
order by a1.name;
;


-- Q5. 

create or replace view Q5(actor1, actor2) as
-- replace the SQL code below:
select 'ABC', 'DEF'
;


-- Q6. 

create or replace function
    experiencedActor(_m int, _n int) returns setof actor
as
$$
declare
    -- fill in any declaration
begin
    -- fill in the body
    return query (with a1 as (select a.name, m.year
                              from actor a
                                       left join acting a2 on a.id = a2.actor_id
                                       left join movie m on a2.movie_id = m.id
                              group by a.name, m.year
                              order by a.name)
                  select a3.*
                  from actor a3
                           left join a1 on a3.name = a1.name
                  where a1.year is not null
                  group by a3.id, a1.name, a3.facebook_likes
                  having (case when max(a1.year) - min(a1.year) = 0 then 1 else max(a1.year) - min(a1.year) end) >= _m
                     and (case when max(a1.year) - min(a1.year) = 0 then 1 else max(a1.year) - min(a1.year) end) <= _n
                  order by id);
end;
$$ language plpgsql;


-- Q7.
-- Define your trigger (or triggers) below

create or replace function trigger_genre() returns trigger as
$$
declare
    a int;
begin
    select count(1) into a from genre g where g.movie_id = new.movie_id;
    if a > 5 then
        raise exception 'the number of genre greater than 5';
    end if;
    return new;
end;
$$
    language plpgsql;

create trigger check_genre
    before insert or update or delete
    on
        genre
    for each row
execute procedure trigger_genre();

create or replace function trigger_keyword() returns trigger as
$$
declare
    a int;
begin
    select count(1) into a from keyword where movie_id = new.movie_id;
    if a > 5 then
        raise exception 'the number of genre greater than 5';
    end if;
    return new;
end;
$$
    language plpgsql;

create trigger check_keyword
    before insert or update or delete
    on
        genre
    for each row
execute procedure trigger_keyword();


