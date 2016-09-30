#!/usr/bin/env python

import cPickle as pickle
import sklearn.mixture
import numpy as np
import glob
import sys

folder=sys.argv[1]
files=glob.glob(folder+'/*.p')

gmm=None
for f in files:
    if gmm:
        other=pickle.load(open(f, 'rb'))
        gmm.n_components+=other.n_components
        gmm.weights_=np.concatenate((gmm.weights_,other.weights_), axis=0)
        gmm.means_=  np.concatenate((gmm.means_, other.means_   ), axis=0)
        gmm.covars_= np.concatenate((gmm.covars_, other.covars_ ), axis=0)
    else:
        gmm=pickle.load(open(f, 'rb'))

if gmm:
    pickle.dump(gmm, open(folder+'/'+folder+'.P', 'wb'))
    print "merged %d gaussians"%gmm.n_components
