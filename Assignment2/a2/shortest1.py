import sys
import sqlite3
import networkx as nx
from matplotlib import pyplot as plt

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
        actor_set = set()
        sql_1 = '''
        select distinct (select group_concat(a2.name)
                 from acting a1
                          left join actor a2 on a1.actor_id = a2.id
                 where a.movie_id = a1.movie_id) as actor_table,
                m.title || ' (' || m.year || ')'
        from acting a
            left join movie m on a.movie_id = m.id
        where actor_table like {}
        group by movie_id, actor_id;
        '''.format('\'%' + sys.argv[1] + '%\'')
        degree = 0
        cur.execute(sql_1)
        movie_actors_1 = cur.fetchall()
        for _i in range(len(movie_actors_1)):
            actors_list = movie_actors_1[_i][0].split(',')
            for _actor in actors_list:
                if _actor == sys.argv[1] or _actor in actor_set:
                    continue
                g.add_edges_from([(sys.argv[1], _actor)])
                sql_1 = '''
                        select distinct (select group_concat(a2.name)
                                         from acting a1
                                                  left join actor a2 on a1.actor_id = a2.id
                                         where a.movie_id = a1.movie_id) as actor_table,
                                        m.title || ' (' || m.year || ')'
                                from acting a
                                    left join movie m on a.movie_id = m.id
                                where actor_table like {}
                                group by movie_id, actor_id;
                                '''.format('\'%' + _actor + '%\'')
                cur.execute(sql_1)
                movie_actors_helper = cur.fetchall()
                for _j in range(len(movie_actors_helper)):
                    actors_list_helper = movie_actors_helper[_j][0].split(',')
                    for _actor_helper in actors_list_helper:
                        if _actor_helper == _actor:
                            continue
                        g.add_edges_from([(_actor, _actor_helper)])
                        sql_1 = '''
                                        select distinct (select group_concat(a2.name)
                                                 from acting a1
                                                          left join actor a2 on a1.actor_id = a2.id
                                                 where a.movie_id = a1.movie_id) as actor_table,
                                                m.title || ' (' || m.year || ')'
                                        from acting a
                                            left join movie m on a.movie_id = m.id
                                        where actor_table like {}
                                        group by movie_id, actor_id;
                                        '''.format('\'%' + _actor_helper + '%\'')
                        cur.execute(sql_1)
                        degree_actors = cur.fetchall()
                        for d in range(degree):
                            pass

        # nx.draw_networkx(g)
        # plt.show()
        # g.add_edges_from([(sys.argv[1], split_actor[_])])
        print('*', g.edges)
        nx.draw_networkx(g)
        plt.show()
        print(1)
        print(nx.has_path(g, source=sys.argv[1], target=sys.argv[2]))
        path = nx.all_shortest_paths(g, source=sys.argv[1], target=sys.argv[2])
        shortest_paths = list(path)
        print(shortest_paths)

        for _ in range(len(shortest_paths)):
            sql_2 = '''
                            select distinct (select group_concat(a2.name)
                             from acting a1
                                      left join actor a2 on a1.actor_id = a2.id
                             where a.movie_id = a1.movie_id) as actor_table,
                            m.title || ' (' || m.year || ')'
            from acting a
                     left join movie m on a.movie_id = m.id
            where actor_table like {} and actor_table like {}
            group by movie_id, actor_id;'''.format('\'%' + sys.argv[1] + '%\'', '\'%' + shortest_paths[_][1] + '%\'')
            cur.execute(sql_2)
            movie_1 = cur.fetchall()
            # print(movie_1)
            for j in range(len(movie_1)):
                sql_3 = '''
                select distinct (select group_concat(a2.name)
                             from acting a1
                                      left join actor a2 on a1.actor_id = a2.id
                             where a.movie_id = a1.movie_id) as actor_table,
                            m.title || ' (' || m.year || ')'
            from acting a
                     left join movie m on a.movie_id = m.id
            where actor_table like {} and actor_table like {}
            group by movie_id, actor_id;'''.format('\'%' + sys.argv[2] + '%\'', '\'%' + shortest_paths[_][1] + '%\'')

                cur.execute(sql_3)
                movie_2 = cur.fetchall()
                for k in range(len(movie_2)):
                    line = '{} was in {} with {}; {} was in {} with {}'.format(sys.argv[1], movie_1[j][1],
                                                                               shortest_paths[_][1],
                                                                               shortest_paths[_][1],
                                                                               movie_2[k][1],
                                                                               sys.argv[2])
                    temp_tuple = (line, movie_1[j][1])
                    output.append(temp_tuple)

            # temp = cur.fetchall()
            # print(temp)

        # print(path)
        # print(output)
        output.sort(key=lambda x: x[1])
        i = 1
        for _ in range(len(output)):
            print('{}.'.format(i), output[_][0])
            i += 1

    #
