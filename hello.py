from __future__ import absolute_import, division, print_function, unicode_literals
import tensorflow as tf
import tensorflow_hub as hub
from tensorflow.keras import layers
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Conv2D, Flatten, Dropout, MaxPooling2D
import pathlib
import os
import matplotlib.pyplot as plt
import scipy.ndimage as ndimage
import numpy as np

BATCH_SIZE = 32
IMG_HEIGHT = 224
IMG_WIDTH = 224


def random_rotate_image(image):
    image = ndimage.rotate(image, np.random.uniform(-30, 30), reshape=False)
    return image


def tf_random_rotate_image(image, label):
    im_shape = image.shape
    [image,] = tf.py_function(random_rotate_image, [image], [tf.float32])
    image.set_shape(im_shape)
    return image, label


def get_label(file_path):
    # convert the path to a list of path components
    parts = tf.strings.split(file_path, os.path.sep)
    # The second to last is the class-directory
    return parts[-2] == CLASS_NAMES


def process_path(file_path):
    label = get_label(file_path)
    # load the raw data from the file as a string
    img = tf.io.read_file(file_path)
    img = decode_img(img)
    return img, label


# Reads an image from a file, decodes it into a dense tensor, and resizes it to a fixed shape.
def parse_image(filename):
    parts = tf.strings.split(file_path, os.sep)
    label = parts[-2]
    image = tf.io.read_file(filename)
    image = tf.image.decode_jpeg(image)
    image = tf.image.convert_image_dtype(image, tf.float32)
    image = tf.image.resize(image, [IMG_HEIGHT, IMG_WIDTH])
    return image, label


def show(image, label):
    plt.figure()
    plt.imshow(image)
    plt.title(label.numpy().decode('utf-8'))
    plt.axis('off')


def prepare_for_training(ds, cache=True, shuffle_buffer_size=1000):
    # This is a small dataset, only load it once, and keep it in memory.
    # use `.cache(filename)` to cache preprocessing work for datasets that don't
    # fit in memory.
    if cache:
        if isinstance(cache, str):
            ds = ds.cache(cache)
        else:
            ds = ds.cache()
    ds = ds.shuffle(buffer_size=shuffle_buffer_size)
    # Repeat forever
    ds = ds.repeat()
    ds = ds.batch(BATCH_SIZE)
    # `prefetch` lets the dataset fetch batches in the background while the model
    # is training.
    ds = ds.prefetch(buffer_size=tf.data.experimental.AUTOTUNE)
    return ds


def show_batch(image_batch, label_batch):
    plt.figure(figsize=(10,10))
    for n in range(25):
        ax = plt.subplot(5,5,n+1)
        plt.imshow(image_batch[n])
        plt.title(CLASS_NAMES[label_batch[n]==1][0].title())
        plt.axis('off')


def decode_img(img):
    # convert the compressed string to a 3D uint8 tensor
    img = tf.image.decode_jpeg(img, channels=3)
    # Use `convert_image_dtype` to convert to floats in the [0,1] range.
    img = tf.image.convert_image_dtype(img, tf.float32)
    # resize the image to the desired size.
    return tf.image.resize(img, [IMG_WIDTH, IMG_HEIGHT])


# Use tf.data to batch and shuffle the dataset:
bosphorus_root = "C:\\Data\\Attractive\\classes\\"
bosphorus_root = pathlib.Path(bosphorus_root)
for item in bosphorus_root.glob("*"):
    print(item.name)


list_ds = tf.data.Dataset.list_files(str(bosphorus_root/'*/*'))
image_count = len(list(bosphorus_root.glob('*/*.jpg')))
print("\nNumber of images: " + str(image_count))

CLASS_NAMES = np.array([item.name for item in bosphorus_root.glob('*') if item.name != "LICENSE.txt"])
print("\nClass names: " + str(CLASS_NAMES))

file_path = next(iter(list_ds))
image, label = parse_image(file_path)

images_ds = list_ds.map(parse_image)
labeled_ds = list_ds.map(process_path, num_parallel_calls=tf.data.experimental.AUTOTUNE)
train_ds = prepare_for_training(labeled_ds, cache="./bosph.tfcache")
image_batch, label_batch = next(iter(labeled_ds))
#show_batch(image_batch.numpy(), label_batch.numpy())

eval_root = "C:\\Data\\Attractive\\eval\\"
eval_root = pathlib.Path(eval_root)
list_ds = tf.data.Dataset.list_files(str(eval_root/'*/*'))
image_count = len(list(eval_root.glob('*/*.jpg')))
print("\nNumber of evaluation images: " + str(image_count))
eval_ds = list_ds.map(process_path, num_parallel_calls=tf.data.experimental.AUTOTUNE)
eval_ds = prepare_for_training(eval_ds, cache="./eval.tfcache")
# bosphorus_train_ds = tf.data.Dataset.from_tensor_slices((images, labels))
# bosphorus_train_ds = bosphorus_train_ds.shuffle(5000).batch(32)

#rot_ds = images_ds.map(tf_random_rotate_image)

'''
for image, label in rot_ds.take(3):
    show(image, label)

for f in list_ds.take(5):
    print(f.numpy())

labeled_ds = list_ds.map(process_path)
for image_raw, label_text in labeled_ds.take(10):
    print(repr(image_raw.numpy()[:100]))
    print()
    print(label_text.numpy())


'''

feature_extractor_url = "https://tfhub.dev/google/tf2-preview/mobilenet_v2/feature_vector/2" #@param {type:"string"}
feature_extractor_layer = hub.KerasLayer(feature_extractor_url, input_shape=(IMG_HEIGHT,IMG_WIDTH,3))
feature_batch = feature_extractor_layer(image_batch)
feature_extractor_layer.trainable = False

model = tf.keras.Sequential([
  feature_extractor_layer,
  layers.Dense(image_data.num_classes, activation='softmax')
])


# Build the tf.keras.Sequential model by stacking layers. Choose an optimizer and loss function for training:
# model = tf.keras.Sequential([
#     Conv2D(16, 3, padding='same', activation='relu', input_shape=(IMG_HEIGHT, IMG_WIDTH, 3)),
#     MaxPooling2D(),
#     Conv2D(32, 3, padding='same', activation='relu'),
#     MaxPooling2D(),
#     Conv2D(64, 3, padding='same', activation='relu'),
#     MaxPooling2D(),
#     Flatten(),
#     Dense(512, activation='relu'),
#     Dense(1, activation='sigmoid')
#     #Dense(1, activation='softmax')
# ])

model.compile(optimizer='adam', loss='categorical_crossentropy', metrics=['accuracy'])

history = model.fit(train_ds, steps_per_epoch=250, epochs=5, validation_data=eval_ds, validation_steps=100)

#model.evaluate(x_test,  y_test, verbose=2)
loss, accuracy = model.evaluate(train_ds, steps=100)
print("Loss :", loss)
print("Accuracy :", accuracy)

acc = history.history['accuracy']
val_acc = history.history['val_accuracy']

loss = history.history['loss']
val_loss = history.history['val_loss']

epochs_range = range(5)

plt.figure(figsize=(8, 8))
plt.subplot(1, 2, 1)
plt.plot(epochs_range, acc, label='Training Accuracy')
plt.plot(epochs_range, val_acc, label='Validation Accuracy')
plt.legend(loc='lower right')
plt.title('Training and Validation Accuracy')

plt.subplot(1, 2, 2)
plt.plot(epochs_range, loss, label='Training Loss')
plt.plot(epochs_range, val_loss, label='Validation Loss')
plt.legend(loc='upper right')
plt.title('Training and Validation Loss')
plt.show()
