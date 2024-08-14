from PIL import Image
import scipy
from glob import glob
import numpy as np


class DataLoader():
    def __init__(self, dataset_name, img_res=(128, 128)):
        self.dataset_name = dataset_name
        self.img_res = img_res

    def load_data(self, batch_size=1, is_testing=False):
        data_type = "train" if not is_testing else "val"
        # path = glob('./datasets/%s/%s/*' % (self.dataset_name, data_type))
        path = glob(self.dataset_name + "/*")

        batch = np.random.choice(path, size=batch_size)

        imgs_A, imgs_B = [], []
        for img in batch:
            img = Image.open(img)
            w, h = img.size
            half_w = int(w/2)
            img_A = img.crop((0, 0, half_w, h))
            img_B = img.crop((half_w, 0, w, h))

            img_A = np.array(img_A.resize(self.img_res))
            img_B = np.array(img_B.resize(self.img_res))

            if not is_testing and np.random.random() > 0.5:
                    img_A = np.fliplr(img_A)
                    img_B = np.fliplr(img_B)

            imgs_A.append(img_A)
            imgs_B.append(img_B)

        imgs_A = np.array(imgs_A, list)/127.5 - 1.
        imgs_B = np.array(imgs_B, list)/127.5 - 1.

        return imgs_A, imgs_B

    def load_batch(self, batch_size=1, is_testing=False):
        data_type = "train" if not is_testing else "val"
        # path = glob('./datasets/%s/%s/*' % (self.dataset_name, data_type))
        path = glob(self.dataset_name + "/*")

        self.n_batches = int(len(path) / batch_size)

        for i in range(self.n_batches-1):
            batch = path[i*batch_size:(i+1)*batch_size]
            imgs_A, imgs_B = [], []
            for img in batch:
                img = Image.open(img).convert('RGB')

                w, h = img.size
                half_w = int(w/2)
                img_A = img.crop((0, 0, half_w, h))
                img_B = img.crop((half_w, 0, w, h))

                img_A = np.array(img_A.resize(self.img_res))
                img_B = np.array(img_B.resize(self.img_res))

                if not is_testing and np.random.random() > 0.5:
                        img_A = np.fliplr(img_A)
                        img_B = np.fliplr(img_B)

                imgs_A.append(img_A)
                imgs_B.append(img_B)

            imgs_A = np.array(imgs_A, list)/127.5 - 1.
            imgs_B = np.array(imgs_B, list)/127.5 - 1.

            yield imgs_A, imgs_B

    def load_img(self, path):
        img = Image.open(path)
        img = img.resize(self.img_res)
        img = img/127.5 - 1.
        return img[np.newaxis, :, :, :]