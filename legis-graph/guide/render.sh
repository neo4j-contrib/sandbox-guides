echo "Usage: sh render.sh [publish]"
GUIDES=../../neo4j-guides

function render {
$GUIDES/run.sh index.adoc index.html +1 "$@"
$GUIDES/run.sh exercises.adoc exercises.html +1 "$@"
$GUIDES/run.sh fecimport.adoc fecimport.html +1 "$@"
$GUIDES/run.sh legis-graph-fec.adoc legisgraphfec.html +1 "$@"
$GUIDES/run.sh legis-graph-import.adoc legisgraphimport.html +1 "$@"
$GUIDES/run.sh legis-graph.adoc legisgraph.html +1 "$@"
$GUIDES/run.sh graphalgorithms.adoc graphalgorithms.html +1 "$@"
$GUIDES/run.sh legis-graph-export-dq.adoc export.html +1 "$@"
$GUIDES/run.sh data-load-overview.adoc dataloadoverview.html +1 "$@"
$GUIDES/run.sh fec-import-exerise-answers.adoc fecimportanswers.html +1 "$@"

}

if [ "$1" == "publish" ]; then
  URL=guides.neo4j.com/sandbox/legis-graph
  render http://$URL -a csv-url=http://guides.neo4j.com/legis-graph/data/ -a env-training
  if hash aws 2>/dev/null; then
	  aws s3 cp --acl public-read --recursive --exclude "*" --include "*.html" --include "*.png" --include "*.jpg" --include "*.gif" --include "*.csv" s3://${URL}/
	  aws s3 cp --acl public-read index.html s3://${URL}
  else
  	s3cmd put --recursive -P *.html img data s3://${URL}/
  	s3cmd put -P index.html s3://${URL}
  fi
  echo "Publication Done"
else
  URL=localhost:8001/sandbox/legis-graph
  render http://$URL -a csv-url=file:/// -a env-training
  echo "Starting Websever at $URL Ctrl-c to stop"
  python $GUIDES/http-server.py
fi
