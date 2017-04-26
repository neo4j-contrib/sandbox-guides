// CREATE SCHEMA CONSTRAINT
CREATE CONSTRAINT ON (p:Person) ASSERT p.name IS UNIQUE;
CREATE CONSTRAINT ON (o:Organization) ASSERT o.name IS UNIQUE;


//org-org
WITH 'https://docs.google.com/spreadsheets/d/1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss/export?format=csv&id=1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss&gid=1996904412' AS url
LOAD CSV WITH HEADERS FROM url AS row
WITH apoc.text.regreplace(toUpper(row.Connection),'\\W+','_') AS type, row
WITH row,type WHERE row.`Entity A Type` = 'Organization' AND row.`Entity B Type` = 'Organization'
  WITH ['LOAN','LOBBIED','SALE','SUPPLIER','SHAREHOLDER','LICENSES','AFFILIATED','TIES','NEGOTIATION','INVOLVED','PARTNER'] AS terms, type, row
  WITH coalesce(head(filter(term IN terms WHERE type CONTAINS term)), type) AS type, row
  MERGE (o1:Organization {name:row.`Entity A`})
  MERGE (o2:Organization {name:row.`Entity B`})
  WITH o1,o2,type,row
  CALL apoc.create.relationship(o1,type, {source:row.`Source(s)`, connection:row.Connection},o2) YIELD rel
  RETURN COUNT(*);

// org-person
WITH 'https://docs.google.com/spreadsheets/d/1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss/export?format=csv&id=1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss&gid=1996904412' AS url
LOAD CSV WITH HEADERS FROM url AS row
WITH apoc.text.regreplace(toUpper(row.Connection),'\\W+','_') AS type, row
WITH row,type WHERE row.`Entity A Type` = "Person" AND row.`Entity B Type` = "Organization"

  WITH ['BOARD','DIRECTOR','INCOME','PRESIDENT','CHAIR','CEO','PARTNER','OWNER','INVESTOR','FOUNDER','STAFF','DEVELOPER','EXECUTIVE_COMITTEE','EXECUTIVE','FELLOW','BANKER','COUNSEL','ADVISOR','SHAREHOLDER','LIASON','SPEECH','CONNECTED','HIRED','CONSULTED','INVOLVED','APPOINTEE','MANAGER','TRUSTEE','AMBASSADOR','PUBLISHER','LAWYER'] AS terms, type, row
  WITH coalesce(head(filter(term IN terms WHERE type CONTAINS term)), 'INVOLVED_WITH') AS type, row
  MERGE (o:Organization {name:row.`Entity B`})
  MERGE (p:Person {name:row.`Entity A`})
  WITH o,p,type,row
  CALL apoc.create.relationship(p,type, {source:row.`Source(s)`, connection:row.Connection},o) YIELD rel
RETURN COUNT(*);

// person-person
WITH 'https://docs.google.com/spreadsheets/d/1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss/export?format=csv&id=1Z5Vo5pbvxKJ5XpfALZXvCzW26Cl4we3OaN73K9Ae5Ss&gid=1996904412' AS url
LOAD CSV WITH HEADERS FROM url AS row
WITH apoc.text.regreplace(toUpper(row.Connection),'\\W+','_') AS type, row
WITH row,type WHERE row.`Entity A Type` = "Person" AND row.`Entity B Type` = "Person"

  WITH ['WHITE_HOUSE','REPRESENTATIVE','FRIEND','DIRECTOR','ADVISOR','WORKED','MET','LUNCHED','NOMINEE','COUNSELOR','AIDED','CAMPAIGN','PARTNER','MARRIED','CLOSE','APPEARANCE','BOUGHT','SAT_IN','CONSULTED','CO_CHAIR','GAVE'] AS terms, type, row
  WITH coalesce(head(filter(term IN terms WHERE type CONTAINS term)), 'INVOLVED_WITH') AS type, row
  MERGE (p1:Person {name:row.`Entity A`})
  MERGE (p2:Person {name:row.`Entity B`})
  WITH p1,p2,type,row
  CALL apoc.create.relationship(p2,type, {source:row.`Source(s)`, connection:row.Connection},p1) YIELD rel
  RETURN COUNT(*);

// Set Bank label
MATCH (o:Organization)
WHERE o.name CONTAINS "BANK" SET o:Bank;

// Set Hotel label
MATCH (o:Organization)
WHERE o.name CONTAINS "HOTEL" SET o:Hotel;

// Set Trump label
MATCH (o:Organization)
WHERE any(term in ["TRUMP","DT","DJT"] WHERE o.name CONTAINS (term + " "))
SET o:Trump;
