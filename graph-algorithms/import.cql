CREATE CONSTRAINT ON (c:Character)
ASSERT c.id IS UNIQUE;

UNWIND range(1,7) AS season
LOAD CSV WITH HEADERS FROM "https://github.com/mneedham/gameofthrones/raw/master/data/got-s" + season + "-nodes.csv" AS row
MERGE (c:Character {id: row.Id})
ON CREATE SET c.name = row.Label;

UNWIND range(1,7) AS season
LOAD CSV WITH HEADERS FROM "https://github.com/mneedham/gameofthrones/raw/master/data/got-s" + season + "-edges.csv" AS row
MATCH (source:Character {id: row.Source})
MATCH (target:Character {id: row.Target})
CALL apoc.merge.relationship(source, "INTERACTS_SEASON" + season, {}, {}, target) YIELD rel
SET rel.weight = toInteger(row.Weight), rel.season = season;
