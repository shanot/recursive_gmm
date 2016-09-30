import IMP
import IMP.em
import IMP.bayesianem
import IMP.isd.gmm_tools as GMM
import numpy as np
import sklearn.mixture
import cPickle as pickle
import copy

import sys
import os

def fit_gmm_to_points(points,
        n_components,
        mdl,
        ps=[],
        num_iter=100,
        covariance_type='full',
        min_covar=0.001,
        init_centers=[],
        force_radii=-1.0,
        force_weight=-1.0,
        mass_multiplier=1.0,
        w=None):
    """fit a GMM to some points. Will return the score and the Akaike score.
    Akaike information criterion for the current model fit. It is a measure
    of the relative quality of the GMM that takes into account the
    parsimony and the goodness of the fit.
    if no particles are provided, they will be created

    points:            list of coordinates (python)
    n_components:      number of gaussians to create
    mdl:               IMP Model
    ps:                list of particles to be decorated. if empty, will add
    num_iter:          number of EM iterations
    covariance_type:   covar type for the gaussians. options: 'full', 'diagonal', 'spherical'
    min_covar:         assign a minimum value to covariance term. That is used to have more spherical
                       shaped gaussians
    init_centers:      initial coordinates of the GMM
    force_radii:       fix the radii (spheres only)
    force_weight:      fix the weights
    mass_multiplier:   multiply the weights of all the gaussians by this value
    dirichlet:         use the DGMM fitting (can reduce number of components, takes longer)
    """

    params='m'
    init_params='m'
    if force_radii==-1.0:
        params+='c'
        init_params+='c'
    else:
        covariance_type='spherical'
        print('forcing spherical with radii',force_radii)

    if force_weight==-1.0:
        params+='w'
        init_params+='w'
    else:
        print('forcing weights to be',force_weight)

    print('creating GMM with params',params,'init params',init_params,'n_components',n_components,'n_iter',num_iter,'covar type',covariance_type)
    gmm=sklearn.mixture.GMM(n_components=n_components,
            n_iter=100,
            covariance_type=covariance_type,
            min_covar=min_covar,
            params=params,
            init_params=init_params,
            tol=1e-30)

    if force_weight!=-1.0:
        gmm.weights_=np.array([force_weight]*n_components)
    if force_radii!=-1.0:
        gmm.covars_=np.array([[force_radii]*3 for i in range(n_components)])
    if init_centers!=[]:
        gmm.means_=init_centers
    print('fitting')
    model=gmm.fit(points,w=w)
    score=gmm.score(points)
    akaikescore=model.aic(points)
    #print('>>> GMM score',gmm.score(points))

    ### convert format to core::Gaussian
    for ng in range(n_components):
        covar=gmm.covars_[ng]
        if covar.size==3:
            covar=np.diag(covar).tolist()
        else:
            covar=covar.tolist()
        center=list(gmm.means_[ng])
        weight=mass_multiplier*gmm.weights_[ng]
        if ng>=len(ps):
            ps.append(IMP.Particle(mdl))
        shape=IMP.algebra.get_gaussian_from_covariance(covar,IMP.algebra.Vector3D(center))
        g=IMP.core.Gaussian.setup_particle(ps[ng],shape)
        IMP.atom.Mass.setup_particle(ps[ng],weight)
        IMP.core.XYZR.setup_particle(ps[ng],np.sqrt(np.max(g.get_variances())))

    return (gmm, score, akaikescore)


def build_gmm(mdl, X, w, n_centers, mass_mul):
    density_ps = []
    gmm, score, akaike = fit_gmm_to_points(
            X, n_centers, mdl, ps=density_ps, num_iter=100, covariance_type='full', min_covar=0.001, w=w, mass_multiplier=mass_mul)
    return density_ps, gmm, score, akaike


def get_data_from_map(dm, threshold=0.0):
    #build data matrix
    n_data = dm.get_number_of_voxels()
    X = []
    dens = []
    for i in range(n_data):
        w = dm.get_value(i)
        if(w > threshold):
            dens.append(w)
            X.append(dm.get_location_by_voxel(i))
    return (np.array(X), np.array(dens))

mdl = IMP.Model()

map_name = sys.argv[1]
threshold = float(sys.argv[2])
n_centers = int(sys.argv[3])
gmm_name = None
gaussian_idx = None
if len(sys.argv) > 5:
    gmm_name = sys.argv[4]
    gaussian_idx = int(sys.argv[5])

print "map_name     = ",map_name
print "threshold    = ",threshold
print "n_centers    = ",n_centers
print "gmm_name     = ",gmm_name
print "gaussian_idx = ",gaussian_idx

rasterization_cutoff = 8

#computing file names
if gmm_name:
    output_name = "%d/%d.gmm" % (n_centers, gaussian_idx)
    gmm_pickle=gmm_name.replace(".txt", ".P")
else:
    output_name = "%d/%d.gmm" % (n_centers,n_centers)
output_pickle=output_name.replace(".gmm", ".p")
X_name = map_name + "_X.npy"
w_name = map_name + "_w.npy"
m_name = map_name + "_mass.p"

#loading maps
X=None
w=None
if os.path.isfile(X_name) and os.path.isfile(w_name):
    X=np.load(X_name)
    w=np.load(w_name)
else:
    print "run mrc2npy on the map"
    exit()
#    dm = IMP.em.read_map(map_name, IMP.em.MRCReaderWriter())
#    X, w = get_data_from_map(dm, threshold)
#    np.save(X_name, X)
#    np.save(w_name, w)
if os.path.isfile(m_name):
    total_mass = pickle.load(open(m_name, "rb"))
else:
    print "run mrc2npy on the map"
    exit()
#    dm = IMP.em.read_map(map_name, IMP.em.MRCReaderWriter())
#    total_mass=IMP.em.approximate_molecular_mass(dm,threshold)
#    pickle.dump(total_mass, open(m_name, "wb"))


#loading gmm
gmm_ps = []
gmm=None
if gmm_name:
    IMP.isd.gmm_tools.decorate_gmm_from_text(gmm_name, gmm_ps, mdl)
    gmm = pickle.load(open(gmm_pickle,'rb'))

#compute the partial map
w_sum=w.sum()
if gmm:
    sub_gmm=copy.deepcopy(gmm)
    sub_gmm.weights_=np.array([sub_gmm.weights_[gaussian_idx]])
    sub_gmm.means_= np.array([sub_gmm.means_[gaussian_idx]])
    sub_gmm.covars_=np.array([sub_gmm.covars_[gaussian_idx]])
    sub_gmm.n_components=1
    gmm_values = np.exp(gmm.score_samples(X)[0])
    sub_gmm_values = np.exp(sub_gmm.score_samples(X)[0])
    w*=sub_gmm_values/gmm_values

#get the gmm of the masked map
sel=np.where(w>threshold)
w=w[sel]
X=X[sel]
sub_w_sum = w.sum()
mass_ratio = sub_w_sum/w_sum
n_gaussian = int(round(n_centers*mass_ratio))
print "n=%d, mass_ratio = %e, n_gaussian   = %d" %(n_centers, mass_ratio, n_gaussian)
if mass_ratio>1:
    exit()
if n_gaussian<=1:
    density_ps=[gmm_ps[gaussian_idx]]
    output_gmm = sub_gmm
else:
    density_ps, output_gmm, score, akaike = build_gmm(mdl, X, w, n_gaussian, total_mass*mass_ratio)
GMM.write_gmm_to_text(density_ps, output_name)
pickle.dump(output_gmm, open(output_pickle,'wb'))
