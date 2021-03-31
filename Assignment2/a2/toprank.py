import sqlite3
import sys

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)

    con = sqlite3.connect('a2.db')

    sql_top_rank = '''
    select distinct m.title,
                '(' || ifnull(m.year || ', ', '') || ifnull(m.content_rating || ', ', '') ||
                ifnull(m.lang, '') || ')',
                '[' || ifnull(r.imdb_score || ', ', '') || ifnull(r.num_voted_users, '') || ']',
                (select group_concat(g1.genre) from genre g1 where g1.movie_id = g.movie_id order by g1.genre)
    from movie m
         left join acting a on m.id = a.movie_id
         left join actor a2 on a.actor_id = a2.id
         left join director d on m.director_id = d.id
         left join keyword k on m.id = k.movie_id
         left join genre g on m.id = g.movie_id
         left join rating r on m.id = r.movie_id
    where 
    '''

    score = 0

    if sys.argv[2] == '' or sys.argv[2] is None:
        score = 0
    else:
        score = sys.argv[2]

    sql_top_rank += 'r.imdb_score >= ' + score

    genre = []
    if sys.argv[1] != '':
        genre = sys.argv[1].split('&')
        sql_top_rank += ' and g.genre in ('
        genre = set(genre)
        genre = [i for i in genre]
        for i in range(len(genre)):
            if i == len(genre) - 1:
                sql_top_rank += '\'' + genre[i] + '\''
            else:
                sql_top_rank += '\'' + genre[i] + '\'' + ','
        sql_top_rank += ')'

    sql_top_rank += ' order by r.imdb_score desc, r.num_voted_users desc;'


    cur = con.cursor()

    cur.execute(sql_top_rank, )

    i = 1
    while True:
        t = cur.fetchone()
        if t is None:
            break
        genre_helper = t[3].split(',')
        flag = True
        for _ in range(len(genre)):
            if genre[_] not in genre_helper:
                flag = False
                break
        if flag is False:
            continue
        print('{}. {} {} {}'.format(i, t[0], t[1], t[2]))
        i += 1
    con.close()
