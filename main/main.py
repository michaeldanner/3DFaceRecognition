import eos
import eos_util
import numpy as np
from PIL import Image


def main():
    """Demo for running the eos fitting from Python."""
    landmarks = read_pts('../data/image_0010.pts')
    landmarks = read_pts('K:\\CASIA-lms\\0000524\\035.pts')
    landmarks = read_pts('K:\\CASIA-lms\\0000532\\085.pts')

    image_width = 1280  # Make sure to adjust these when using your own images!
    image_height = 1024

    model = eos.morphablemodel.load_model("../share/sfm_shape_3448.bin")
    blendshapes = eos.morphablemodel.load_blendshapes("../share/expression_blendshapes_3448.bin")
    # Create a MorphableModel with expressions from the loaded neutral model and blendshapes:
    morphablemodel_with_expressions = eos.morphablemodel.MorphableModel(model.get_shape_model(), blendshapes,
                                                                        color_model=eos.morphablemodel.PcaModel(),
                                                                        vertex_definitions=None,
                                                                        texture_coordinates=model.get_texture_coordinates())
    landmark_mapper = eos.core.LandmarkMapper('../share/ibug_to_sfm.txt')
    edge_topology = eos.morphablemodel.load_edge_topology('../share/sfm_3448_edge_topology.json')
    contour_landmarks = eos.fitting.ContourLandmarks.load('../share/ibug_to_sfm.txt')
    model_contour = eos.fitting.ModelContour.load('../share/sfm_model_contours.json')

    (mesh, pose, shape_coeffs, blendshape_coeffs) = eos.fitting.fit_shape_and_pose(morphablemodel_with_expressions,
                                                                                   landmarks, landmark_mapper,
                                                                                   image_width, image_height,
                                                                                   edge_topology, contour_landmarks,
                                                                                   model_contour)

    # print("EOS.Render:")
    # print(dir(eos.render))
    # print(dir(eos.core))
    # obj = eos.core.read_obj("../data/180914075154ER.wrl")
    # print(obj.tvi)
#
    # print("a:")
    # verts = eos_util.load_wrl("../data/180914075154ER.wrl")
    # obj.vertices = eos_util.load_wrl('../data/180914075154ER.wrl')
    # print(verts)
    # Now you can use your favourite plotting/rendering library to display the fitted mesh, using the rendering
    # parameters in the 'pose' variable.

    # Or for example extract the texture map, like this:
    # import cv2
    # image = cv2.imread('../data/image_0010.png')
    # isomap = eos.render.extract_texture(mesh, pose, image)

    print("\npose:")
    print(mesh.tvi)
    print(mesh.vertices)

    x_normal, y_normal, z_normal = eos_util.normal_pattern(mesh.tvi, mesh.vertices, 400)
    img = Image.fromarray(np.uint8(y_normal), 'L').rotate(90)
    img.show()
    img.save('c:\\data\\test.png', 'PNG')
'''
    imx = np.zeros([240, 240])
    imy = np.zeros([240, 240])
    imz = np.zeros([240, 240])

    #fig = plt.figure()
    #ax = plt.axes(projection="3d")

    mymesh = mesh.tvi
    myverts = mesh.vertices

    for triangle in mymesh[::1]:
        x = [(myverts[triangle[0]][0]), (myverts[triangle[1]][0]), (myverts[triangle[2]][0])]
        y = [(myverts[triangle[0]][1]), (myverts[triangle[1]][1]), (myverts[triangle[2]][1])]
        z = [(myverts[triangle[0]][2]), (myverts[triangle[1]][2]), (myverts[triangle[2]][2])]
        v1 = [x[2] - x[0], y[2] - y[0], z[2] - z[0]]
        v2 = [x[1] - x[0], y[1] - y[0], z[1] - z[0]]
        len1 = int(math.sqrt(v1[0] * v1[0] + v1[1] * v1[1] + v1[2] * v1[2])) + 2
        len2 = int(math.sqrt(v2[0] * v2[0] + v2[1] * v2[1] + v2[2] * v2[2])) + 2
        for a in range(0, len1):
            for b in range(0, len2):
                mx = x[0] + a / len1 * v1[0] + b / len2 * v2[0]
                my = y[0] + a / len1 * v1[1] + b / len2 * v2[1]

                # Determine the cross product of the two vectors:
                cross = [v1[1] * v2[2] - v1[2] * v2[1], v1[2] * v2[0] - v1[0] * v2[2], v1[0] * v2[1] - v1[1] * v2[0]]
                len_cross = math.sqrt(cross[0] * cross[0] + cross[1] * cross[1] + cross[2] * cross[2])
                imx[int(mx) + 120][int(my) + 120] = -cross[0] / len_cross
                imy[int(mx) + 120][int(my) + 120] = -cross[1] / len_cross
                imz[int(mx) + 120][int(my) + 120] = -cross[2] / len_cross

        # print("x: " + str(int(mesh.vertices[triangle[0]][0])+120)
        # + " - y: " + str(int(mesh.vertices[triangle[0]][1])+120) + " - z: " + str(cross[2]*(-20)))
        #ax.plot_trisurf(x, y, z, color='green')

    # fig = go.Figure(data=pose)
    # fig.show()
    imx = imx - imx.min()
    imx = imx / imx.max() * 255
    img = Image.fromarray(np.uint8(imx), 'L')
    #img.show()

    imy = imy - imy.min()
    imy = imy / imy.max() * 255
    img = Image.fromarray(np.uint8(imy), 'L')
    #img.show()

    imz = imz - imz.min()
    imz = imz / imz.max() * 255
    img = Image.fromarray(np.uint8(imz), 'L')
    #img.show()

    rgbArray = np.zeros((240, 240, 3), 'uint8')
    rgbArray[..., 2] = imx
    rgbArray[..., 0] = imy
    rgbArray[..., 1] = imz

    img = Image.fromarray(rgbArray).convert('LA')
'''



def read_pts(filename):
    """A helper function to read the 68 ibug landmarks from a .pts file."""
    lines = open(filename).read().splitlines()
    lines = lines[3:71]

    landmarks = []
    ibug_index = 1  # count from 1 to 68 for all ibug landmarks
    for l in lines:
        coords = l.split()
        landmarks.append(eos.core.Landmark(str(ibug_index), [float(coords[0]), float(coords[1])]))
        ibug_index = ibug_index + 1

    return landmarks


if __name__ == "__main__":
    main()
