#!/bin/bash

if [ "$#" != "1" ]
then
  echo 'Usage: npm run release [patch|minor|major]'
  exit
fi

git checkout develop

git checkout -b tmp-release

npm run compile

npm version $1

VERSION=`npm view . version`

git commit -am "v$VERSION"

git checkout develop

git merge tmp-release

git branch -d tmp-release

npm publish

npm run clean


