//add the speakers and companies
load csv with headers from
"https://docs.google.com/a/neotechnology.com/spreadsheets/d/1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps/export?format=csv&id=1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps&gid=1504480307" as csv
merge (p:Person {name: csv.name, title: csv.title, bio: csv.bio})
merge (c:Company {name: csv.company})
with csv
match (p:Person {name: csv.name, title: csv.title, bio: csv.bio}), (c:Company {name: csv.company})
merge (p)-[:WORKS_FOR]->(c);

//add the rooms, tracks, floors
load csv with headers from "https://docs.google.com/a/neotechnology.com/spreadsheets/d/1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps/export?format=csv&id=1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps&gid=284108" as csv
merge (f:Floor {name: csv.floor})
merge (r:Room {name: csv.room})-[:LOCATED_ON]->(f)
merge (t:Track {name: csv.track});


//add the timeslots to each day
load csv with headers from "https://docs.google.com/a/neotechnology.com/spreadsheets/d/1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps/export?format=csv&id=1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps&gid=284108" as csv
merge (t1:Time {time: toInt(csv.start)})
merge (t2:Time {time: toInt(csv.end)});

//Connecting the timeslots
match (t:Time)
with t
order by t.time ASC
with collect(t) as times
  foreach (i in range(0,length(times)-2) |
    foreach (t1 in [times[i]] |
      foreach (t2 in [times[i+1]] |
        merge (t1)-[:FOLLOWED_BY]->(t2))));

//add the sessions and connect them up
load csv with headers from "https://docs.google.com/a/neotechnology.com/spreadsheets/d/1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps/export?format=csv&id=1Hu4l5cfnn6efsAvjNq0DmUyW1K5EiyDd7jpo3Ei3Mps&gid=284108" as csv
match (t2:Time {time: toInt(csv.end)}),
(t1:Time {time: toInt(csv.start)}),
(r:Room {name: csv.room}),
(t:Track {name: csv.track}),
(p:Person {name: csv.speaker})
merge (s:Session {title: csv.title})
set s.abstract = csv.abstract
set s.tags = csv.tags
merge (s)<-[:SPEAKS_IN]-(p)
merge (s)-[:IN_ROOM]->(r)
merge (s)-[:STARTS_AT]->(t1)
merge (s)-[:ENDS_AT]->(t2)
merge (s)-[:IN_TRACK]->(t);

//extract the tags
match (s:Session)
with s, [t in split(s.tags,",") | trim(t)] as tags
unwind tags as tag
merge (t:Tag {name: tag})
merge (s)-[:TAGGED_AS]->(t)
remove s.tags;

