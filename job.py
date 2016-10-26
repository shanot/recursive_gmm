import numpy as np
import sklearn.mixture
import cPickle as pickle
import copy
from scipy import linalg

import sys
import os


def eval_gmm(X, gmm, min_covar=1.e-7):
    means = gmm.means_
    covars = gmm.covars_
    n_samples, n_dim = X.shape
    val = np.zeros(n_samples)
    for c, (mu, cv) in enumerate(zip(means, covars)):
        det = linalg.det(cv)
        inv = linalg.inv(cv)
        val += np.exp(-0.5 * np.sum((X - mu) * np.dot(inv, (X - mu).T).T, axis=1)) / \
            np.sqrt((2 * np.pi) ** n_dim * det)
    return val


def fit_gmm_to_points(points,
                      n_components,
                      num_iter=10000,
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

    params = 'm'
    init_params = 'm'
    if force_radii == -1.0:
        params += 'c'
        init_params += 'c'
    else:
        covariance_type = 'spherical'
        print('forcing spherical with radii', force_radii)

    if force_weight == -1.0:
        params += 'w'
        init_params += 'w'
    else:
        print('forcing weights to be', force_weight)

    print('creating GMM with params', params, 'init params', init_params,
          'n_components', n_components, 'n_iter', num_iter, 'covar type', covariance_type)
    gmm = sklearn.mixture.GMM(n_components=n_components,
                              n_iter=10000,
                              covariance_type=covariance_type,
                              min_covar=min_covar,
                              params=params,
                              init_params=init_params,
                              tol=1e-10,
                              verbose=2)

    if force_weight != -1.0:
        gmm.weights_ = np.array([force_weight] * n_components)
    if force_radii != -1.0:
        gmm.covars_ = np.array(
            [[force_radii] * 3 for i in range(n_components)])
    if init_centers != []:
        gmm.means_ = init_centers
    print('fitting')
    model = gmm.fit(points, w=w)
    score = gmm.score(points)
    akaikescore = model.aic(points)

    for i in range(len(gmm.weights_)):
        gmm.weights_[i] *= mass_multiplier

    return (gmm, score, akaikescore)


def build_gmm(X, w, n_centers, mass_mul):
    gmm, score, akaike = fit_gmm_to_points(
        X, n_centers, num_iter=100, covariance_type='full', min_covar=0.001,
        w=w, mass_multiplier=mass_mul)

    return gmm, score, akaike


map_name = sys.argv[1]
threshold = float(sys.argv[2])
n_centers = int(sys.argv[3])
gmm_name = None
gaussian_idx = 0
if len(sys.argv) > 5:
    gmm_name = sys.argv[4]
    gaussian_idx = int(sys.argv[5])

print "map_name     = ", map_name
print "threshold    = ", threshold
print "n_centers    = ", n_centers
print "gmm_name     = ", gmm_name
print "gaussian_idx = ", gaussian_idx

rasterization_cutoff = 8

#computing file names
if gmm_name:
    gmm_pickle = gmm_name.replace(".txt", ".P")
output_pickle = "%d/%d_%d.p" % (n_centers, n_centers, gaussian_idx)
X_name = map_name + "_X.npy"
w_name = map_name + "_w.npy"
m_name = map_name + "_mass.p"

#loading maps
X = None
w = None
if os.path.isfile(X_name) and os.path.isfile(w_name):
    X = np.load(X_name)
    w = np.load(w_name)
else:
    print "run mrc2npy on the map"
    exit()
if os.path.isfile(m_name):
    total_mass = pickle.load(open(m_name, "rb"))
else:
    print "run mrc2npy on the map"
    exit()


#loading gmm
gmm = None
if gmm_name:
    gmm = pickle.load(open(gmm_pickle, 'rb'))

#compute the partial map
w_sum = w.sum()
if gmm:
    sub_gmm = copy.deepcopy(gmm)
    sub_gmm.weights_ = np.array([sub_gmm.weights_[gaussian_idx]])
    sub_gmm.means_ = np.array([sub_gmm.means_[gaussian_idx]])
    sub_gmm.covars_ = np.array([sub_gmm.covars_[gaussian_idx]])
    sub_gmm.n_components = 1
    sub_map_ratio = eval_gmm(X, sub_gmm) / eval_gmm(X, gmm)
    w *= sub_map_ratio

#get the gmm of the masked map
sub_w_sum = w.sum()
mass_ratio = sub_w_sum / w_sum
n_gaussian = int(round(n_centers * mass_ratio))
print "n=%d, mass_ratio = %e, n_gaussian   = %d" % (n_centers, mass_ratio, n_gaussian)
if mass_ratio > 1:
    exit()
if n_gaussian <= 1:
    output_gmm = sub_gmm
else:
    output_gmm, score, akaike = build_gmm(
        X, w, n_gaussian, total_mass * mass_ratio)
pickle.dump(output_gmm, open(output_pickle, 'wb'))
