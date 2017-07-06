# Tensorflow iOS SSDMobilenet Example

This example gives a demo of loading a SSDMobilenet model to the iOS platform and using it to do the object detection work.

## Introduciton

Recently Google released the Tensorflow Object Detection API which includes the selection of multiple models. However, the API does not contain a iOS version of implementation. Therefore, in this example, I wrote a IOS implementation of the object detection API, including the SSDMobilenet model. For this example, it maintains the same functionality as the python version of object detection API. Furthermore, the IOS code is derived from Google tensorflow ios_camera_example.

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
You should get a model file and a label file:
```
frozen_inference_graph.pb
graph.pbtxt
```

### Build
#### 1.Build Bazel
Before you could run the project, you need to build some bazel depedicies by following the Google instruction:
If this is your first time build Bazel, please follow the below link to configure the installation:
https://www.tensorflow.org/install/install_sources#configure_the_installation

Get into your tensorflow root directory then run this command:
```
$ bazel build --config opt tensorflow/examples/multibox_detector/...
```
(ps: It may take some time for the build process complete.)

After the build process complete, a "bazel-genfiles" folder will be created in the tensorflow root. Copy the following files to "tensorflow/cc/ops/":
```
bazel-genfiles/tensorflow/cc/ops/math_ops.cc
bazel-genfiles/tensorflow/cc/ops/nn_ops.cc
bazel-genfiles/tensorflow/cc/ops/math_ops.h
bazel-genfiles/tensorflow/cc/ops/nn_ops.h
```
#### 2.Change Makefile
The Makefile is under "tensorflow/contrib/makefile/".
  - In the Makefile, first delete the line "-D__ANDROID_TYPES_SLIM__ \" under "# Settings for iOS." for all "$(IOS_ARCH)".
  - Add the following source files into Makefile before the line "ifdef HEXAGON_LIBS":
  ```
  TF_CC_SRCS += \
  tensorflow/cc/framework/scope.cc \
  tensorflow/cc/framework/ops.cc \
  tensorflow/cc/ops/const_op.cc \
  tensorflow/cc/ops/math_ops.cc \
  tensorflow/cc/ops/nn_ops.cc
  ```  
#### 3.Build Tensorflow iOS library
  - Download the dependencies:
  ```
  tensorflow/contrib/makefile/download_dependencies.sh
  ```
  - Next, you will need to compile protobufs for iOS:
  ```
  tensorflow/contrib/makefile/compile_ios_protobuf.sh 
  ```
  - Then create the libtensorflow-core.a:
  ```
  tensorflow/contrib/makefile/compile_ios_tensorflow.sh "-O3  -DANDROID_TYPES=ANDROID_TYPES_FULL"
  ```
  Make sure the script has generated the following .a files:
  ```
  tensorflow/contrib/makefile/gen/lib/libtensorflow-core.a
  tensorflow/contrib/makefile/gen/protobuf_ios/lib/libprotobuf.a
  tensorflow/contrib/makefile/gen/protobuf_ios/lib/libprotobuf-lite.a
  ```
#### 4.Xocde Configuration
  - Open xcode example, put the model and label file you just downloaded into "TF_Graph" folder in the project
  - Follow the link for configuration:
  https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/ios#creating-your-own-app-from-your-source-libraries
  (ps: you need to contain a absolute path of "libtensorflow-core.a" after the "-force_load" option)
  - After finished the above steps, add one more Header Search path named "(your tensorflow root path)/bazel_genfiles/"
  
### Running
Before you run, make sure to recompile the libtensorflow-core.a according to the modified Makefile. Otherwise, following error may be generated during the runtime:
```
Error adding graph to session:
No OpKernel was registered to support Op 'Less' with these attrs.  
Registered devices: [CPU],     Registered kernels: device='CPU';
 T in [DT_FLOAT]......
 ```
Once you finish the above process, you could run the project by click the build button in the Xcode

### Result
ios_SSDMobilenet_tensorflow_example/ios_result.png
