#!/bin/sh

[ "$1" = "UPDATE" ] && UPDATE="true"

set -e

function bumpChartVersion() {
  v=$(grep '^version:' ./drpsychick/$1/Chart.yaml | awk -F: '{print $2}' | tr -d ' ')
  patch=${v/*.*./}
  nv=${v/%$patch/}$((patch+1))
  sed -i "" -e "s/^version: .*/version: $nv/" ./drpsychick/$1/Chart.yaml
}

# checkout github-pages
echo "--> Checkout gh-pages and rebase master"
git checkout gh-pages
git pull
git rebase master
git push

echo "--> Helm package and re-index"
for c in cronjobs nginx-phpfpm; do
  [ -z "$(git status -s ./drpsychick/$c/Chart.yaml)" -a -z "$UPDATE" ] && bumpChartVersion $c
  (cd drpsychick; helm dependency update $c; helm package $c)
  mv ./drpsychick/$c-*.tgz ./docs/
done

helm repo index ./docs --url https://drpsychick.github.io/charts/

echo "--> Commit and push changes to gh-pages"
git add .
git commit -m "publish charts" -av
git push

# switch back to master and merge
echo "--> Checkout master and merge gh-pages"
git checkout master
git pull
git merge gh-pages
git push