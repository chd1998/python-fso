'''
sift-cv-xx.py

@author: chen dong @ fso
purposes: sift using cv

Usage: python sift-cv-xx.py input output
Example: python sift-cv-xx.py d:\fso-data\fso-test-data  result.jpg


Changlog:
20190701	Release 0.1		prototype version 

'''

import os
import PIL
import datetime
import numpy as np
import fire
import cv2
import Utility

from PIL import Image
from multiprocessing import Pool
from astropy.io import fits

def siftcv(path,savedir):
    SAVEDIR=savedir

    folder = os.path.realpath(path)
    if not os.path.isdir(os.path.join(folder)):
        print ("Folder %s doesn't exist!  Pls Check..." % path)
        sys.exit(0)
    else:
        if not os.path.isdir(os.path.join(folder, savedir)):
            os.makedirs(os.path.join(folder, savedir))

        images = get_image_paths(folder)
        lenImg=0
        arrayImg=[]
        for image in images:
            if lenImg==0:
                refImg=image
            else:
                arrayImg.append(image)
            lenImg=lenImg+1
            #print (image)
        tmp1=cv2.imread(arrayImg[1])
        dimx=tmp1.shape[0]
        dimy=tmp1.shape[1]
        finalImg=np.zeros(shape=(dimx,dimy))
        a = datetime.datetime.now()
        #print(lenImg)
        print(len(arrayImg))
        i=1
        for i in range(len(arrayImg)):
            print("Aligning %s to %s..." %(arrayImg[i],refImg))
            #print(arrayImg[i])
            tmp,finalImg=align_jpg(refImg,arrayImg[i])
            refImg=tmp
            i=i+1
        
        b = datetime.datetime.now()
        delta = b - a
        print("Time Used with : %d ms" %( int(delta.total_seconds() * 1000)))
        myimg1=cv2.imread(arrayImg[1])
        myimg2=cv2.imread(tmp)
        allImg = np.concatenate((myimg1,myimg2,finalImg),axis=1)
        cv2.namedWindow('Result',cv2.WINDOW_NORMAL)
        cv2.imshow('Result',allImg)
        cv2.waitKey(0)

def get_image_paths(folder):
    return (os.path.join(folder, f)
            for f in os.listdir(folder)
            if 'jpg' in f)

def align_jpg(img1,img2):
    img1 = cv2.imread(img1)
    img2 = cv2.imread(img2)
    result,_,_ = Utility.siftImageAlignment(img1,img2)
    #allImg = np.concatenate((img1,img2,result),axis=1)
    tmpName="tmp.jpg"
    cv2.imwrite(tmpName,result)
    return tmpName,result

if __name__ == '__main__':
    fire.Fire(siftcv)
    
    
