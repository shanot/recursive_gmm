#!/usr/bin/env python

import IMP
import IMP.em
import IMP.bayesianem
import IMP.isd.gmm_tools as GMM

import cPickle as pickle
import sklearn.mixture
import numpy as np
import glob
import sys

folder=sys.argv[1]
output_name=sys.argv[2]
files=glob.glob(folder+'/*.p')

gmm=None
for f in files:
    if gmm:
        other=pickle.load(open(f, 'rb'))
        gmm.n_components+=other.n_components
        gmm.weights_=np.concatenate((gmm.weights_,other.weights_), axis=0)
        gmm.means_=  np.concatenate((gmm.means_, other.means_   ), axis=0)
        gmm.covars_= np.concatenate((gmm.covars_, other.covars_ ), axis=0)
        print "other.weights_",other.weights_
        print "other.means_    ",other.means_
        print "other.covars_   ",other.covars_
    else:
        gmm=pickle.load(open(f, 'rb'))
        print "gmm.weights_",gmm.weights_
        print "gmm.means_    ",gmm.means_
        print "gmm.covars_   ",gmm.covars_

if gmm:
    mdl = IMP.Model()
    pickle.dump(gmm, open(folder+'/'+folder+'.P', 'wb'))
    ### convert format to core::Gaussian
    ps=[]
    for ng in range(gmm.n_components):
        covar=gmm.covars_[ng]
        if covar.size==3:
            covar=np.diag(covar).tolist()
        else:
            covar=covar.tolist()
        center=list(gmm.means_[ng])
        if ng>=len(ps):
            ps.append(IMP.Particle(mdl))
        shape=IMP.algebra.get_gaussian_from_covariance(covar,IMP.algebra.Vector3D(center))
        g=IMP.core.Gaussian.setup_particle(ps[ng],shape)
        IMP.atom.Mass.setup_particle(ps[ng],gmm.weights_[ng])
        IMP.core.XYZR.setup_particle(ps[ng],np.sqrt(np.max(g.get_variances())))
    GMM.write_gmm_to_text(ps, output_name)
