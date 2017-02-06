// Legis-graph LOAD CSV cypher script
// https://github.com/legis-graph/legis-graph

// Load Legislators


CREATE CONSTRAINT ON (l:Legislator) ASSERT l.bioguideID IS UNIQUE;
CREATE CONSTRAINT ON (s:State) ASSERT s.code IS UNIQUE;
CREATE CONSTRAINT ON (p:Party) ASSERT p.name IS UNIQUE;
CREATE CONSTRAINT ON (b:Body) ASSERT b.type IS UNIQUE;
CREATE CONSTRAINT ON (b:Bill) ASSERT b.billID IS UNIQUE;
CREATE CONSTRAINT ON (s:Subject) ASSERT s.title IS UNIQUE;
CREATE CONSTRAINT ON (c:Committee) ASSERT c.thomasID IS UNIQUE;



LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/legislators-current.csv' AS line
MERGE (legislator:Legislator {bioguideID: line.bioguideID})
    ON CREATE SET legislator = line
MERGE (s:State {code: line.state})
MERGE (legislator)-[:REPRESENTS]->(s)
MERGE (p:Party {name: line.currentParty})
MERGE (legislator)-[:IS_MEMBER_OF]->(p)
MERGE (b:Body {type: line.type})
MERGE (legislator)-[:ELECTED_TO]->(b);

CREATE INDEX ON :Legislator(thomasID);

// Load Congresses

LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/congresses.csv' AS line
MERGE (congress:Congress { number: line.number });


// Load Bills

USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/bills.csv'
AS line
MATCH (c:Congress)
CREATE (bill:Bill { billID: line.billID })
    SET bill = line
// FIXME: ASSUMES ONLY 1 CONGRESS IS LOADED!!!
CREATE (bill)-[:PROPOSED_DURING]->(c);

// Load subjects 

LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/subjects.csv' AS line
MERGE (subject:Subject { title: line.title });

// Load Bills Legislators

// Load current sponsorships
USING PERIODIC COMMIT 50000
LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/sponsors.csv'
AS line
MATCH (bill:Bill { billID: line.billID }),
      (legislator:Legislator { bioguideID: line.bioguideID })
CREATE (bill)-[r:SPONSORED_BY]->(legislator)
    SET r.cosponsor = CASE WHEN line.cosponsor = "1" THEN True ELSE False END;

// Load Votes

USING PERIODIC COMMIT 50000
LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/votes.csv'
AS line
MATCH (bill:Bill { billID: line.billID }),
      (legislator:Legislator { bioguideID: line.bioguideID })
CREATE (bill)<-[r:VOTED_ON]-(legislator)
    SET r.vote = line.vote;

// Load Committees

LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/committees-current.csv' AS line
MERGE (c:Committee {thomasID: line.thomasID})
  ON CREATE SET c = line;

LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/bill_committees.csv' AS line
MATCH (b:Bill {billID: line.billID})
MATCH (c:Committee {thomasID: line.committeeID})
CREATE (b)-[:REFERRED_TO]->(c);

// Load Committee Members

LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/committee-members.csv' AS line
MATCH (c:Committee {thomasID: line.committeeID})
MATCH (l:Legislator {bioguideID: line.legislatorID})
MERGE (l)-[r:SERVES_ON]->(c)
SET r.rank = toInt(line.rank);

// Load bill subjects
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS
FROM 'http://guides.neo4j.com/sandbox/legis-graph/data/bill_subjects.csv'
AS line
MATCH (bill:Bill { billID: line.billID })
MATCH (subject:Subject { title: line.title })
WITH bill, subject
CREATE (bill)-[r:DEALS_WITH]->(subject)
RETURN COUNT(*);

CREATE INDEX ON :Legislator(govtrackID);
CREATE INDEX ON :Legislator(opensecretsID);
CREATE INDEX ON :Legislator(votesmartID);
CREATE INDEX ON :Legislator(cspanID);
CREATE INDEX ON :Legislator(wikipediaID);
CREATE INDEX ON :Legislator(washpostID);
CREATE INDEX ON :Legislator(icpsrID);
CREATE INDEX ON :Legislator(lisID);
