import IMP
import IMP.em
import numpy as np
import pickle

import sys
import os

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

print "map_name     = ",map_name
#computing file names
X_name = map_name + "_X.npy"
w_name = map_name + "_w.npy"
m_name = map_name + "_mass.p"

#loading maps
X=None
w=None
dm = IMP.em.read_map(map_name, IMP.em.MRCReaderWriter())
X, w = get_data_from_map(dm, threshold)
np.save(X_name, X)
np.save(w_name, w)
#dm = IMP.em.read_map(map_name, IMP.em.MRCReaderWriter())
total_mass=IMP.em.approximate_molecular_mass(dm,threshold)
pickle.dump(total_mass, open(m_name, "wb"))
