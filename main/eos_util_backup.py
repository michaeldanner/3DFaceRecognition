import numpy as np
import math
from PIL import Image
import sys


def load_wrl(sourcefile):
    """ Parse a WRL VRML V2.0 utf8 file
    :param sourcefile: filename of wrl file
    :return tvi: index of vertices
    :return vertices: x,y,z coordinates of vertices
    """
    fid = open(sourcefile, 'rt')
    point_block = False
    coord_block = False
    index_block = False
    texture_block = False
    point = ""
    coord = ""

    for line in fid:
        # Parsing wrl file for different blocks and save them to temp files
        if line.find("coord Coordinate {") > -1:
            coord_block = True
            texture_block = False

        if line.find("texCoord TextureCoordinate {") > -1:
            coord_block = False
            texture_block = True

        if coord_block:
            if line.find("point [") > -1:
                point_block = True
                index_block = False

            if line.find("coordIndex [") > -1:
                point_block = False
                index_block = True

            if point_block:
                point += line

            if index_block:
                coord += line

        if texture_block:
            # todo: future parsing texture block
            break

    fid.close()

    fid = open("tmp_point.txt", "w+")
    fid.write(point)
    fid.close()

    fid = open("tmp_coord.txt", "w+")
    fid.write(coord)
    fid.close()

    regexp = r"\s+([0-9.\-]+) ([0-9.\-]+) ([0-9.\-]+)"
    dt = [('x', np.float32), ('y', np.float32), ('z', np.float32)]
    data = np.fromregex("tmp_point.txt", regexp, dt)

    vertices = []
    for item in data:
        vertices.append(np.float32([item['x'], item['y'], item['z'], ]))

    regexp = r"\s+([0-9.\-]+) ([0-9.\-]+) ([0-9.\-]+) \-1,"
    dt = [('x', np.int32), ('y', np.int32), ('z', np.int32)]
    data = np.fromregex("tmp_coord.txt", regexp, dt)

    tvi = []
    for item in data:
        tvi.append(np.int32([item['x'], item['y'], item['z'], ]))

    return tvi, vertices


def normal_pattern(tvi, vertices, img_size):
    imx = np.zeros([img_size + 60, img_size + 60])
    imy = np.zeros([img_size + 60, img_size + 60])
    imz = np.zeros([img_size + 60, img_size + 60])
    counter = 1
    tvi_len = len(tvi) + 2

    # Find min and max value for x,y coordinates
    minimum = []
    maximum = []
    for element in vertices:
        minimum.append(min(element))
        maximum.append(max(element))
    print(min(minimum))
    print(max(maximum))
    original_size = max(maximum) - min(minimum)
    #ratio = img_size / original_size
    #print(ratio)

    for triangle in tvi[::1]:
        # printing a progress bar
        sys.stdout.write('\r')
        sys.stdout.write("[%-60s] %d%%" % ('=' * int(counter * 60 / tvi_len), counter * 100 / tvi_len))
        sys.stdout.flush()
        counter += 1

        x = [(vertices[triangle[0]][0]), (vertices[triangle[1]][0]), (vertices[triangle[2]][0])]
        y = [(vertices[triangle[0]][1]), (vertices[triangle[1]][1]), (vertices[triangle[2]][1])]
        z = [(vertices[triangle[0]][2]), (vertices[triangle[1]][2]), (vertices[triangle[2]][2])]

        v1 = [x[2] - x[0], y[2] - y[0], z[2] - z[0]]
        v2 = [x[1] - x[0], y[1] - y[0], z[1] - z[0]]
        len1 = (math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])) + 2
        len2 = (math.sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2])) + 2

        len1 = int(len1 * 1)
        len2 = int(len2 * 1)

        for a in range(0, len1):
            for b in range(0, len2):

                mx = x[0] + a / len1 * v1[0] + b / len2 * v2[0] + min(minimum)
                my = y[0] + a / len1 * v1[1] + b / len2 * v2[1] + min(minimum)

                mx = int(mx * 1)
                my = int(my * 1)

                # Determine the cross product of the two vectors:
                cross = [v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]]
                len_cross = math.sqrt(cross[0] * cross[0] + cross[1] * cross[1] + cross[2] * cross[2])
                if len_cross == 0:
                    imx[mx][my] = 0
                    imy[mx][my] = 0
                    imz[mx][my] = 0
                else:
                    imx[mx][my] = abs(-cross[0] / len_cross)
                    imy[mx][my] = abs(-cross[1] / len_cross)
                    imz[mx][my] = abs(-cross[2] / len_cross)

    #imx = imx - imx.min()
    imx = imx / imx.max() * 255

    #imy = imy - imy.min()
    imy = imy / imy.max() * 255

    #imz = imz - imz.min()
    imz = imz / imz.max() * 255
    #img = Image.fromarray(np.uint8(imz), 'L')

    return imx, imy, imz


def save_xyz_to_rgb(filename, imx, imy, imz, color=True):
    size = len(imx[0])
    rgbArray = np.zeros((size, size, 3), 'uint8')
    rgbArray[..., 2] = imx
    rgbArray[..., 0] = imy
    rgbArray[..., 1] = imz
    if color:
        img = Image.fromarray(rgbArray).rotate(90)
    else:
        img = Image.fromarray(rgbArray).convert('LA').rotate(90)
    img.save(filename)
    return img


def saveImage(filename, array):
    img = Image.fromarray(np.uint8(array), 'L').rotate(90)
    img.save(filename)
    return img


if __name__ == "__main__":
    load_wrl('../data/180914075154ER.wrl')
    print("done")
