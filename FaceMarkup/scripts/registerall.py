#!/usr/bin/env python
""" Batch-register a lump of annotated 3D scans.

Description
================
registerall.py recursively searches the first passed folder for .wrl and equally
named .jpg files. It searches the second passed folder for equally named .lnd
files. If such a triplet is found, it invokes register.py to register the 3D
scan using the Morphable Model. Ouput files are written to the third folder.

Update: now runs in parallel, as many instances as there are CPU's available.

Usage
==========
registerall.py WRLFOLDER LNDFOLDER OUTPUTFOLDER [-s | --symm]

WRLFOLDER     Directory containing .wrl and .jpg files. The .wrl files contain
              3D scan data to be registered.
LNDFOLDER     Directory containing .lnd files. The .lnd files contain
              coordinates of landmarks on the 3D scan.
              Defaults to WRLFOLDER.
OUTPUTFOLDER  Directory where all output files from registration are
              written to.
-s | --symm   Use symmetric face model
-l file | --lndfile file
              Specify model landmark file:
                defaults to 26pt (non-symmetric) | 14pt (symmetric)

"""
import argparse
import glob
import multiprocessing
import os
import re
import shutil
import subprocess
import sys
import tempfile



def find_texture(wrlfile, maxlines=50):
  """ Return the texture file for a VRML file (.wrl).
  """
  try:
    f = open(wrlfile, 'r')
  except IOError:
    return ''
  i = 0
  for line in f:
    i = i + 1
    url = re.findall('(?:url|filename)\s*"([^"]+\.(?:jpg|bmp|png))"', line)
    if url or i > maxlines:
      break
  f.close()
  return url[0] if url else ''


def list_files(wrlfolder, lndfolder):
  """ Find all VRML files in the given folder.
  Limit the list to files with a corresponding '.lnd' file in `lndfolder`.
  Return a list of tuples `[(wrlfile, lndfile), ...]`.
  """
  def annotationfile(wrlfile):
    name = os.path.splitext(os.path.split(wrlfile)[1])[0]
    return os.path.join(lndfolder, name+'.lnd')

  wrlfolder = os.path.abspath(wrlfolder)
  lndfolder = os.path.abspath(lndfolder)

  wrllist = glob.iglob(os.path.join(wrlfolder, '*.wrl'))
  lndlist = ((wrlfile, annotationfile(wrlfile)) for wrlfile in wrllist)
  return [(wrlfile, lndfile)
          for wrlfile,lndfile in lndlist if os.path.exists(lndfile)]


def register(wrlfile, lndfile, args={}, fldout='', verbose=False):
  """ Register a given VRML file.
  lndfile is the 3D annotation.
  fldout is where the registered image files will be written to.
  extra Register arguments can be set in args (advanced).
  set verbose=True to print progress.
  Returns the Register return code (should be zero), or an error message string.
  """
  prog = 'Register'
  args['S'] = wrlfile
  args['SL'] = lndfile
  jpgfile = find_texture(wrlfile)
  if jpgfile:
    args['SI'] = os.path.join(os.path.split(wrlfile)[0], jpgfile)
  command = '%s %s' % (prog, ' '.join('-%s %s' % a for a in args.items()))

  if verbose:
    print '----- CALLING: ' + '-' * 55
    print command
    print '-' * 70

  cwd = tempfile.mkdtemp()

  try:
    retcode = subprocess.call(command, cwd=cwd, shell=True)
  except OSError, e:
    print >>sys.stderr, 'Execution failed:', e
    retcode = str(e)
  else:
    if retcode < 0:
      print >>sys.stderr, 'Child was terminated by signal', -retcode
    else:
      # This is good, now rename the files.
      wrlin = os.path.join(cwd, 'Registered3DER.wrl')
      jpgin = os.path.join(cwd, 'isoRegistered3D.jpg')
      rgbin = os.path.join(cwd, 'triRegistered3D.rgb')

      basename = os.path.splitext(os.path.basename(wrlfile))[0]
      wrlout = os.path.join(fldout, basename + 'ER.wrl')
      jpgout = os.path.join(fldout, 'iso' + basename + '.jpg')
      rgbout = os.path.join(fldout, 'tri' + basename + '.rgb')

      if verbose:
        print
        print '----- RENAMING: ' + '-' * 54
        print 'Registered3DER.wrl   to  %sER.wrl' % basename
        if jpgfile:
          print 'isoRegistered3D.jpg  to  iso%s.jpg' % basename
        print 'triRegistered3D.rgb  to  tri%s.rgb' % basename
        print '-' * 70

      if jpgfile:
        shutil.move(jpgin, jpgout)
      shutil.move(rgbin, rgbout)

      with open(wrlin, 'r') as f1:
        with open(wrlout, 'w') as f2:
          for l in f1:
            if 'isoRegistered3D.jpg' in l:
              l = l.replace('isoRegistered3D.jpg', 'iso'+basename+'.jpg')
              f2.write(l)
              break
            f2.write(l)
          f2.writelines(l for l in f1)

      if verbose:
        print 'done.'
  try:
    shutil.rmtree(cwd)
  except OSError:
    pass
  return retcode


def register_all(wrlfolder, lndfolder, args={}, fldout='', verbose=False):
  """ Run `register` for all files in parallel.
  """
  nprocs = 1 if verbose else multiprocessing.cpu_count()
  args = list(
    (wrlfile, lndfile, args, fldout, verbose)
    for wrlfile,lndfile in list_files(wrlfolder, lndfolder)
  )
  pool = multiprocessing.Pool(processes=nprocs)
  return pool.map(star_process, args)


def star_process(args):
  register(*args)


def main():
  # parse command line options
  parser = argparse.ArgumentParser()
  parser.add_argument("folders", nargs=3, help="3 data directories, in order: wrl, landmark, output")
  parser.add_argument("-s", "--symm", help="use symmetric face model", action="store_true")
  parser.add_argument("-l", "--lndref", help="model landmark file: defaults to 26pt (without -s) | 14pt (with -s)")
  parser.add_argument('-v', '--verbose', help='run as single process and print extra information', action='store_true')
  args = parser.parse_args()

  verbose = args.verbose
  if verbose:
    print args

  # process arguments
  # default no. of landmarks is 26 for non-symmetric model, 14 for symmetric one

  if args.lndref:
    lndref = args.lndref
  elif args.symm:
    lndref = "MnFMdl-14.lnd"
  else:
    lndref = "MnFMdl.lnd"
  #if not os.path.exists(lndref):
  #  lndref = os.path.join(os.getenv('PROJECT_OUT'), 'share/3DMM', lndref)

  options = dict(GL=lndref)
  if args.symm:
    options['SYM'] = ' '

  wrlfolder = args.folders[0]
  lndfolder = args.folders[1]
  outputfolder = args.folders[2]
  if not os.path.exists(outputfolder):
    os.makedirs(outputfolder)

  # register all files.
  retval = register_all(wrlfolder, lndfolder, args=options,
                        fldout=outputfolder, verbose=verbose)
  print 'Processed %d scans (check output for failures though!!!)' % len(retval)
  return 0


if __name__ == '__main__':
  sys.exit(main())

