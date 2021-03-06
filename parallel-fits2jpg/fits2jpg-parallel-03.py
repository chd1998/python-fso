'''
fits2jpg-parallel-xx.py

@author: chen dong @ fso
purposes: generating the jpeg thumbnails of fits files in source SAVE_DIRECTORY
Note: single --- using 1 process; parallel --- using specific number of processes via input

Usage: python fits2jpg-parallel-xx.py -p <inputpath> --sx <num1> --sy <num2>
Example: python fits2jpg-parallel-xx.py -p d:\\fso-test --sx 200 --sy 200

Changlog:
20190701	Release 0.1		prototype version both in single & parallel version
20190705	Release 0.2     revised, add input argvs
<<<<<<< HEAD
20191212    Release 0.3     using click to input argvs
=======
20191210    Release 0.3     using click instead of getopt
>>>>>>> b1b3960921e4d0d15c04a99f3a3123de483be9c0

'''

import os
import PIL
import datetime
import numpy as np
import sys,click

from PIL import Image
from multiprocessing import Pool
from astropy.io import fits
TSIZE=(256,256)
SAVEDIR="thumbs"
@click.command()
@click.option('--path', default=".", nargs=1, required=True, help='path of source images')
@click.option('--pn', default="1",nargs=1, required=True, type=int, help='process numbers, >=1')
@click.option('--sx', default=256,nargs=1, required=True, type=int, help='x size of thumbnail')
@click.option('--sy', default=256,nargs=1, required=True, type=int, help='y size of thumbnail')
@click.option('--savedir', default="thumbs",nargs=1, required=True, type=str, help='directory of thumbnail, related to path')

def main(path,pn,sx,sy,savedir):
    TSIZE=tuple([sx,sy])
    SAVEDIR=savedir
    folder = os.path.realpath(path)
    if not os.path.isdir(os.path.join(folder)):
        print ("Folder %s doesn't exist!  Pls Check..." % path)
    else:
        #print(tsize,TSIZE)
        
        if not os.path.isdir(os.path.join(folder, savedir)):
            os.makedirs(os.path.join(folder, savedir))

        images = get_image_paths(folder)
        #for image in images:
        #    print (image)
        a = datetime.datetime.now()
        pool = Pool(processes=pn)
        print("Converting...")
<<<<<<< HEAD
        #print (TSIZE,SAVEDIR)
=======
        print (TSIZE,SAVEDIR)
>>>>>>> b1b3960921e4d0d15c04a99f3a3123de483be9c0
        pool.map(create_thumbnail, images)
        pool.close()
        pool.join()
        b = datetime.datetime.now()
        delta = b - a
        print("Time Used with %d thread : %d ms" %(pn, int(delta.total_seconds() * 1000)))


def get_image_paths(folder):
    return (os.path.join(folder, f)
            for f in os.listdir(folder)
            if 'fits' in f)


def create_thumbnail(filename):
    #print (TSIZE)
    hud = fits.open(filename)
    immax = np.max(hud[0].data)
    immin = np.min(hud[0].data)
    im1 = ((hud[0].data - immin) / (immax - immin)) * 255
    im1 = im1.astype('uint8')
    #im1 = im1.astype(np.int8)
    hud.close()
    #tmp = tmp.astype(np.int32)
    im = Image.fromarray(im1, mode="L")
    im.thumbnail(TSIZE, Image.ANTIALIAS)
    # im.resize(SIZE)
    base, fname = os.path.split(filename)
    print(base,fname)
    fname = fname + ".jpg"
    save_path = os.path.join(base, SAVEDIR, fname)
    print("Converting %s" % fname)
    im.save(save_path)
    print (save_path)


if __name__ == '__main__':
    main()
