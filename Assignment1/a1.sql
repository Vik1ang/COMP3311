-- 1
create or replace view Q1(pid, firstname, lastname) as
select pid, firstname, lastname
from person
where pid not in (select pid from staff)
  and pid not in (select pid from client)
order by pid asc;

-- 2
create or replace view Q2(pid, firstname, lastname) as
select *
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
select *
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
    returns integer
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
    LANGUAGE 'sql'
    VOLATILE
    CALLED ON NULL INPUT
    SECURITY INVOKER;

-- 11
create or replace procedure renew(pno integer) as
$body$
declare
    p_ptype     char;
    p_status    varchar(2);
    p_effective date;
    p_expire    date;
    p_value     real;
    p_comments  varchar(80);
    p_sid       integer;
    p_id        integer;
    count       bigint;
    countP      bigint;
    newP        bigint;
    countV      bigint;
    flag        integer := 1;
begin

    select count(1) from policy p where p.pno = $1 into count;
    select ptype,
           status,
           effectivedate,
           expirydate,
           agreedvalue,
           comments,
           sid,
           id
    from policy
    into p_ptype, p_status, p_effective, p_expire, p_value, p_comments, p_sid, p_id;
    select count(1)
    from policy p
    where p.pno = $1
      and status not in ('D', 'RR', 'AR')
      and expirydate > now()
    into countP;

    select count(id)
    from policy
    where ptype = ptype
      and status not in ('D', 'RR', 'AR')
      and expirydate > now()
      and id = p_id
    into countV;

    if (count == 0) then
        flag = 0;

    elsif (countV > 1) then
        flag = 0;
    elsif (count > 0) then
        update policy p set expirydate = now() where p.pno = $1;
        insert into policy(ptype, status, effectivedate, expirydate, agreedvalue, comments, sid, id)
        VALUES (p_ptype, p_status, now(), now() + (p_expire - p_effective), p_value, p_comments, p_sid, p_id);
        select max(p.pno) from policy p into newP;
        with new_coverage as (select * from coverage c where c.pno = $1)
        insert
        into coverage(cname, maxamount, comments, pno)
        values (new_coverage.cname, new_coverage.maxamount, new_coverage.comments, newP);
    else
        insert into policy(ptype, status, effectivedate, expirydate, agreedvalue, comments, sid, id)
        values (p_ptype, p_status, now(), now() + (p_expire - p_effective), p_value, p_comments, p_sid, p_id);
        select max(p.pno) from policy p into newP;
        with new_coverage as (select * from coverage c where c.pno = $1)
        insert
        into coverage(cname, maxamount, comments, pno)
        values (new_coverage.cname, new_coverage.maxamount, new_coverage.comments, newP);
    end if;
    if (flag = 0) then
        rollback;
    else
        commit;
    end if;
end;
$body$
    LANGUAGE 'plpgsql';

-- 12

create function insure_create() returns trigger
as
$$
declare
    p_pid   integer;
    p_pid_c integer;
begin
    select p2.pid
    from policy
             left join staff s on policy.sid = s.sid
             left join person p2 on s.pid = p2.pid
    where policy.pno = old.pno
    into p_pid;
    select p.pid
    from client c
             left join person p on c.pid = p.pid
    where c.cid = old.cid
    into p_pid_c;
    if p_pid <> p_pid_c then
        insert into insured_by(cid, pno) VALUES (new.cid, new.pno);
    end if;
end;
$$
    language plpgsql;

create trigger check_insure
    before insert or update
    on insured_by
    for each row
execute procedure insure_create();

create function check_rate_create() returns trigger
as
$$
declare
    p_pid integer;
begin
    select
    from person
             left join staff s on person.pid = s.pid
    where s.sid = old.sid
    into p_pid;
    if p_pid not in (select p.pid
                     from rating_record rr
                              left join coverage c on rr.coid = c.coid
                              left join insured_by ib on c.pno = ib.pno
                              left join client c2 on ib.cid = c2.cid
                              left join person p on c2.pid = p.pid
                     where rid = old.rid) then
        insert into rated_by(sid, rid, rdate, comments)
        values (old.sid, old.rid, old.rdate, old.comments);
    end if;
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
declare
    p_pid integer;
begin
    select p.pid
    from person p
             left join staff s on s.pid = p.pid
    into p_pid;
    if p_pid not in (select p2.pid
                     from underwriting_record ur
                              left join policy p on ur.pno = p.pno
                              left join insured_by ib on p.pno = ib.pno
                              left join client c on ib.cid = c.cid
                              left join person p2 on c.pid = p2.pid
                     where ur.urid = old.urid) then
        insert into underwritten_by(sid, urid, wdate, comments) values (old.sid, old.urid, old.wdate, old.comments);
    end if;
end;
$$
    language plpgsql;

create trigger check_under
    before insert or update
    on underwritten_by
    for each row
execute procedure check_under_create();


