import sqlite3
import sys

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)

    con = sqlite3.connect('a2.db')

    cur = con.cursor()

    sql_movie_search = '''
    select distinct m.title, 
    '(' || ifnull(m.year || ', ', '') || ifnull(m.content_rating || ', ', '') ||
                ifnull(r.imdb_score, '') || ')',
                '[' || (select group_concat(g1.genre) from genre g1 where g1.movie_id = g.movie_id order by g1.genre) ||
                ']'
    from movie m
         left join acting a on m.id = a.movie_id
         left join actor a2 on a.actor_id = a2.id
         left join director d on m.director_id = d.id
         left join keyword k on m.id = k.movie_id
         left join genre g on m.id = g.movie_id
         left join rating r on m.id = r.movie_id
    where 
    '''

    sql_search = '''(ifnull(m.title, '') || ifnull(d.name, '') || ifnull(a2.name, '')) like ? '''

    query_para = ''
    if len(sys.argv) == 2:
        query_para = sys.argv[1]

    parameters = []
    for i in range(1, len(sys.argv)):
        parameters.append('%' + sys.argv[i] + '%')
        if i == 1:
            sql_movie_search = sql_movie_search + sql_search
        else:
            sql_movie_search = sql_movie_search + 'and ' + sql_search

    sql_movie_search = sql_movie_search + ' order by m.year desc;'
    print(sql_movie_search)
    cur.execute(sql_movie_search, tuple(parameters))

    i = 1
    res_list = []
    while True:
        t = cur.fetchone()
        if t is None:
            break
        print('{}. {} {} {}'.format(i, t[0], t[1], t[2]))
        i += 1
    con.close()
