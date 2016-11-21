# Neo4j browser guides for sandbox instances

## Available Use Cases

* us-elections-2016

## Render / deploy guides for a use case

1. Clone this repo `git clone git@github.com:neo4j-contrib/sandbox-guides.git`
1. `cd sandbox-guides`
1. `git submodule init`
1. `git submodule updaet`
1. Edit `{USE-CASE}/{GUIDE-NAME-HERE}.adoc`
1. `{USE-CASE}/render.sh [publish]`

1. Open Neo4j Browser and run `:play http://localhost:8001/{USE-CASE}`