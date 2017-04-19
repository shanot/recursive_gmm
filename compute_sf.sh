#!/bin/bash

e2proc3d.py threshold.map  tmp.map --calcsf orig.sf &
for f in [0-9]*/*.mrc
do
	e2proc3d.py $f tmp.map --calcsf $(basename $f .mrc).sf &
done
