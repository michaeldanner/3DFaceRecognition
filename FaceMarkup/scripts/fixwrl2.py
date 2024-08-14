#!/usr/bin/env python
"""
fixwrl.py FILEPATTERN

Find all .wrl files and fix their texture url declaration, giving
preference to jpg over png over bmp texture files.

For each wrl file the following texture files are tested for existence
(in order):
  1. <declared>.jpg
  2. <filename>.jpg
  3. <declared>.png
  4. <filename>.png

The first pattern to point to an existing file will be chosen and the
wrl file will be updated accoringly. If not, the wrl file will be left
untouched.

<declared> is the texture file name as declared in the wrl file.
<filename> is the base name of the wrl file (<filename>.wrl).

FILEPATTERN is a pattern to find the wrl files. If it is a folder, the
folder will be searched for files with the .wrl extension. Otherwise
(file name, possibly with wildcards) the matching files with .wrl
extension are included.

Note that if no file can be found with the above patterns, the source
file will NOT be updated.
"""
import re
import sys

from glob import iglob
from os import rename
from os.path import isfile, splitext
from os.path import join as joinpath
from os.path import split as splitpath


re_url = re.compile(r'^(.*url\s+)(.*)$')
clean_url = lambda m: m.group(2).strip().strip('"')


class TextureNotFound(FileNotFoundError):
    """Cannot determine texture file for wrl."""

class NoURL(Exception):
    """Cannot find the URL declaration in a wrl file."""


def texturefile(path, name, mfilename):
    """Returns the best, existing, texture file.

    Args:
        path: Folder name of the wrl file.
        name: File base name of the wrl file.
        mfilename: Texture file as originally declared in the wrl file.

    Returns:
        The best texture file name, if one exists.
        Raises TextureNotFound otherwise.
    """
    mbase = splitext(mfilename)[0]
    mpath, mname = splitpath(mbase)

    folders = ['', mpath]
    files = [mname+'.jpg', name+'.jpg', mname+'.png', name+'.png']

    for filename in files:
        for folder in folders:
            if isfile(joinpath(path, folder, filename)):
                return joinpath(folder, filename)
    
    raise TextureNotFound


def updatewrl(filename):
    """Adjusts the texture declaration in a wrl file to prefer jpg.
    
    Args:
        filename: File name of the wrl file to be updated.

    Raises:
        TextureNotFound if no suitable texture file could be found.
        NoURL if no url declaration could be found in the wrl.
    """
    base = splitext(filename)[0]
    path, name = splitpath(base)

    resub_url = lambda m: m.group(1) + '"{:s}"\r\n'.format(texturefile(path, name, clean_url(m)))
  
    bkpfile = filename + '.bkp'
    tmpfile = filename + '.tmp'

    success = False

    with open(filename) as fin:
        for i in range(50):
            line = fin.readline()
            m = re_url.match(line)
            if m:
                with open(tmpfile, 'w') as fout:
                    fout.writelines(headers)
                    fout.write(resub_url(m))
                    fout.write(fin.read())
                success = True
                break
            else:
                headers.append(line)

    if success:
        rename(filename, bkpfile)
        rename(tmpfile, filename)
    else:
        raise NoURL


if __name__ == '__main__':
    pattern = sys.argv[1] if len(sys.argv)>1 else '.'

    if isdir(pattern):
        pattern = joinpath(pattern, '*.wrl')

    files = (f for f in iglob(pattern) if f.lower().endswith('.wrl'))

    for i, f in enumerate(files):
        print('{:5d}. {:s}'.format(i, f))
        try:
            updatewrl(f)
        except TextureNotFound:
            print(' -- no texture file. skip.')
        except NoURL:
            print(' -- no URL declaration. skip.')
    
    print('done.')

