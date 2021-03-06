import matplotlib
import numpy as np
import matplotlib.pyplot  as plt
from astropy.io import fits
halpha = fits.open("/content/Ha_r000_20170806_090022_1B_sir.fits")
data = halpha[0].data
m,n = data.shape
print (m,n)
tdata = np.array([n,m])
tdata = data.T
m1,n1 = tdata.shape
print ('Min:', np.min(data))
print ('Max:', np.max(data))
print ('Mean:', np.mean(data))
print ('Stdev:', np.std(data))
plt.figure(1)
plt.subplot(211)
plt.imshow(data, cmap='gray')
plt.colorbar()
plt.show()
plt.subplot(212)
print (m1,n1)
print ('Min:', np.min(tdata))
print ('Max:', np.max(tdata))
print ('Mean:', np.mean(tdata))
print ('Stdev:', np.std(tdata))
plt.imshow(tdata, cmap='gray')
plt.colorbar()
plt.show()
