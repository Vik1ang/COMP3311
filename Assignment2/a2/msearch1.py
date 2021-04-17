#!/usr/bin/python3
import sqlite3
import sys
from functools import cmp_to_key

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)

    con = sqlite3.connect('a2.db')

    cur = con.cursor()
    final_set = ()
    for _p in sys.argv[1:]:
        sql_m = '''
            select distinct m.title,
                        '(' || ifnull(m.year || ', ', '') || ifnull(m.content_rating || ', ', '') ||
                        ifnull(printf('%.1f', r.imdb_score), '') || ')',
                        '[' || (select group_concat(g1.genre) from genre g1 where g1.movie_id = g.movie_id order by g1.genre) ||
                        ']', ifnull(m.year, 0), ifnull(r.imdb_score, 0)
        from movie m
                 left join acting a on m.id = a.movie_id
                 left join actor a2 on a.actor_id = a2.id
                 left join director d on m.director_id = d.id
                 left join keyword k on m.id = k.movie_id
                 left join genre g on m.id = g.movie_id
                 left join rating r on m.id = r.movie_id
        where a2.name like {} or m.title like {} or d.name like {}
        order by m.year desc, r.imdb_score desc, m.title asc;
            '''.format('\'%' + _p + '%\'', '\'%' + _p + '%\'', '\'%' + _p + '%\'')
        cur.execute(sql_m)
        temp_list = cur.fetchall()
        if len(final_set) is 0:
            temp_set = set(temp_list)
            final_set = temp_set
        else:
            temp_set = set(temp_list)
            final_set = final_set & temp_set

    i = 1
    output = []
    final_set = list(final_set)


    def cmp(x, y):
        if x[3] == y[3]:
            if x[4] == y[4]:
                return y[0] - x[0]
            else:
                return y[4] - x[4]
        else:
            return y[3] - x[3]


    final_set.sort(key=cmp_to_key(cmp))

    for _o in final_set:
        line = '{}. '.format(i) + _o[0] + ' ' + _o[1] + ' ' + _o[2]
        output.append(line)
        i += 1

    for _ in output:
        print(_)
