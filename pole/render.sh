echo "Usage: sh render.sh [publish]"
GUIDES=../neo4j-guides

function render {
$GUIDES/run.sh pole_guide.adoc index.html +1 "$@"
}

if [ "$1" == "publish" ]; then
	URL=guides.neo4j.com/sandbox/pole
	render http://$URL -a csv-url=http://guides.neo4j.com/sandbox/pole/data/ -a env-training
	if hash aws 2>/dev/null; then
		aws s3 cp --acl public-read --recursive --exclude "*" --include "*.html" --include "*.png" --include "*.jpg" --include "*.gif" --include "*.csv" s3://${URL}/
		aws s3 cp --acl public-read index.html s3://${URL}
	else
		s3cmd put --recursive -P *.html img s3://${URL}/ # data
		s3cmd put -P index.html s3://${URL}
	fi
	echo "Publication Done"
elif [ "$1" == "render-only" ]; then
  URL=guides.neo4j.com/sandbox/pole
  render http://$URL
else
	URL=localhost:8001/sandbox/pole
	render http://$URL -a csv-url=file:/// -a img=//localhost:8001/img -a env-training
	echo "Starting webserver at $URL Ctrl-C to stop"
	python $GUIDES/http-server.py
fi