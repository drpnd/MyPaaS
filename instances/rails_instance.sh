#!/bin/sh

RAILS_ENV=$1
DATABASE_PASSWORD=$2
SECRET_TOKEN=$3

## The following variable may be moved to arguments of this script.
REPOS_APPNAME=$4
DATABASE_URL=$5

export RAILS_ENV
export DATABASE_PASSWORD
export SECRET_TOKEN
export REPOS_APPNAME
export DATABASE_URL

## Kill the running instance
kill `cat rails_instance.pid`

cd $REPOS_APPNAME

## Run the rails server
bundle exec rails server --bind=0.0.0.0 &

## Save the PID if rails server and watch this shell process until the rails server goes down
PID=$!
cd ..
echo $PID > rails_instance.pid

RET=0
while [ $RET -eq 0 ];
do
	kill -0 $PID
	RET=$?
	sleep 1
done
