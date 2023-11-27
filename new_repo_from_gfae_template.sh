#!/bin/bash

repo_name=$1

git clone https://github.com/dchaimow/gfae ${repo_name}

cd ${repo_name}
rm -rf .git
git init
git add .

git commit -m "initializing repo from gfae template" 
