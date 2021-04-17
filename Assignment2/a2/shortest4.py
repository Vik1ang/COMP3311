import sys
import sqlite3
import time
from queue import Queue


def recursive(_final_result, _graph, _node, _line, _graph_node=None):
    if _node not in _graph:
        _final_result.append(_line)
        return
    a = _graph[_node]
    for _a1 in a:
        recursive(_final_result, _graph, _a1[2], _line + _a1[0] + ' was in ' + _a1[2] + ' with ' + _a1[1] + '; ')


if __name__ == '__main__':
    if len(sys.argv) < 2:
        sys.exit(1)

    sys.argv[1] = sys.argv[1].title()
    sys.argv[2] = sys.argv[2].title()

    con = sqlite3.connect('a2.db')

    cur = con.cursor()

    # sql_shortest_and = '''
    # select distinct (select group_concat(a2.name)
    #              from acting a1
    #                       left join actor a2 on a1.actor_id = a2.id
    #              where a.movie_id = a1.movie_id) as actor_table,
    #                 m.title || ' (' || m.year || ')'
    # from acting a
    #      left join movie m on a.movie_id = m.id
    # where actor_table like {}
    #     and actor_table like {}
    # group by movie_id, actor_id;
    # '''.format('\'%' + sys.argv[1] + '%\'', '\'%' + sys.argv[2] + '%\'')
    #
    # output = []
    #
    # cur.execute(sql_shortest_and)
    #
    # i = 1
    # while True:
    #     t = cur.fetchone()
    #     if t is None:
    #         break
    #     temp = str(i) + '. ' + sys.argv[1] + ' was in ' + t[1] + ' with ' + sys.argv[2]
    #     output.append(temp)
    #     i += 1
    #
    # print(*output, sep='\n')

    start = time.time()
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
    actors_relation = {}
    cur.execute(sql_1)
    actors_table = cur.fetchall()

    for _line in actors_table:
        temp_actor_list = _line[1].split(',')
        if _line[0] not in actors_relation:
            actors_relation[_line[0]] = set()
        for _i in temp_actor_list:
            if _line[0] == _i:
                continue
            actors_relation[_line[0]].add(_i)

    end = time.time()
    output = []
    degree = 0
    for _d1 in actors_relation[sys.argv[1]]:
        if _d1 == sys.argv[2]:
            temp_list = [sys.argv[1], _d1]
            output.append(temp_list)
            break
        for _d2 in actors_relation[_d1]:
            if _d2 == sys.argv[2]:
                temp_list = [sys.argv[1], _d1, _d2]
                output.append(temp_list)
                break
            for _d3 in actors_relation[_d2]:
                if _d3 == sys.argv[2]:
                    temp_list = [sys.argv[1], _d1, _d2, _d3]
                    output.append(temp_list)
                    break
                for _d4 in actors_relation[_d3]:
                    if _d4 == sys.argv[2]:
                        temp_list = [sys.argv[1], _d1, _d2, _d3, _d4]
                        output.append(temp_list)
                        break
                    for _d5 in actors_relation[_d4]:
                        if _d5 == sys.argv[2]:
                            temp_list = [sys.argv[1], _d1, _d2, _d3, _d4, _d5]
                            output.append(temp_list)
                            break
                        for _d6 in actors_relation[_d5]:
                            if _d6 == sys.argv[2]:
                                temp_list = [sys.argv[1], _d1, _d2, _d3, _d4, _d5, _d6]
                                output.append(temp_list)
                                break

    min_len = 7
    for _o1 in output:
        if len(_o1) < min_len:
            min_len = len(_o1)

    del_output = output.copy()

    for _o2 in del_output:
        if len(_o2) > min_len:
            output.remove(_o2)

    sql_1 = '''
        select a.name,
       (select group_concat(m.title || ' (' || m.year || ')')
        from movie m1
                 left join acting a3 on m1.id = a3.movie_id
        where a3.actor_id = a2.actor_id)
from actor a
         left join acting a2 on a.id = a2.actor_id
         left join movie m on a2.movie_id = m.id
group by a.name;
        '''
    cur.execute(sql_1)
    movies_table = cur.fetchall()
    movie_relation = {}
    for _line in movies_table:
        temp_movie_list = []
        try:
            temp_movie_list = _line[1].split(',')
        except:
            pass
        if _line[0] not in movie_relation:
            movie_relation[_line[0]] = set()
        for _i in temp_movie_list:
            movie_relation[_line[0]].add(_i)

    final_output = []
    for _f1 in output:
        _index_0 = 0
        _index_1 = 1
        temp_output = []
        while True:
            if _index_1 >= min_len:
                break
            interact_set = movie_relation[_f1[_index_0]] & movie_relation[_f1[_index_1]]
            temp_output_sub = []
            for _s1 in interact_set:
                temp_output_sub.append((_f1[_index_0], _f1[_index_1], _s1))
            temp_output.append(temp_output_sub)
            _index_0 += 1
            _index_1 += 1
        final_output.append(temp_output)

    final_output.sort(key=lambda x: x[0][0][2])
    final_result = []
    for _fo1 in final_output:
        graph = {}
        graph['head'] = []
        prev_key = 'head'
        graph_queue = Queue()
        graph_queue.put(prev_key)
        _index1 = 0
        for _index1 in range(len(_fo1)):
            queue_size = graph_queue.qsize()
            for _q1 in range(queue_size):
                graph_key = graph_queue.get()
                for _t1 in _fo1[_index1]:
                    if graph_key not in graph:
                        graph[graph_key] = []
                    graph[graph_key].append(_t1)
                    graph_queue.put(_t1[2])

        recursive(final_result, graph, 'head', '')

    final_result = set(final_result)
    final_result = list(final_result)
    i = 1
    final_result.sort()
    final_final = []
    for _fs in final_result:
        _fs = _fs.rstrip()
        line_f = '{}. '.format(i) + _fs[:-1]
        final_final.append(line_f)
        i += 1

    print(*final_final, sep='\n')
