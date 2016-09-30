import os
import glob
from chimera import runCommand as rc
from chimera import replyobj

#change to folder with data files
os.chdir("/Users/shanot/Documents/Pasteur/emd_2670")

#em_map = "../mediator_modeling/em_map_files/asturias_mediator_translated.mrc"


def open_mrc(dir, thresh=0.1):
    density_names = glob.glob('[0-9][0-9][0-9]*/*.txt.mrc')
    i=0
    for d in density_names:
        rc("open " + d)
        rc("vol #" + str(i) + " level " + str(thresh))
        i=i+1
    rc("open emd_2670.map")
    rc("vol #" + str(i) + " level " + str(thresh))
    i=i+1
    rc("focus")


def set_background(background):
    rc("background solid " + background)


open_mrc(None, 0.75)
