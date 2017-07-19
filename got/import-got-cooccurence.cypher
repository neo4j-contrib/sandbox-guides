CREATE CONSTRAINT ON (c:Character) ASSERT c.name IS UNIQUE;

// We can import the co-occurences for all books first, which will also create all characters:

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mathbeveridge/asoiaf/master/data/asoiaf-all-edges.csv" AS row
MERGE (src:Character {name: row.Source})
MERGE (tgt:Character {name: row.Target})
MERGE (src)-[r:INTERACTS]->(tgt) ON CREATE SET r.weight = toInt(row.weight);

// Then for each of the books we can create a dedicated relationship, suffixed with the number of the book.
LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mathbeveridge/asoiaf/master/data/asoiaf-book1-edges.csv" AS row
MATCH (src:Character {name: row.Source})
MATCH (tgt:Character {name: row.Target})
MERGE (src)-[r:INTERACTS1]->(tgt) ON CREATE SET r.weight = toInt(row.weight), r.book=1;

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mathbeveridge/asoiaf/master/data/asoiaf-book2-edges.csv" AS row
MATCH (src:Character {name: row.Source})
MATCH (tgt:Character {name: row.Target})
// relationship for the book
MERGE (src)-[r:INTERACTS2]->(tgt) ON CREATE SET r.weight = toInt(row.weight), r.book=2;

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mathbeveridge/asoiaf/master/data/asoiaf-book3-edges.csv" AS row
MATCH (src:Character {name: row.Source})
MATCH (tgt:Character {name: row.Target})
// relationship for the book
MERGE (src)-[r:INTERACTS3]->(tgt) ON CREATE SET r.weight = toInt(row.weight), r.book=3;

LOAD CSV WITH HEADERS FROM "https://raw.githubusercontent.com/mathbeveridge/asoiaf/master/data/asoiaf-book45-edges.csv" AS row
MATCH (src:Character {name: row.Source})
MATCH (tgt:Character {name: row.Target})
// relationship for the book
MERGE (src)-[r:INTERACTS45]->(tgt) ON CREATE SET r.weight = toInt(row.weight), r.book=45;
