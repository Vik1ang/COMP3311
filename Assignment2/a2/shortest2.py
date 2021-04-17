import sys
import sqlite3
import networkx as nx
from matplotlib import pyplot as plt
import time

if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)

    sys.argv[1] = sys.argv[1].title()
    sys.argv[2] = sys.argv[2].title()

    con = sqlite3.connect('a2.db')

    cur = con.cursor()

    sql_shortest_and = '''
    select distinct (select group_concat(a2.name)
                 from acting a1
                          left join actor a2 on a1.actor_id = a2.id
                 where a.movie_id = a1.movie_id) as actor_table,
                    m.title || ' (' || m.year || ')'
    from acting a
         left join movie m on a.movie_id = m.id
    where actor_table like {}
        and actor_table like {}
    group by movie_id, actor_id;
    '''.format('\'%' + sys.argv[1] + '%\'', '\'%' + sys.argv[2] + '%\'')

    output = []

    cur.execute(sql_shortest_and)

    i = 1
    while True:
        t = cur.fetchone()
        if t is None:
            break
        temp = str(i) + '. ' + sys.argv[1] + ' was in ' + t[1] + ' with ' + sys.argv[2]
        output.append(temp)
        i += 1

    print(*output, sep='\n')

    if len(output) is 0:
        g = nx.Graph()
        start = time.time()
        actor_set = set()
        sql_1 = '''
            select actor.name,
       (select group_concat(a2.name)
        from acting a1
                 left join actor a2 on a1.actor_id = a2.id
        where a.movie_id = a1.movie_id)

from actor
         left join acting a on actor.id = a.actor_id
         left join movie m on a.movie_id = m.id
group by actor.id, m.title;
        '''
        cur.execute(sql_1)
        actors_table = cur.fetchall()

        for _line in actors_table:
            temp_actor_list = []
            try:
                temp_actor_list = _line[1].split(',')
            except:
                pass
            for _i in temp_actor_list:
                g.add_edges_from([(_line[0], _i)])

        end = time.time()
        print(end - start)

        # nx.draw_networkx(g)
        # plt.show()
        print(1)
        # print(nx.has_path(g, source=sys.argv[1], target=sys.argv[2]))
        path = nx.all_shortest_paths(g, source=sys.argv[1], target=sys.argv[2])
        shortest_paths = list(path)
        print(shortest_paths)

        # print(path)
        # print(output)
        output.sort(key=lambda x: x[1])
        i = 1
        for _ in range(len(output)):
            print('{}.'.format(i), output[_][0])
            i += 1

    #
