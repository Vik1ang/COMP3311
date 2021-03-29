-- 1
create or replace view Q1(pid, firstname, lastname) as
select pid, firstname, lastname
from person
where pid not in (select pid from staff)
  and pid not in (select pid from client)
order by pid asc;

-- 2
create or replace view Q2(pid, firstname, lastname) as
select pid, firstname, lastname
from person
where pid not in (select pid
                  from client
                  where cid in (select distinct cid
                                from insured_by
                                where pno in (select pno
                                              from policy
                                              where status not in ('D', 'RR', 'AR')
                                )))
order by pid asc;

-- 3
create or replace view Q3(brand, vid, pno, premium) as
select distinct on (sub.brand) brand, sub.id vid, sub.pno pno, sum(sub.rate) premium
from (select ii.id, ii.brand, rr.rate, p.pno
      from insured_item ii
               inner join policy p on ii.id = p.id
               inner join coverage c on c.pno = p.pno
               inner join rating_record rr on rr.coid = c.coid
               inner join underwriting_record ur on ur.pno = p.pno
      where p.status not in ('D', 'RR', 'AR')
        and p.effectivedate < now()
        and rr.status not in ('R', 'W')
        and ur.status not in ('R', 'W')) sub
group by sub.brand, sub.pno, sub.id
order by brand, id, premium desc, sub.pno;

-- 4
create or replace view Q4(pid, firstname, lastname) as
select pid, firstname, lastname
from person
where pid in (select pid
              from staff
              where sid not in (select sid from underwritten_by));


-- 5
create or replace view Q5(suburb, npolicies) as
select suburb, count(1) npolicies
from client c
         left join insured_by ib on c.cid = ib.cid
         left join person p on c.pid = p.pid
         left join policy p2 on ib.pno = p2.pno
where p2.status in ('E')
group by suburb
order by npolicies;

-- 6
create or replace view Q6(pno, ptype, pid, firstname, lastname) as
select ur.pno, p.ptype, p2.pid, p2.firstname, p2.lastname
from underwriting_record ur
         left join policy p on ur.pno = p.pno
         left join staff s on p.sid = s.sid
         left join person p2 on s.pid = p2.pid
where ur.status not in ('R', 'W')
  and p.status not in ('D', 'RR', 'AR')
  and p.sid in (select sid
                from rated_by
                where rid not in (select rating_record.rid from rating_record where status not in ('R', 'W')))
order by pno asc;

-- 7
create or replace view Q7(pno, ptype, effectivedate, expirydate, agreedvalue) as
select pno, ptype, effectivedate, expirydate, agreedvalue
from (select *, (expirydate - effectivedate) duration
      from policy) sub
where sub.duration = (select max(sub1.duration)
                      from (select *, (expirydate - effectivedate) duration
                            from policy) sub1)
  and status not in ('D', 'RR', 'AR')
order by pno asc;

-- 8
create or replace view Q8(pid, name, brand) as
select distinct p2.pid, concat(firstname, ' ', lastname) as name, brand
from policy p
         left join staff s on p.sid = s.sid
         left join insured_item ii on p.id = ii.id
         left join person p2 on s.pid = p2.pid
where p2.pid in (select sub.pid
                 from (select p2.pid, brand
                       from coverage c
                                left join policy p on c.pno = p.pno
                                left join insured_item ii on p.id = ii.id
                                left join rated_by rb on p.sid = rb.sid
                                left join staff s on p.sid = s.sid
                                left join person p2 on s.pid = p2.pid
                       where p.status not in ('R', 'W')
                       group by p2.pid, brand) sub
                 group by pid
                 having count(sub.pid) = 1)
order by p2.pid asc;

-- 9
create or replace view Q9(pid, name) as
with countBrand as (select count(distinct brand) from insured_item)
select pid, concat(firstname, ' ', lastname) as name
from person
where pid in (
    select pid
    from (select ii.brand, c.pid
          from insured_by ib
                   left join policy p on ib.pno = p.pno
                   left join insured_item ii on p.id = ii.id
                   left join client c on ib.cid = c.cid
                   left join person p2 on c.pid = p2.pid
          where p.effectivedate < now()
            and p.expirydate > now()
          group by brand, c.pid) sub
    group by sub.pid
    having count(sub.brand) = (select * from countBrand)
)
order by pid asc;

-- 10
create or replace function staffcount(pno integer)
    returns bigint
