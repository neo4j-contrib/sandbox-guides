echo "Usage: sh render.sh [publish]"
GUIDES=../neo4j-guides

function render {
$GUIDES/run.sh index.adoc index.html +1 "$@"
}

if [ "$1" == "publish" ]; then
	URL=guides.neo4j.com/sandbox/twitter-trolls
	render http://$URL -a csv-url=http://guides.neo4j.com/sandbox/twitter-trolls/data/ -a env-training
	s3cmd put --cf-invalidate --recursive -P *.html img s3://${URL}/
	s3cmd put --cf-invalidate -P index.html s3://${URL}
	echo "Publication Done"
else
	URL=localhost:8001/sandbox/twitter-trolls
	render http://$URL -a csv-url=file:/// -a img=//localhost:8001/img -a env-training
	echo "Starting webserver at $URL Ctrl-C to stop"
	python $GUIDES/http-server.py
fi