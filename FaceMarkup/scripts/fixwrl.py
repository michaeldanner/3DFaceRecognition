#!/usr/bin/env python
"""
FIXWRL FOLDERNAME

Find all .wrl files and fix their texture url declaration.

Files are organised such that abcdef.wrl has texture abcdef.jpg. Often, however,
the reference to the texture file within the .wrl file is incorrect (e.g.
pointing to a subfolder or .bmp file). This file fixes the texture declaration
in all .wrl files.

FOLDERNAME or its subfolders contain .wrl files and identically named .jpg
texture files.

Note that if the .jpg file is not present, the .wrl file will NOT be modified.
"""
import re, os, sys


resub_url = re.compile(r'^(.*url\s+")([^"]+)(".*)$')



def updatewrl(path, wrlname, delete_original=False):
  """ Fix the reference to the texture file in a .wrl file.
  Files are organised such that abcdef.wrl has texture abcdef.jpg. Often,
  however, the reference to the texture file within the .wrl file is incorrect
  (e.g. pointing to a subfolder or .bmp file). This function fixes the texture
  declaration.
  Note that if the .jpg file is not present,
            the .wrl file will NOT be modified.

  # ONLY! set delete_original True when you are VERY SURE of what you are doing
  # AND you are short on diskspace. In any other case leave commented out and
  # run `rm *.tmp` after you have checked the result.
  """
  jpgname = wrlname[:-4] + '.jpg'
  tmpname = wrlname + '.tmp'
  bkpname = wrlname + '.bkp'
  
  rerep   = lambda m: m.group(1) + jpgname + m.group(3)
  
  success = False
  
  headers = []
  with open(os.path.join(path, wrlname)) as fin:
    for i in range(50):
      line = fin.readline()
      if 'url' in line:
        if jpgname in line:
          break# no change? then don't touch the file.
        with open(os.path.join(path, tmpname), 'w') as fout:
          fout.writelines(headers)
          fout.write(resub_url.sub(rerep, line))
          fout.write(fin.read())
        success = True
        break
      elif line.strip().endswith('.bmp') or line.strip().endswith('.jpg'):
        # wk0003: Adding "url" to the line slightly worries me. Leave for now.
        with open(os.path.join(path, tmpname), 'w') as fout:
          fout.writelines(headers)
          fout.write('          url "%s"\r\n' % jpgname)
          fout.write(fin.read())
        success = True
        break
      else:
        headers.append(line)
  
  if success:
    os.rename( os.path.join(path,wrlname), os.path.join(path,bkpname) )
    os.rename( os.path.join(path,tmpname), os.path.join(path,wrlname) )
    if delete_original:
      os.unlink( os.path.join(path,bkpname) )
  return success



if __name__ == '__main__':
  wrldir = sys.argv[1] if len(sys.argv)>1 else '.'
  if not os.path.isdir(wrldir):
    print 'Error: That path is not a directory. Aborting.'
    sys.exit(1)
  
  wrlfiles = ((path,fname) for (path,dirs,files) in os.walk(wrldir) \
        for fname in files if fname.endswith('.wrl') and \
        os.path.isfile(os.path.join(path,fname[:-4]+'.jpg')))
  
  for path,wrlname in wrlfiles:
    print wrlname + '...',
    print 'done' if updatewrl(path,wrlname) else 'failed'
  print('finished.')



