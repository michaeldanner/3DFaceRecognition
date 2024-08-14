import numpy as np
import math
from PIL import Image
import sys
import random


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


def normal_pattern(tvi, vertices, img_size, show_bar=False):

    counter = 1
    tvi_len = len(tvi) + 2

    # Find min and max value for x,y coordinates
    minimum = []
    maximum = []
    for element in vertices:
        minimum.append(min(element))
        maximum.append(max(element))
    print("Minimum: " + str(min(minimum)) + " - Maximum: " + str(max(maximum)))
    original_size = max(maximum) - min(minimum)
    min_value = min(minimum)
    ratio = original_size / img_size
    print("Original size: " + str(original_size) + " - Image size: " + str(img_size) + " - Ratio: " + str(ratio))

    imx = np.zeros([img_size + 20, img_size + 20]) + min_value
    imy = np.zeros([img_size + 20, img_size + 20]) + min_value
    imz = np.zeros([img_size + 20, img_size + 20]) + min_value

    min_x = 0
    min_y = 0
    min_z = 0

    for triangle in tvi[::1]:
        if show_bar:
            # printing a progress bar
            sys.stdout.write('\r')
            sys.stdout.write("[%-60s] %d%%" % ('=' * int(counter * 60 / tvi_len), counter * 100 / tvi_len))
            sys.stdout.flush()
            counter += 1

        try:
            x = [(vertices[triangle[0]][0]), (vertices[triangle[1]][0]), (vertices[triangle[2]][0])]
            y = [(vertices[triangle[0]][1]), (vertices[triangle[1]][1]), (vertices[triangle[2]][1])]
            z = [(vertices[triangle[0]][2]), (vertices[triangle[1]][2]), (vertices[triangle[2]][2])]
        except IndexError:
            print("IndexError: list index out of range")
            print(triangle)

        # x[0], z[0] = rotate(4, x[0], z[0])
        # x[1], z[1] = rotate(4, x[1], z[1])
        # x[2], z[2] = rotate(4, x[2], z[2])

        v1 = [x[2] - x[0], y[2] - y[0], z[2] - z[0]]
        v2 = [x[1] - x[0], y[1] - y[0], z[1] - z[0]]
        len1 = (math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2]))
        len2 = (math.sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2]))

        len1 = (len1 / ratio)
        len2 = (len2 / ratio)

        cross = [v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]]
        len_cross = math.sqrt(cross[0] * cross[0] + cross[1] * cross[1] + cross[2] * cross[2])

        for a in range(0, int(len1+1)):
            for b in range(0, int(len2+1)):
                if a / len1 + b / len2 <= 1.0:
                    mx = int((x[0] + a / len1 * v1[0] + b / len2 * v2[0] - min_value) / ratio)
                    my = int((y[0] + a / len1 * v1[1] + b / len2 * v2[1] - min_value) / ratio)

                    if mx < img_size + 20 and my < img_size + 20:
                        # Determine the cross product of the two vectors:
                        if len_cross == 0:
                            imx[mx][my] = 0
                            imy[mx][my] = 0
                            imz[mx][my] = 0
                        else:
                            imx[mx][my] = (-cross[0] / len_cross)
                            imy[mx][my] = (-cross[1] / len_cross)
                            imz[mx][my] = (-cross[2] / len_cross)
                            # print(imy[mx, my])
                            # print("(" + str(mx) + "/" + str(my) + ")")
                            if imx[mx, my] < min_x:
                                min_x = imx[mx, my]
                            if imy[mx, my] < min_y:
                                min_y = imy[mx, my]
                            if imz[mx, my] < min_z:
                                min_z = imz[mx, my]
                    else:
                        print("Warning: out of range. Pixel skipped")
                        return None, None, None

    for x in range(img_size+20):
        for y in range(img_size+20):
            if imz[x, y] < min_z:
                imz[x, y] = min_z
            if imy[x, y] < min_y:
                imy[x, y] = min_y
            if imx[x, y] < min_x:
                imx[x, y] = min_x

    imx = imx - imx.min()
    imx = imx / imx.max() * 255

    imy = imy - imy.min()
    imy = imy / imy.max() * 255

    imz = imz - imz.min()
    imz = imz / imz.max() * 255

    ret_z = np.zeros((img_size, img_size))
    ret_x = np.zeros((img_size, img_size))
    ret_y = np.zeros((img_size, img_size))

    # imz[139, 125] = 0
    background_color = imz[1, 1]
    print()
    for px in range(1, img_size):
        for py in range(1, img_size):
            summe_z = 0
            summe_x = 0
            summe_y = 0
            if imz[px, py] == background_color:
                if px == 139 and py == 125:
                    print(str([px, py]) + " - color: " + str(imy[px, py]))

                for i in range(-1, 2):
                    for j in range(-1, 2):
                        summe_z += imz[px + i, py + j]
                        summe_x += imx[px + i, py + j]
                        summe_y += imy[px + i, py + j]

                ret_z[px, py] = (summe_z - imz[px, py]) / 8
                ret_x[px, py] = (summe_x - imx[px, py]) / 8
                ret_y[px, py] = (summe_y - imy[px, py]) / 8

            else:
                ret_x[px, py] = imx[px, py]
                ret_y[px, py] = imy[px, py]
                ret_z[px, py] = imz[px, py]

    #img = Image.fromarray(np.uint8(imz), 'L')

    return ret_x, ret_y, ret_z


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


def rotate(theta, x, y):
    return x * math.cos(theta) - y * math.sin(theta), y * math.cos(theta) + x * math.sin(theta)


if __name__ == "__main__":
    load_wrl('../data/180914075154ER.wrl')
    print("done")
