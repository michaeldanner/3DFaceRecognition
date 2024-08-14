FaceMarkup
----------
The CVSSP internal parent of the public libFaceMarkup library for dealing with
3D faces in Matlab.

This repository contains some unreleased code and some private data (e.g. to do
with PoBI). Please do not publish to public repositories. Instead, if certain
files are deemed suitable for public then perhaps they ought to be moved to
libFaceMarkup. Discuss with author.


## Usage

To make all code available to you in Matlab, do the following:

1. Add `FaceMarkup` to your Matlab path.
2. Run `init_facemarkup;`.

If you prefer, you can set this up in your `startup.m` which is automatically
run each time you start Matlab.

All scripts are extensively documented, so just view the files for how to use
them.


## Files and folders

`auxi` contains auxiliary data, such as computed means and reference shapes /
annotations.

`convert` contains functions to convert between numbers and formats, etc. Also
code to convert 2D landmark annotations on the texture image to 3D spatial
coordinates on the mesh.

`mains` contains various programs that are suited to be run from the command
line (take string arguments, and can be compiled). Examples include
`annotate_ics.m` to fully automatically annotate 3D faces, and
`eval_annotations.m` to evaluate the overall accuracy of all annotations found
in a folder.

`scripts` contains mostly Python scripts that run Ravl executables in a more
convenient way: for example `registerall.py` runs the morphable model
registration for all files in a given folder.

