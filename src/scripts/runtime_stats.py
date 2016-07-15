#!/usr/bin/env python
# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import numpy as np

x = np.arange(1, 31, 1)
y = [2.284,3.521,4.090,6.174,7.009,7.988,8.786,12.269,13.443,14.616,15.783,16.898,18.094,19.274,20.407,26.577,28.070,29.414,30.947,32.385,34.167,35.288,37.013,38.345,39.589,40.986,42.677,44.047,45.399,46.85]

x = x[0 : len(y)]

plt.plot(x, y, color="brown")
plt.xlabel('Maximal coverage $k$')
plt.ylabel('Runtime in $s$')
plt.savefig("runtime_stats.pdf", bbox_inches='tight', format="pdf")
plt.close()
