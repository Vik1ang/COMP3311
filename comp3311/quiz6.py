import psycopg2

if __name__ == '__main__':
    conn = psycopg2.connect(dbname="cs3311", options="-c search_path=r")
    print(conn)

    db = conn.cursor()
    db.execute("select * from r")
    s = 0
    for t in db.fetchall():
        a, b, c = t
        s = s + a * b
    print(s)
