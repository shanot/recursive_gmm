#!/bin/bash

f=$(basename $1)
cat $f/*.gmm |grep -v '#' > $f/$f.txt
echo 1337
