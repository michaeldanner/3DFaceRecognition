#!/usr/bin/env python
""" List all .wrl files and their texture maps.

Description
================
Recursively search a directory tree and find all .wrl files. The file is read to
find it texture map. The results are written to a text file in a format
described below.


Usage
==========
listfiles.py INPUTFOLDER [OUTPUTFILE]

INPUTFOLDER  Directory to be searched.
OUTPUTFILE   Write all found .wrl files and their texture files to this file.
             This value defaults to "3dfiles.lst".


Example output file
========================
%folder=/vol/vssp/facecap/Oxford/all
/COR703/100317110038/ 100317110038.wrl 100317110038.jpg
/COR703/100317110152/ 100317110152.wrl 100317110152.jpg
/COR703/100317110241/ 100317110241.wrl 100317110241.jpg
...

Explanation
----------------
The first line defines the base folder from which all .wrl files have been
sought. Following, each line lists 3 values, separated by whitespace. The first
value is the subpath under the base folder. The second value is the filename for
the .wrl file and the last value is the texture file as referenced in the .wrl
file.
To reconstruct the full filenames concatenate <folder>+<subpath>+<filename>.

"""
import getopt, os, re, sys



### -------------------------------------------------- UTILITY FUNCTIONS -------
def find_texture( wrlfilename, maxi=50 ):
	try:
		f = open( wrlfilename, 'r' )
	except IOError:
		return ''
	i = 0
	for line in f:
		i = i + 1
		url = re.findall( '(?:url|filename)\s*"([^"]+\.(?:jpg|bmp|png))"', line )
		if url or i > maxi:
			break
	f.close()
	return url[0] if url else ''

def find_3dfiles( path, folders, files ):
	wrl     = (f for f in files if f.endswith( '.wrl' ))
	wrl_tex = ((w,find_texture( os.path.join( path, w ) )) for w in wrl)
	return ((path+os.path.sep,w,t) for w,t in wrl_tex if t in files)

def get_3dfiles( folder ):
	rel = len( folder )
	return ((p[rel:],w,t) for walk in os.walk( folder )
				for p,w,t in find_3dfiles( *walk ))


### ------------------------------------------------------ BASE FUNCTION -------
def process( inputfolder, outputfile='3dfiles.lst' ):
	if not os.path.isdir( inputfolder ):
		raise IOError( (-1,'The folder does not exist',inputfolder) )
	if inputfolder.endswith( os.path.sep ):
		inputfolder = inputfolder[:-len(os.path.sep)]
	
	# open file before scanning to throw IOError if access denied
	f = open( outputfile, 'w' )
	f.write( '%%folder=%s\n' % inputfolder )
	
	scans = get_3dfiles( inputfolder )
	f.writelines( '%s %s %s\n' % l for l in scans )
	
	f.close()
	return 0


### ------------------------------------------------------------- ERRORS -------
class Error( Exception ):
	def __init__( self, message, filename='' ):
		self.strerror = message
		self.filename = filename
	def __str__( self ):
		return repr( self.strerror )


### ----------------------------------------- 'MAIN' INTERACTS WITH USER -------
def main( argv=sys.argv ):
	try:
		# parse command line options
		try:
			opts, args = getopt.getopt( argv[1:], "h", ["help"] )
		except getopt.error, msg:
			raise Usage( msg )
		# process options
		for o, a in opts:
			if o in ("-h", "--help"):
				print __doc__
				return 0
		# process arguments
		if len( args ) < 1:
			raise Usage( "No base folder specified." )
		elif len( args ) > 2:
			raise Usage( "Too many arguments." )
		return process( *args )
	except IOError, err:
		print >>sys.stderr, err.strerror
		print >>sys.stderr, err.filename
		print >>sys.stderr, "---"
		print >>sys.stderr, "for help use --help"
		return 1
	except Usage, err:
		print >>sys.stderr, err.msg
		print "---"
		print >>sys.stderr, "for help use --help"
		return 2

if __name__ == '__main__':
	sys.exit( main() )


