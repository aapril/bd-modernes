-- Section 6.4 : hypertable cours et 30 jours de cotations fictives
-- (une cotation par minute pour trois titres, soit 129 603 lignes).
DROP TABLE IF EXISTS cours CASCADE;
CREATE TABLE cours (
    moment   timestamptz   NOT NULL,
    symbole  text          NOT NULL,
    prix     numeric(10,2) NOT NULL,
    volume   integer
) WITH (tsdb.hypertable,
        tsdb.partition_column = 'moment',
        tsdb.chunk_interval   = '1 day',
        tsdb.segmentby        = 'symbole',
        tsdb.orderby          = 'moment DESC');
INSERT INTO cours (moment, symbole, prix, volume)
SELECT t, s,
       round((100 + 10 * sin(extract(epoch FROM t) / 86400)
              + random() * 2)::numeric, 2),
       (random() * 1000)::int
FROM   generate_series(now() - INTERVAL '30 days', now(),
                       INTERVAL '1 minute') AS t,
       unnest(ARRAY['ETS', 'CLUB', 'MTL']) AS s;
SELECT count(*) AS cotations FROM cours;
