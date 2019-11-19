from __future__ import absolute_import, division, print_function, unicode_literals
import mxnet as mx
import argparse
import io
import numpy as np
import tensorflow as tf
import os
import pathlib

IMG_HEIGHT = 224
IMG_WIDTH = 224

def parse_args():
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='data path information'
    )
    parser.add_argument('--bin_path', default='dataset/faces_emore/train.rec', type=str,
                        help='path to the binary image file')
    parser.add_argument('--idx_path', default='dataset/faces_emore/train.idx', type=str,
                        help='path to the image index path')
    parser.add_argument('--tfrecords_file_path', default='converted_dataset', type=str,
                        help='path to the output of tfrecords file path')
    args = parser.parse_args()
    return args


def mx2tfrecords(imgidx, imgrec, args):
    output_path = os.path.join(args.tfrecords_file_path, 'ms1m_train.tfrecord')
    writer = tf.data.experimental.TFRecordWriter(output_path)

    def generator():
        for i in imgidx:
            img_info = imgrec.read_idx(i)
            header, img = mx.recordio.unpack(img_info)
            label = int(header.label)
            example = tf.train.Example(features=tf.train.Features(feature={
                'image_raw': tf.train.Feature(bytes_list=tf.train.BytesList(value=[img])),
                "label": tf.train.Feature(int64_list=tf.train.Int64List(value=[label]))
            }))
            yield example.SerializeToString()
        # serialized_features_dataset.take(example.SerializeToString())
            if i % 10000 == 0:
                print('%d num image processed' % i)
    serialized_features_dataset = tf.data.Dataset.from_generator(
        generator, output_types=tf.string, output_shapes=())
    writer.write(serialized_features_dataset)  # Serialize To String


def original():
    # # define parameters
    id2range = {}
    data_shape = (3, 112, 112)
    args = parse_args()
    print("Unpacking mxnet dataset...")
    imgrec = mx.recordio.MXIndexedRecordIO(args.idx_path, args.bin_path, 'r')
    s = imgrec.read_idx(0)
    header, _ = mx.recordio.unpack(s)
    print(header.label)
    imgidx = list(range(1, int(header.label[0])))
    seq_identity = range(int(header.label[0]), int(header.label[1]))
    for identity in seq_identity:
        s = imgrec.read_idx(identity)
        header, _ = mx.recordio.unpack(s)
        a, b = int(header.label[0]), int(header.label[1])
        id2range[identity] = (a, b)
    print('id2range', len(id2range))

    print("Done.")

    # # generate tfrecords
    print("Generating Tensorflow Dataset...")
    mx2tfrecords(imgidx, imgrec, args)
    print("Done.")


def _bytes_feature(value):
    """Returns a bytes_list from a string / byte."""
    if isinstance(value, type(tf.constant(0))):
        value = value.numpy() # BytesList won't unpack a string from an EagerTensor.
    return tf.train.Feature(bytes_list=tf.train.BytesList(value=[value]))


def _int64_feature(value):
    """Returns an int64_list from a bool / enum / int / uint."""
    return tf.train.Feature(int64_list=tf.train.Int64List(value=[value]))


# Reads an image from a file, decodes it into a dense tensor, and resizes it to a fixed shape.
def parse_image(filename):
    # print(str(filename))
    parts = tf.strings.split(filename, os.sep)
    label = parts[-2]
    image = tf.io.read_file(filename)
    image_shape = tf.image.decode_jpeg(image).shape
    # print(str(image_shape))
    feature = {
        'height': _int64_feature(image_shape[0]),
        'width': _int64_feature(image_shape[1]),
        'depth': _int64_feature(image_shape[2]),
        'label': _int64_feature(label),
        'image_raw': _bytes_feature(image),
    }
    return tf.train.Example(features=tf.train.Features(feature=feature))


if __name__ == '__main__':
    # Use tf.data to batch and shuffle the dataset:
    dataset_root = "C:\\Data\\Attractive\\classes\\"
    dataset_root = pathlib.Path(dataset_root)
    for item in dataset_root.glob("*"):
        print(item.name)

    list_ds = tf.data.Dataset.list_files(str(dataset_root / '*/*'))
    image_count = len(list(dataset_root.glob('*/*.jpg')))
    print("\nNumber of images: " + str(image_count))

    CLASS_NAMES = np.array([item.name for item in dataset_root.glob('*') if item.name != "LICENSE.txt"])
    print("\nClass names: " + str(CLASS_NAMES))

    file_path = next(iter(list_ds))
    #  labeled_ds = list_ds.map(parse_image)
    # for f in list_ds:
    #     text = f.numpy().decode("utf-8")
    #     if str(text).endswith('jpg'):
    #         for line in str(parse_image(f)).split('\n')[:1]:
    #            print(line)

    output_path = 'femaleface_train.tfrecord'
    with tf.io.TFRecordWriter(output_path) as writer:
        for f in list_ds:
            text = f.numpy().decode("utf-8")
            if str(text).endswith('jpg'):
                # image_string = open(filename, 'rb').read()
                tf_example = parse_image(f)
                writer.write(tf_example.SerializeToString())

    if(0):
        output_path = 'femaleface_train.tfrecord'
        writer = tf.data.experimental.TFRecordWriter(output_path)

        def generator():
            for image, label in labeled_ds:
                example = tf.train.Example(features=tf.train.Features(feature={
                    'image_raw': tf.train.Feature(bytes_list=tf.train.BytesList(value=[image])),
                    "label": tf.train.Feature(int64_list=tf.train.Int64List(value=[label]))
                }))
            yield example.SerializeToString()

        serialized_features_dataset = tf.data.Dataset.from_generator(
            generator, output_types=tf.string, output_shapes=())
        writer.write(serialized_features_dataset)  # Serialize To String