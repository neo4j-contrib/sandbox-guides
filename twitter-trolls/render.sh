echo "Usage: sh render.sh [publish]"
GUIDES=../neo4j-guides

function render {
$GUIDES/run.sh index.adoc index.html +1 "$@"
$GUIDES/run.sh exercise_index.adoc exercise.html +1 "$@"
$GUIDES/run.sh introguide.adoc intro.html +1 "$@"
$GUIDES/run.sh questions.adoc questions.html +1 "$@"
$GUIDES/run.sh project_ideas.adoc project_ideas.html +1 "$@"
$GUIDES/run.sh graph_algorithms.adoc graph_algorithms.html +1 "$@"
$GUIDES/run.sh tableauviz.adoc tabular_viz.html +1 "$@"
}

if [ "$1" == "publish" ]; then
	URL=guides.neo4j.com/sandbox/twitter-trolls
	render https://$URL -a csv-url=http://guides.neo4j.com/sandbox/twitter-trolls/data/ -a env-training
	s3cmd put --cf-invalidate --recursive -P *.html img s3://${URL}/
	s3cmd put --cf-invalidate -P index.html s3://${URL}
	echo "Publication Done"
elif [ "$1" == "render-only" ]; then
  URL=guides.neo4j.com/sandbox/twitter-trolls
  render https://$URL
else
	URL=localhost:8001/sandbox/twitter-trolls
	render http://$URL -a csv-url=file:/// -a img=//localhost:8001/img -a env-training
	echo "Starting webserver at $URL Ctrl-C to stop"
	python $GUIDES/http-server.py
fi
