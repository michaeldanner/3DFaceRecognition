from main import eos_util
import glob
import os
import multiprocessing


def calculate_save(tvi, vertices, target_x, target_y, target_z, path, file):
    x_normal, y_normal, z_normal = eos_util.normal_pattern(tvi, vertices, 500)
    # x_normal, y_normal, z_normal = eos_util.normal_pattern(tvi, vertices, 120)

    if x_normal is not None:
        eos_util.saveImage(target_x + path + os.sep + file + ".png", x_normal)
        eos_util.saveImage(target_y + path + os.sep + file + ".png", y_normal)
        eos_util.saveImage(target_z + path + os.sep + file + ".png", z_normal)

def convertImage(folder, target):
    target_x = target + os.sep + "normal_x" + os.sep
    target_y = target + os.sep + "normal_y" + os.sep
    target_z = target + os.sep + "normal_z" + os.sep
    target_color = target + os.sep + "normal_color" + os.sep
    target_grey = target + os.sep + "normal_grey" + os.sep

    if not os.path.exists(target_x):
        os.makedirs(target_x)
    if not os.path.exists(target_y):
        os.makedirs(target_y)
    if not os.path.exists(target_z):
        os.makedirs(target_z)
    if not os.path.exists(target_color):
        os.makedirs(target_color)
    if not os.path.exists(target_grey):
        os.makedirs(target_grey)

    process = []

    for f in glob.glob(folder + "/bs*"):
        print(str(f))

        for filename in glob.glob(f + "/*.wrl"):
            tvi, vertices = eos_util.load_wrl(filename)
            filename, extension = os.path.splitext(filename)
            path, file = os.path.split(filename)
            print(str(filename))
            path = path[-5:]
            if not os.path.exists(target_x + path):
                os.makedirs(target_x + path)
            if not os.path.exists(target_y + path):
                os.makedirs(target_y + path)
            if not os.path.exists(target_z + path):
                os.makedirs(target_z + path)
            if not os.path.exists(target_color + path):
                os.makedirs(target_color + path)
            if not os.path.exists(target_grey + path):
                os.makedirs(target_grey + path)

            p = multiprocessing.Process(target=calculate_save,
                                        args=(tvi, vertices, target_x, target_y, target_z, path, file,))
            process.append(p)
            p.start()

            # eos_util.save_xyz_to_rgb(target_color + path + os.sep + file + ".png", x_normal, y_normal, z_normal, True)
            # eos_util.save_xyz_to_rgb(target_grey + path + os.sep + file + ".png", x_normal, y_normal, z_normal, False)


if __name__ == "__main__":
    print("Start.......\n")
    # folder = 'C:\\Data\\jnu3d\\registered'
    f = 'C:\\Data\\bosphorus\\source\\BosphorusDB\\'
    t = "C:\\Data\\bosphorus\\source\\"
    convertImage(f, t)
