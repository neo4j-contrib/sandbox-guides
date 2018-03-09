echo "Usage: sh render.sh [publish]"
GUIDES=../neo4j-guides

function render {
$GUIDES/run.sh index.adoc index.html +1 "$@"
$GUIDES/run.sh intro.adoc intro.html +1 "$@"
$GUIDES/run.sh import.adoc import.html +1 "$@"
$GUIDES/run.sh sna.adoc sna.html +1 "$@"
$GUIDES/run.sh contracts.adoc contracts.html +1 "$@"
$GUIDES/run.sh exploratory.adoc exploratory.html +1 "$@"
$GUIDES/run.sh exercises.adoc exercises.html +1 "$@"
$GUIDES/run.sh interestingqueries.adoc interesting.html +1 "$@"
$GUIDES/run.sh littlesis.adoc littlesis.html +1 "$@"
}

if [ "$1" == "publish" ]; then
	URL=guides.neo4j.com/sandbox/trumpworld
	render http://$URL -a csv-url=http://guides.neo4j.com/sandbox/trumpworld/data/ -a env-training
	if hash aws 2>/dev/null; then
		aws s3 cp --acl public-read --recursive --exclude "*" --include "*.html" --include "*.png" --include "*.jpg" --include "*.gif" --include "*.csv" s3://${URL}/
		aws s3 cp --acl public-read index.html s3://${URL}
	else
		s3cmd put --recursive -P *.html img data s3://${URL}/
		s3cmd put -P index.html s3://${URL}
	fi
	echo "Publication Done"
elif [ "$1" == "render-only" ]; then
  URL=guides.neo4j.com/sandbox/trumpworld
  render https://$URL
else
	URL=localhost:8001/sandbox/trumpworld
	render http://$URL -a csv-url=file:/// -a env-training
	echo "Starting webserver at $URL Ctrl-C to stop"
	python $GUIDES/http-server.py
fi