as
$body$
select count(1)
from (select rb.sid
      from rated_by rb
               left join rating_record rr on rb.rid = rr.rid
               left join coverage c on rr.coid = c.coid
      where c.pno = $1
      union
      select ub.sid
      from underwritten_by ub
               left join underwriting_record ur on ub.urid = ur.urid
               left join policy p on ur.pno = p.pno
      where ur.pno = $1
      union
      select p.sid
      from policy p
      where p.pno = $1) sub
$body$
    LANGUAGE 'sql';

-- 11
create or replace procedure renew(pno integer) as
$$
declare
    cname_1 varchar(20);
begin
    if (select count(1) from policy p where p.pno = $1) = 0 then

    elsif (select count(1)
           from policy p
           where p.pno = $1
             and status not in ('D', 'RR', 'AR')
             and expirydate < now()) > 0 then
        with temp as (select ptype,
                             status,
                             effectivedate,
                             expirydate,
                             agreedvalue,
                             comments,
                             sid,
                             id
                      from policy p
                      where p.pno = $1)
        insert
        into policy(pno, ptype, status, effectivedate, expirydate, agreedvalue, comments, sid, id)
        values ((select max(p.pno) from policy p) + 1, temp.ptype, temp.status, temp.effectivedate, temp.expirydate,
                temp.agreedvalue, temp.comments, temp.sid,
                temp.id);
        with new_coverage as (select * from coverage c where c.pno = $1)
        insert
        into coverage(coid, cname, maxamount, comments, pno)
        values ((select max(coid) from coverage) + 1, new_coverage.cname, new_coverage.maxamount, new_coverage.comments,
                (select max(p.pno) from policy p));
    elseif (select count(1)
            from policy p
            where p.pno = $1
              and status not in ('D', 'RR', 'AR')
              and expirydate > now()) > 0 then

        with temp as (select ptype,
                             status,
                             effectivedate,
                             expirydate,
                             agreedvalue,
                             comments,
                             sid,
                             id
                      from policy p
                      where p.pno = $1)
        insert
        into policy(pno, ptype, status, effectivedate, expirydate, agreedvalue, comments, sid, id)
        values ((select max(p.pno) from policy p) + 1, (select ptype from temp), 'D',
                now(),
                now() + (select expirydate from temp) - (select effectivedate from temp),
                (select agreedvalue from temp),
                (select comments from temp),
                (select sid from temp), (select id from temp));
        update policy set expirydate = now() where pno = $1;
        with new_coverage as (select * from coverage c where c.pno = $1 limit 1)
        insert
        into coverage(coid, cname, maxamount, comments, pno)
        values ((select max(coid) from coverage) + 1, (select cname from new_coverage),
                (select maxamount from new_coverage), (select comments from new_coverage),
                (select max(p.pno) from policy p));
    end if;
    commit;
end;

$$
    language plpgsql;


-- 12
create function insure_create() returns trigger
as
$$
begin
    if (new.cid = (select sid from policy p where p.pno = new.pno)) then
        raise exception 'same cid and sid';
    end if;
    return new;
end;
$$
    language plpgsql;

create trigger check_insure
    before insert or update
    on insured_by
    for each row
execute procedure insure_create();

insert into insured_by (cid, pno)
values (1, 7);

create function check_rate_create() returns trigger
as
$$
begin
    if (new.sid in (select cid
                    from insured_by ib
                    where pno = (select distinct pno
                                 from rated_by rb
                                          left join rating_record rr on rb.rid = rr.rid
                                          left join coverage c on rr.coid = c.coid
                                 where rb.rid = new.rid
                                   and rb.sid = new.sid
                                   and rb.comments = new.comments
                                   and rb.rdate = new.rdate)
    )) then
        raise exception 'same cid and sid';
    end if;
    return new;
end;
$$
    language plpgsql;


create trigger check_rate
    before insert or update
    on rated_by
    for each row
execute procedure check_rate_create();

create function check_under_create() returns trigger as
$$
begin
    if (new.sid in (select cid
                    from insured_by ib
                             left join underwriting_record ur on ib.pno = ur.pno
                             left join underwritten_by ub on ur.urid = ub.urid
                    where ub.sid = new.sid
                      and ub.urid = new.urid
                      and ub.comments = new.comments
                      and ub.wdate = new.wdate)) then
        raise exception 'same cid and sid';
    end if;
    return new;
end;
$$
    language plpgsql;

create trigger check_under
    before insert or update
    on underwritten_by
    for each row
execute procedure check_under_create();


