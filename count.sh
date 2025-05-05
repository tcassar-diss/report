#!/usr/bin/env bash

git ls-files '*.tex' | egrep -v '[a-z/]*-old.tex|appendices.tex|title.tex|todos.tex|screencast/[a-z]*' | xargs texcount | grep -A 8 Total
