# Tensorflow IOS SSDMobilenet Example

This example gives a demo of loading a SSDMobilenet model to the IOS platform and using it to do the object detection work.

## Introduciton

Recently Google released the Tensorflow Object Detection API which includes the selection of multiple models. However, the API does not contain a IOS version of implementation. Therefore, for this example, I wrote a IOS implementation of the object detection API, including the SSDMobilenet model. For this example, it maintains the same functionality as the python version of object detection API. Furthermore, the IOS code is derived from Google tensorflow ios_camera_example.

## Prerequisites


### Installing

#### Xcode
You’ll need Xcode 7.3 or later.

#### Tensorflow
Download the Google Tensorflow repository to local:
https://github.com/tensorflow/tensorflow

#### Bazel
If you don't have Bazel, please follow the Bazel's official installation process:
https://docs.bazel.build/versions/master/install.html

#### Example Download
Download this repository to local and put the directory into the tensorflow directory you just downloaded.

#### Graph Download
Follow the below instruction to download the ssd_mobilenet_v1 model:
https://github.com/tensorflow/models/blob/master/object_detection/g3doc/detection_model_zoo.md

### Build


