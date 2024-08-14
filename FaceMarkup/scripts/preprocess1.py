#!/usr/bin/env python
'''
Usage:
 preprocess1.py [FOLDER]

Recursively find all .jpg and .wrl files in FOLDER,
 rename according to PoBI format, and
 organise in "probably-ears" and "probably-faces" folders.
 "probably-ears" and "probably-faces" are local (relative to cwd, not to FOLDER)

Note:
 To extract zip files efficiently run unzip with the following arguments,
 counting the number of asterixes required for the depth of those files within
 the archives. This will keep the path structure present in the zip files (as
 required by `preprocess1.py`), but limits the extraction to *.wrl and *.jpg
 files only.
 `unzip -Ppassword /path/to/\*.zip \*/\*/\*.wrl \*/\*/\*.jpg`
'''
from   collections import defaultdict
import os
import re
#import shutil
import sys
#import subprocess
#import stat

from fixwrl import updatewrl




def bitsandpieces(path, filename):
  # ex. 'some/path/OXF203/130222034902', '130222034902.jpg'
  # -> ('some/path/OXF203/130222034902/130222034902.jpg',
  #     'OXF203',
  #     'OXF203-130222034902.jpg')
  fullname = os.path.join(path, filename)
  fldname  = os.path.split(os.path.split(path)[0])[1].upper()
  newname  = fldname + '-' + filename
  return (fullname, fldname, newname)



def main(folder):
  h    = defaultdict(list)
  bits = (bitsandpieces(path, f)
      for (path,dirs,files) in os.walk(folder)
      for f in files
      if f.lower().endswith('.wrl') or f.lower().endswith('.jpg'))

  # -- rename all files
  #    moving them to cwd in the process
  
  for fullname, stu, newname in bits:
    h[stu].append(newname)
    os.rename(fullname, newname)  # <- preferred
    #copyfile(fullname, newname)  # <- only when folders are read-only

  # -- distribute over "probably-ears" and "probably-faces" subfolders
  #    fix .wrl files in the process
  
  notfixed = []
  
  os.makedirs('probably-ears')
  os.makedirs('probably-faces')
  
  for stu in h:
    photos   = sorted(h[stu])  # includes both .wrl and .jpg
    wrl      = (f for f in photos if f.endswith('.wrl') and \
          os.path.isfile(f[:-4]+'.jpg'))
    notfixed.extend(filter(lambda f: not fixwrl('',f), wrl))
    for f in photos[:2]:
      os.rename(f, os.path.join('probably-faces', f))
    for f in photos[2:]:
      os.rename(f, os.path.join('probably-ears', f))
  
  # -- report files in which texture definition could not be found
  
  if len(notfixed):
    print 'Failed to fix texture in:'
    print '  ' + '\n  '.join(notfixed)



if __name__ == '__main__':
  fld = sys.argv[1] if len(sys.argv)>1 else '.'
  main(fld)


