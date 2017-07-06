# Tensorflow IOS SSDMobilenet Example

This example gives a demo of loading a SSDMobilenet model to the IOS platform and using it to do the object detection work.

## Introduciton

Recently Google released the Tensorflow Object Detection API which includes the selection of multiple models. However, the API does not contain a IOS version of implementation. Therefore, for this example, I wrote a IOS implementation of the object detection API, including the SSDMobilenet model. For this example, it maintains the same functionality as the python version of object detection API. Furthermore, the IOS code is derived from Google tensorflow ios_camera_example.

## Prerequisites


### Installing
#### 1.Xcode
You’ll need Xcode 7.3 or later.
#### 2.Tensorflow
Download the Google Tensorflow repository to local:
https://github.com/tensorflow/tensorflow
#### 3.Bazel
If you don't have Bazel, please follow the Bazel's official installation process:
https://docs.bazel.build/versions/master/install.html
#### 4.Example Download
Download this repository to local and put the directory into the tensorflow directory you just downloaded.
#### 5.Graph Download
Follow the below instruction to download the ssd_mobilenet_v1 model:
https://github.com/tensorflow/models/blob/master/object_detection/g3doc/detection_model_zoo.md

### Build
#### 1.Build Bazel
Before you could run the project, you need to build some bazel depedicies by following the Google instruction:
If this is your first time build Bazel, please follow the below link to configure the installation:
https://www.tensorflow.org/install/install_sources#configure_the_installation

Get into your tensorflow root directory then run this command:
```
$ bazel build --config opt tensorflow/examples/multibox_detector/...
```
After the build process complete, a "bazel-genfiles" folder will be created in the tensorflow root. Copy the following files to "tensorflow/cc/ops/":
```
bazel-genfiles/tensorflow/cc/ops/math_ops.cc
bazel-genfiles/tensorflow/cc/ops/nn_ops.cc
bazel-genfiles/tensorflow/cc/ops/math_ops.h
bazel-genfiles/tensorflow/cc/ops/nn_ops.h
```
