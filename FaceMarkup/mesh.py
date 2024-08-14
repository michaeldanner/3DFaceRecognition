import argparse
import struct
import string

class Mesh:
    """
    Fast 3D Mesh representation based on half-edges.
        The class supports many functions for display and computation of mesh data.
        See:
    - private/halfedges.m  for details on the half-edge structure.
    - TODO: tests/runtest.m  for examples of all supported functions.
                TODO Look into:
     - trimarkpoint
     - precompute half-edge rep for texture.
     - improve fillholes to keep texture mapping working.
     -
     - plotting functions for things as borders, peaks, contours, etc.

      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Core properties.
           Core properties are included when Matlab serialises the object. For example
      when using Matlab's built-in `save(...)`, or when using a Mesh instance in
      a parfor loop when it is loaded outside of the loop. All other properties
      can be derived, these can't.
    """
    name = None
    # FIXME: make setter functions to reset all stored private properties.
    #        when the size of vertices does not change we can keep nb and edges.
    vertices = None       # VxD matrix of V cartesian coodinates.
    faces = None         # Fx3 matrix of vertex indices.
    vertexcolor = None    # Vx3 matrix of RGB colour values at each vertex.
    facecolor = None       # Fx3 matrix of RGB colour values of the faces.
    texturecoords = None   # Tx2 matrix of UV texture coordinates of the vertices.
    textureindices = None  # Fx3 matrix of triplets of texture coordinates.
    sourcefile = None      # String holding the mesh file name.
    texturefile = None     # String holding the texture file name.
    default_neighbourhood_order = 10  # Vertex neighbourhood order for (ao.) mesh parameterisation.
    # `set.default_neighbourhood_order` resets the `parameters`.
    verbose = None         # % Not stored with mesh, but useful for debugging and testing.

    def __init__(self, vertices, faces, varargin):
        p = argparse.ArgumentParser()
        p.add_argument()
        return

    def load_bnt(sourcefile, wrlfile):
        try:
            f = open(sourcefile, "rb")
            nrows = struct.unpack("H", f.read(2))[0]
            ncols = struct.unpack("H", f.read(2))[0]
            zmin = struct.unpack("d", f.read(8))[0]
            print(" " + str(nrows) + " " + str(ncols) + " " + str(zmin))
            length = struct.unpack("H", f.read(2))[0]
            imfile = []
            imfilename = ""
            for i in range(length):
                imfile.append(struct.unpack("c", f.read(1))[0])
                imfilename += imfile[i].decode('UTF-8')
            print("\nImage File: " + imfilename)
            # normally, size of data must be nrows * ncols * 5
            size = int(struct.unpack("I", f.read(4))[0] / 5)
            if size != nrows * ncols:
                print("Uncoherent header: The size of the matrix is incorrect")

            data = {"x": [], "y": [], "z": [], "a": [], "b": [], "flag": []}
            for key in ["x", "y", "z", "a", "b"]:
                for i in range(nrows):
                    # the range image is stored upsidedown in the .bnt file
                    # |LL LR|              |UL UR|
                    # |UL UR|  instead of  |LL LR|
                    # As we dont want to use the insert function or compute
                    # the destination of each value, we reverse the lines
                    # |LR LL|
                    # |UR UL|
                    # and then reverse the whole list
                    # |UL UR|
                    # |LL LR|
                    row = []
                    for j in range(ncols):
                        row.append(struct.unpack("d", f.read(8))[0])
                    row.reverse()
                    data[key].extend(row)
            f.close()

        except:
            print("Error while reading " + sourcefile)

        # reverse list
        data["x"].reverse()
        data["y"].reverse()
        data["z"].reverse()
        data["a"].reverse()
        data["b"].reverse()

        # we determine the flag for each pixel
        for i in range(size):
            if data["z"][i] == zmin:
                data["x"][i] = -0.000000
                data["y"][i] = -0.000000
                data["z"][i] = -0.000000
                data["flag"].append(0)
            else:
                data["flag"].append(1)

        # Write the abs file
        wrlfile = open(wrlfile, "w")
        wrlfile.write('#VRML V2.0 utf8\n')
        wrlfile.write('DEF _CVSSP_object Transform {\n')
        wrlfile.write('  children [\n');
        wrlfile.write('    Shape {\n');
        wrlfile.write(str(nrows) + " rows\n")
        wrlfile.write(str(ncols) + " columns\n")
        wrlfile.write("pixels (flag X Y Z):\n")
        wrlfile.write(" ".join(map(str, data["flag"])) + "\n")
        wrlfile.write(" ".join(map(str, data["x"])) + "\n")
        wrlfile.write(" ".join(map(str, data["y"])) + "\n")
        wrlfile.write(" ".join(map(str, data["z"])) + "\n")
        wrlfile.close()

    if __name__ == "__main__":
        load_bnt("c:\\data\\bosphorus\\source\\BosphorusDB\\bs000\\bs000_CAU_A22A25_0.bnt", "c:\\data\\test.wrl")

