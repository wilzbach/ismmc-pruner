#!/usr/bin/env python
# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt
import numpy as np

x = [0.01, 0.05, 0.1, 0.15, 0.2, 0.3, 0.4, 0.6, 0.8, 1]
y = [1/18, 4/18, 11/18, 16/18, 18/18, 1, 1, 1, 1.0001]

x = x[0 : len(y)]

plt.plot(x, y, color="brown")
plt.xlabel('% of reads of existing alignment')
plt.ylabel('% of phased variantes of normal WhatsHap')
plt.savefig("efficiency_stats.pdf", bbox_inches='tight', format="pdf")
plt.close()
