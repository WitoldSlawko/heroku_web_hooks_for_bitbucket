#!/bin/bash -ex

function publish_master {
    curl -X POST https://api.heroku.com/apps \
        -H "Accept: application/vnd.heroku+json; version=3" \
        -H "Authorization: Bearer $1" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$2\",\"region\":\"eu\"}"
    git checkout --track -B $2
    git branch --set-upstream
    git config user.name $4
    git config user.email $5

    git add .

    uncache_package_json
    
    git commit -m "merged master update"
    git push https://heroku:$1@git.heroku.com/$2.git $2:master
}

function remove_master {
    curl -X DELETE https://api.heroku.com/apps/$2 \
            -H "Content-Type: application/json" \
            -H "Accept: application/vnd.heroku+json; version=3" \
            -H "Authorization: Bearer $1"
}

function publish_branch {
    curl -X POST https://api.heroku.com/apps \
        -H "Accept: application/vnd.heroku+json; version=3" \
        -H "Authorization: Bearer $1" \
        -H "Content-Type: application/json" \
        -d "{\"name\":\"$3-$6\",\"region\":\"eu\"}"
    git checkout --track -B $6
    git branch --set-upstream
    git config user.name $4
    git config user.email $5

    git add .

    uncache_package_json

    git commit -m "feature branch review update"
    git push https://heroku:$1@git.heroku.com/$3-$6.git $6:master
}

function remove_branch {
    curl -X DELETE https://api.heroku.com/apps/$3-$6 \
            -H "Content-Type: application/json" \
            -H "Accept: application/vnd.heroku+json; version=3" \
            -H "Authorization: Bearer $1"
}

function uncache_package_json {
    if [[ $(ls | grep package-lock.json) == "package-lock.json" ]]
    then
        git rm --cached package-lock.json
    fi
}

if [[ $6 == "master" ]]
then
    {
        remove_master $1 $2 $3 $4 $5 $6 && publish_master $1 $2 $3 $4 $5 $6
    } || {
        publish_master $1 $2 $3 $4 $5 $6
    }
else
    {
        remove_branch $1 $2 $3 $4 $5 $6 && publish_branch $1 $2 $3 $4 $5 $6
    } || {
        publish_branch $1 $2 $3 $4 $5 $6
        echo "https://$3-$6.herokuapp.com/"
    }
fi
