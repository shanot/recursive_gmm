import IMP
import IMP.em
import IMP.isd.gmm_tools as GMM
import numpy as np
import matplotlib.pyplot as plt
import sys

from sklearn.decomposition import PCA

fname = sys.argv[1]
other_map = None
cutoff = float(sys.argv[2])
try:
    other_map = sys.argv[3]
    other_map = IMP.em.read_map(other_map, IMP.em.MRCReaderWriter())
except:
    other_map = None

voxel_size = 2
origin = None
bounding_box = None
if other_map:
    voxel_size = other_map.get_spacing()
    origin = other_map.get_origin()
    bounding_box = IMP.em.get_bounding_box(other_map)

print voxel_size
m = IMP.Model()
ps = []
IMP.isd.gmm_tools.decorate_gmm_from_text(fname, ps, m)
if other_map is None:
    GMM.write_gmm_to_map(
        ps, fname + '.mrc', voxel_size, bounding_box=bounding_box, origin=origin, fast=True, factor=cutoff
    )
else:
    out = GMM.gmm2map(ps, voxel_size, bounding_box=bounding_box,
                      origin=origin, fast=True)
    out2 = other_map
    for i in range(out2.get_number_of_voxels()):
        out2.set_value(i, out.get_value(i))
    IMP.em.write_map(out2, fname + '.mrc', IMP.em.MRCReaderWriter())
