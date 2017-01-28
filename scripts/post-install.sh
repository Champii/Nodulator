#!/bin/bash

echo "POST"
cd ./src/Modules/Nodulator-Account && npm install; cd -
cd ./src/Modules/Nodulator-Angular && npm install; cd -
cd ./src/Modules/Nodulator-Assets && npm install; cd -
cd ./src/Modules/Nodulator-Socket && npm install; cd -
cd ./src/Modules/Nodulator-View && npm install; cd -