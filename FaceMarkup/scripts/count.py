#!/usr/bin/env python
# Create a spreadsheet with annotation counts, per user and per file.
# Run pull_annotations.sh first to rsync the *.raw files to here.

import os
import sys
import glob
from collections import defaultdict



# list all *.raw files       --> files
#         (not *.lnd, because we want to know actual annotation progress!)
# count annotations per file --> ntimes
# list all users             --> users
# per user
#    map files to num annotated points --> points

def listfiles(pat):
	files = glob.iglob(pat)
	files = map(lambda f: os.path.splitext(os.path.split(f)[1])[0], files)
	return sorted(files)

def listusers(pat):
	folders = glob.iglob(pat)
	users   = map(lambda f: os.path.split(f)[1].split('-')[-1], folders)
	return sorted(users)

def countpoints(fname):
	return len(open(fname).readlines())

def nnz(tup):
	return sum(ti > 0 for ti in tup)



def main():
	files_pat = '../images/*.wrl'
	files     = listfiles(files_pat)
	
	users_pat = './manual-*'
	users     = listusers(users_pat)
	
	points    = dict((u,defaultdict(int)) for u in users)
	
	for i,u in enumerate(users):
		ufiles_pat = os.path.join(users_pat.replace('*',u), '*.raw')
		ufiles     = listfiles(ufiles_pat)
		uraw       = map(lambda f: ufiles_pat.replace('*', f), ufiles)
		
		print >> sys.stderr, '%15s: %d' % (u, len(ufiles))
		
		points[u].update(zip(ufiles, map(countpoints, uraw)))
	
	mat = [(f,) + tuple(points[u][f] for u in users) for f in files]
	mat = [mi + (nnz(mi[1:]),) for i,mi in enumerate(mat)]
	# sort on total number of annotations, then file name
	mat.sort(key=lambda t:(t[-1],t[0]))
	
	for i,mi in enumerate(mat):
		print ','.join(map(str, mi))


if __name__ == '__main__':
	main()




