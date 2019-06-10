CREATE CONSTRAINT ON (t:Tournament) ASSERT t.id IS UNIQUE;
CREATE CONSTRAINT ON (p:Person) ASSERT p.id IS UNIQUE;
CREATE CONSTRAINT ON (t:Team) ASSERT t.id IS UNIQUE;
CREATE CONSTRAINT ON (m:Match) ASSERT m.id IS UNIQUE;
CREATE CONSTRAINT ON (s:Squad) ASSERT s.id IS UNIQUE;
CREATE INDEX ON :Tournament(shortName);

CALL apoc.load.json("https://github.com/mneedham/womensworldcup/raw/master/data/tournaments.json")
YIELD value
MERGE (tourn:Tournament {id: value.id})
SET tourn.shortName = value.shortName, tourn.name = value.name, tourn.year = value.year
FOREACH(team in value.teams |
  MERGE (t:Team {id: team.id}) SET t.name = team.team
  MERGE (t)-[:PARTICIPATED_IN]->(tourn));

CALL apoc.load.json("https://github.com/mneedham/womensworldcup/raw/master/data/squads.json")
YIELD value
MATCH (team:Team {id: value.teamId})
MATCH (tourn:Tournament {shortName: value.shortName})
MERGE (squad:Squad {id: team.name + " in " + tourn.year})
MERGE (team)-[:NAMED]->(squad)
MERGE (squad)-[:FOR]->(tourn)
WITH *
UNWIND value.players AS player
MERGE (p:Person {id: player.id})
ON CREATE SET p.name = player.name, p.dob = CASE WHEN player.dob = "" THEN null ELSE date(player.dob) END
WITH *
CALL apoc.do.when(player.role = "0", 'MERGE (p)-[:COACH_FOR]->(squad)', 'MERGE (p)-[:IN_SQUAD]->(squad)', {p:p, squad:squad}) YIELD value AS ignore
RETURN count(*);

CALL apoc.load.json("https://github.com/mneedham/womensworldcup/raw/master/data/matches.json")
YIELD value
MATCH (tourn:Tournament {id: value.IdSeason})
MATCH (home:Team {id: value.HomeTeam.IdTeam})
MATCH (away:Team {id: value.AwayTeam.IdTeam})
MERGE (match:Match {id:value.IdMatch})
SET match.stage = value.StageName[0].Description,
    match.date = date(apoc.date.format(datetime(value.Date).epochMillis, "ms", "yyyy-MM-dd"))
MERGE (match)-[:IN_TOURNAMENT]->(tourn)
MERGE (home)-[homePlayed:PLAYED_IN]->(match)
SET homePlayed.score = value.HomeTeam.Score, homePlayed.penaltyScore = value.HomeTeamPenaltyScore
MERGE (away)-[awayPlayed:PLAYED_IN]->(match)
SET awayPlayed.score = value.AwayTeam.Score, awayPlayed.penaltyScore = value.AwayTeamPenaltyScore

FOREACH (goal IN [v in value.HomeTeam.Goals WHERE not v.IdPlayer  is null] |
  MERGE (p:Person {id: goal.IdPlayer})
  MERGE (p)-[:SCORED_GOAL {minute: goal.Minute}]->(match)
)

FOREACH (goal IN [v in value.AwayTeam.Goals WHERE not v.IdPlayer  is null] |
  MERGE (p:Person {id: goal.IdPlayer})
  MERGE (p)-[:SCORED_GOAL {minute: goal.Minute}]->(match)
)

FOREACH (player IN [v in value.HomeTeam.Players WHERE v.Status = 1] |
  MERGE (p:Person {id: player.IdPlayer})
  MERGE (p)-[playedIn:PLAYED_IN]->(match)
  SET playedIn.type = "Started"
)

FOREACH (player IN [v in value.AwayTeam.Players WHERE v.Status = 1] |
  MERGE (p:Person {id: player.IdPlayer})
  MERGE (p)-[playedIn:PLAYED_IN]->(match)
  SET playedIn.type = "Started"
)

FOREACH (sub IN [v in value.HomeTeam.Substitutions WHERE not v.IdPlayerOn is null] |
  MERGE (p:Person {id: sub.IdPlayerOn})
  MERGE (p)-[playedIn:PLAYED_IN]->(match)
  SET playedIn.minuteOn = sub.Minute, playedIn.type = "Subbed On"
)

FOREACH (sub IN [v in value.AwayTeam.Substitutions WHERE not v.IdPlayerOn is null] |
  MERGE (p:Person {id: sub.IdPlayerOn})
  MERGE (p)-[playedIn:PLAYED_IN]->(match)
  SET playedIn.minuteOn = sub.Minute, playedIn.type = "Subbed On"
);

MATCH (p:Person)-[:IN_SQUAD]-()<-[:NAMED]-(team:Team)
MERGE (p)-[:REPRESENTS]->(team);
