import os
import glob
from PIL import Image
import cv2

folder = 'C:\\Data\\bosphorus\\source\\BosphorusDB\\'
folderz = 'C:\\Data\\bosphorus\\source\\normal_x\\'
target = 'D:\\Projects\\surrey\\3d-face-recognition\\main\\discogan\\datasets\\face2nx\\train\\'
cnt = 0

for f in glob.glob(folder + "/bs*"):
    path, folder = os.path.split(f)
    fz = os.path.join(folderz, folder)
    # ft = os.path.join(target, folder)
    print(str(fz))
    for filename in glob.glob(f + "/*.png"):
        path, file = os.path.split(filename)
        file_z = os.path.join(fz, file)
        file_target = os.path.join(target, file)
        if not ("_color.png" in filename or "_grey.png" in filename
                or "_x.png" in filename or "_y.png" in filename or "_z.png" in filename):
            print(str(file_target))
            cnt += 1

            img_a = cv2.imread(filename)
            img_b = cv2.imread(file_z)
            gray = cv2.cvtColor(img_b, cv2.COLOR_BGR2GRAY)
            _, thresh = cv2.threshold(gray, 1, 255, cv2.THRESH_BINARY)
            contours, hierarchy = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
            cnt = contours[0]
            x, y, w, h = cv2.boundingRect(cnt)
            if w > 50:

                # print("Image dimension: " + str(w) + ", " + str(h))
                crop = img_b[y:y + h, x:x + w]
                try:
                    w_min = min(im.shape[0] for im in [img_a, img_b])
                    im_list_resize = [cv2.resize(im, (w_min, w_min), interpolation=cv2.INTER_CUBIC)
                                      for im in [img_a, crop]]
                    # cv2.imshow('test', im_list_resize[0])
                    img = cv2.hconcat(im_list_resize)
                    cv2.imwrite(file_target, img)
                    # cv2.imshow('test', img)
                    # cv2.waitKey()
                except AttributeError as error:
                    print("AttributeError: " + str(error))
