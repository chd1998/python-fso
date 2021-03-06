'''
fits2jpg-single-xx.py
@author: chen dong @ fso
purposes: generating the jpeg thumbnails of fits files in source SAVE_DIRECTORY
Note: single --- using 1 thread; parallel --- using specific number of threads via input

Usage: python fits2jpg-single-xx.py -p <inputpath> --sx <num1> --sy <num2>
Example: python fits2jpg-single-xx.py -p d:\\fso-test --sx 200 --sy 200

20190701	Release 0.1		prototype version both in single & parallel version
20190705	Release 0.2     revised, add input argvs

'''

import os
import PIL
import datetime
import numpy as np

from PIL import Image
from astropy.io import fits

SIZE = (256,256)
SAVE_DIRECTORY = 'thumbs'

def get_image_paths(folder):
    return (os.path.join(folder, f)
            for f in os.listdir(folder)
            if 'fits' in f)

def create_thumbnail(filename):
    hud = fits.open(filename)
    immax = np.max(hud[0].data)
    immin = np.min(hud[0].data)
    im1 = ((hud[0].data-immin)/(immax-immin))*255
    im1 = im1.astype('uint8')
    #im1 = im1.astype(np.int8)
    hud.close()
    #tmp = tmp.astype(np.int32)
    im = Image.fromarray(im1,mode="L")
    im.thumbnail(SIZE, Image.ANTIALIAS)
    #im.resize(SIZE)
    base, fname = os.path.split(filename)
    fname = fname+".jpg"
    save_path = os.path.join(base, SAVE_DIRECTORY, fname)
    im.save(save_path)

if __name__ == '__main__':
    folder = os.path.realpath(
        'D:\\fso-imag\\fso-test')
    if not os.path.isdir(os.path.join(folder, SAVE_DIRECTORY)):
        os.makedirs(os.path.join(folder, SAVE_DIRECTORY))

    images = get_image_paths(folder)
    a = datetime.datetime.now()

    print ("Converting...")
    tmpnum=1
    for image in images:
        print ('%4d : %s' %(tmpnum,image))
        create_thumbnail(image)
        tmpnum +=1

    b = datetime.datetime.now()
    delta = b - a
    print ("Time Used: %d ms" %(int(delta.total_seconds() * 1000)))
