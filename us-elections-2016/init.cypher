create index on :Area(fips);
create index on :Candidate(npid);
create index on :State(state);


// go over all states
call apoc.periodic.iterate('
UNWIND ["AL","AK","AZ","AR","CA","CO","CT","DE","DC" , "FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY"] as state RETURN state', '

with "http://origin-east-elections.politico.com/mapdata/2016/elections-ftp-download/"+state+".txt" as url
load csv from url as row fieldterminator ";"
// separate the header
with row, row[0..19] as header
// name the header fields
with row,header[1] as date, header[2] as state, header[3] as county_no, header[4] as fips, header[5] as area_name, header[6] as race_no, header[7] as office, header[8] as race_type,
header[9] as seat_no, header[10] as office_name, header[11] as seat_name, header[12] as race_type_party, header[13] as race_type_name, 
header[14] as office_description, header[15] as number_of_winners, header[16] as number_in_runoff, toInt(header[17]) as reported_precincts, toInt(header[18]) as total_precincts


// get-or-create an :Election node for the office, and date
MERGE (e:Election {date:date, office:office,race:race_type}) ON CREATE SET e.name=office_name, e.raceName = race_type_name
// get-or-create an :Area node (State or County) by state and fips, set additional properties
MERGE (a:Area {state:state,fips:fips}) ON CREATE SET a.name = area_name,  a.county_no = county_no 
// always update reporting numbers, also calculate percentage of reported precincts
SET a.reporting = case when total_precincts = 0 then 100.0 else 100.0*reported_precincts/total_precincts end, 
    a.reported_precincts = reported_precincts, a.total_precincts = total_precincts
with *
// dynamically add a label for the state
call apoc.create.addLabels(a,case when fips="00000" then ["State"] else [] end) yield node
// find the state if any
OPTIONAL MATCH (st:State {state:state})
// if we found a state and the current area is not the state, connect them with :IS_IN
FOREACH (_ in case when fips <> "00000" and not st is null then [1] else [] end | 
   MERGE (a)-[:IS_IN]->(st)
)
// compute the number of remaining blocks
with *, (length(row)-19)/12 as seats
// for each of those blocks
unwind range(0,seats-1) as seat_idx
// get a slice of the row-data
with *, row[(19+seat_idx*12)..(19+(seat_idx+1)*12)] as seat 
// name fields
with *,seat[0] as ap_cand_no, seat[1] as cand_order, seat[2] as party, 
     seat[3] + " "+ seat[5] as name, 
     seat[8] as incumbent, toInt(seat[9]) as votes, 
     case seat[11] when "0" then state+seat[0] else seat[11] end as npid,
     case seat[10] when "X" then true when " " then false when "R" then null end as winner
// get-or-create :Candidate node based on global npid
MERGE (c:Candidate {npid:npid}) ON CREATE SET c.name = name, c.incumbent = incumbent, c.party = party, c.seat_no = seat_no
// connect candidate with election
MERGE (c)-[:RUNS_IN]->(e)
// create a :Vote within the area for that candidate
MERGE (a)-[:REPORTS]->(v:Vote {npid:npid})
// always update the votes and winner info
SET v.votes = votes, v.winner = winner, v.reported = votes * a.reporting / 100.0
// connect the vote to the candidate
MERGE (v)-[:FOR]->(c);', {batchSize:1});



// Add state borders
WITH "https://raw.githubusercontent.com/ubikuity/List-of-neighboring-states-for-each-US-state/master/neighbors-states.csv" as url
LOAD CSV WITH HEADERS FROM url AS row
MATCH (from:State {state:row.StateCode}), 
      (to:State {state:row.NeighborStateCode})
MERGE (from)-[:BORDERS]-(to)
RETURN from,to;


// Add electoral college votes
// Data from https://en.wikipedia.org/wiki/Electoral_College_(United_States)
// Add state votes 
WITH {AL:9, AK:3, AZ:11, AR:6, CA:55, CO:9, CT:7, DE:3, DC:3, FL:29, GA:16, HI:4, ID:4, IL:20, IN:11, IA:6, KS:6, KY:8, LA:8, ME:4, MD:10, MA:11, MI:16, MN:10, MS:6, MO:10, MT:3, NE:5, NV:6, NH:4, NJ:14, NM:5, NY:29, NC:15, ND:3, OH:18, OK:7, OR:7, PA:20, RI:4, SC:9, SD:3, TN:11, TX:38, UT:6, VT:3, VA:13, WA:12, WV:5, WI:10, WY:3} 
AS college
UNWIND keys(college) as state
MATCH (s:State {state:state})
SET s.votes = college[state];


// add eligible voter / population for each state
// source: http://www.electproject.org/2016g
LOAD CSV WITH HEADERS FROM "https://dl.dropboxusercontent.com/u/67572426/data/populations.csv" AS row
MATCH (s:State {name: row.State})
SET s.voters = row.`Voting-Eligible Population (VEP)`,
        s.population = row.`Voting-Age Population (VAP)`;

