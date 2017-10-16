# Tensorflow iOS ObjectDetection Example

This example gives a demo of loading a Object Detection model to the iOS platform and using it to do the object detection work. The currently supported models are: <a href="http://download.tensorflow.org/models/object_detection/ssd_mobilenet_v1_coco_11_06_2017.tar.gz">ssd_mobilenet_v1_coco</a>, <a href="http://download.tensorflow.org/models/object_detection/ssd_inception_v2_coco_11_06_2017.tar.gz">ssd_inception_v2_coco</a>, <a href="http://download.tensorflow.org/models/object_detection/faster_rcnn_resnet101_coco_11_06_2017.tar.gz">faster_rcnn_resnet101_coco</a>.

## Quick Start
  #### 1.Setup Environment Variable in Terminal
  First open the terminal, type in the following command:
  ```
  export TF_ROOT=/Users/Your User Id/Downloads/tensorflow-master(root)/
  ```
  Then cd to the example folder and check your tensroflow version and the correctness of your tensorflow root path:
  ```
  cd /Users/Your User Id/Downloads/iOS_Tensorflow_ObjectDetection_Example-master/config/
  bash config.sh
  ```
  The config.sh file will automatically check your TensorFlow version and copy some files that are necessary for the compile process.
  After running the config.sh, if the terminal show the following result then you are good for next step:
  ```
  ok=> current version: # Release 1.4.0
  ok=> Ready!
  ```
  Otherwise, please go to the TensorFlow official website and download the latest version of TensorFlow.
  #### 2.Compile dependencies
  Compile ios dependencies:
  ```
  cd $TF_ROOT
  sudo sh tensorflow/contrib/makefile/build_all_ios_ssd.sh
  ```
  #### 3.Setup project in Xcode
  Open the project in Xcode
  Then in the "tf_root.xcconfig" replace the TF_ROOT with your tensorflow root's absolute path.
  Finally, add the "op_inference_graph.pb" to your project folder.
  #### 4.Build & Run the project
  Note: If you'd like to run other two models, download it from the above links and add the .ph file to your project.
  #### 5.Other Model Resource
  For other model file, please check my another <a href="https://github.com/JieHe96/tf_resource">repo</a>.
  
  
## Result running on iOS device
![alt text](https://github.com/JieHe96/iOS_Tensorflow_ObjectDetection_Example/blob/master/iphone_result.png)
![alt text](https://github.com/JieHe96/ios_SSDMobilenet_tensorflow_example/blob/master/ios_result.png)

## Update content for TensorFlow 1.4.0
After updating the TensorFlow to version 1.4.0, I did the following change to make sure the example could run successfully:
1. Follow the steps in the new QuickStart section
2. If you've tryed the previous version of this example before, then you need to re-compile the libtensorflow.a, otherwise many register will not able to be found:
```
cd $TF_ROOT
rm -r tensorflow/contrib/makefile/gen/lib/ tensorflow/contrib/makefile/gen/obj/
tensorflow/contrib/makefile/build_tflib_ssd.sh
```
3. In the iOS project, add the new header search, and also make sure you use the right $(TF_ROOT) in the header search:
```
$(TF_ROOT)/tensorflow/contrib/makefile/downloads/nsync/public/
```
4. In the iOS project, add the new lib search:
```
$(TF_ROOT)/tensorflow/contrib/makefile/gen/nsync
```
5. In the Makefile_ios, comment out the line:
```
TF_CC_SRCS += tensorflow/core/platform/default/gpu_tracer.cc
```

## Below content is the detailed explanation and FAQs of this example
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
#### 4.Repository Download
Download this repository to local and put the directory into the tensorflow directory you just downloaded.
#### 5.Graph Download
Follow the below instruction to download the model you want:
https://github.com/tensorflow/models/blob/master/object_detection/g3doc/detection_model_zoo.md
We only need the graph file, aka .pb file (We chose SSDMobilenet as example):
```
frozen_inference_graph.pb
```
Then download the label file for the model you chose:
https://github.com/tensorflow/models/tree/master/object_detection/data
```
mscoco_label_map.pbtxt
```

### Build
#### 1.Build Bazel
Before you could run the project, you need to build some bazel depedicies by following the Google instruction:
If this is your first time build Bazel, please follow the below link to configure the installation:
https://www.tensorflow.org/install/install_sources#configure_the_installation
##### Optional:
If you'd like to get the info of graph's input/output name, using the following command:
```
bazel build tensorflow/tools/graph_transforms:summarize_graph
bazel-bin/tensorflow/tools/graph_transforms/summarize_graph --in_graph=YOUR_GRAPH_PATH/example_graph.pb
```

#### 2.Change Makefile
The Makefile is under "tensorflow/contrib/makefile/".
  - In the Makefile, first delete the line "-D__ANDROID_TYPES_SLIM__ \" under "# Settings for iOS." for all "$(IOS_ARCH)".
  
#### 3.Generate ops_to_register.h
One of the biggest issues during iOS Tensorflow building is the missing of different OpKernel. One may get similar errors like below:
```
Invalid argument: No OpKernel was registered to support Op 'Equal' with these attrs.  Registered devices: [CPU], Registered kernels:
  <no registered kernels>
```
In order to solve the problems in one time, we use Bazel to generate a ops_to_register.h, which contains all the needed Ops to loading the certain graph into project. An example of command-line usage is:
```
  bazel build tensorflow/python/tools:print_selective_registration_header 
  bazel-bin/tensorflow/python/tools/print_selective_registration_header \
    --graphs=path/to/graph.pb > ops_to_register.h
```
This will generate a ops_to_register.h file in the current directory. Copy the file to "tensorflow/core/framework/". Then when compiling tensorflow, pass -DSELECTIVE_REGISTRATION and -DSUPPORT_SELECTIVE_REGISTRATION 
See tensorflow/core/framework/selective_registration.h for more details.
##### Attention:
For different models, you also need to provide certain ops_to_register.h file that fits the model. Therefore, if you'd like to contain several models in one project, you need to first generate a ops_to_register.h for each different model, then merge all the ops_to_register.h into one file. By doing the operation, you could use different models in one project without compiling the Tensorflow lib separately.

In this example, we provided a combined ops_to_register.h file which is compatible with ssd_mobilenet_v1_coco and ssd_inception_v2_coco  and faster_rcnn_resnet101_coco.

#### 4.Build Tensorflow iOS library
Instead of using build_all_ios for the building process, we divide the process into several steps:
  - In tensorflow/contrib/makefile/compile_ios_protobuf.sh, add the line
  ```
  export MACOSX_DEPLOYMENT_TARGET="10.10"
  ```
  after
  ```
  set -x
  set -e
  ```
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
  tensorflow/contrib/makefile/compile_ios_tensorflow.sh "-O3  -DANDROID_TYPES=ANDROID_TYPES_FULL -DSELECTIVE_REGISTRATION -DSUPPORT_SELECTIVE_REGISTRATION"
  ```
  If you'd like to shorten the building time, you could choose to build the "compile_ios_tensorflow_s.sh" file provided in the repository. The "complie_ios_tensorflow_s.sh" only complie two IOS_ARCH: ARM64 and x86_64, which make the building process much shorter. Make sure to copy the file to the "tensorflow/contrib/makefile/" directory before building. Then the build command is changed to:
  ```
  tensorflow/contrib/makefile/compile_ios_tensorflow_s.sh "-O3  -DANDROID_TYPES=ANDROID_TYPES_FULL -DSELECTIVE_REGISTRATION -DSUPPORT_SELECTIVE_REGISTRATION"
  ```
  
  Make sure the script has generated the following .a files:
  ```
  tensorflow/contrib/makefile/gen/lib/libtensorflow-core.a
  tensorflow/contrib/makefile/gen/protobuf_ios/lib/libprotobuf.a
  tensorflow/contrib/makefile/gen/protobuf_ios/lib/libprotobuf-lite.a
  ```
#### 5.Xocde Configuration
  - Open xcode example, put the model and label file you just downloaded into "TF_Graph" folder in the project
  - Follow the link for configuration:
  https://github.com/tensorflow/tensorflow/tree/master/tensorflow/examples/ios#creating-your-own-app-from-your-source-libraries
  (ps: you need to contain a absolute path of "libtensorflow-core.a" after the "-force_load" option)
  
### Running
Before you run, make sure to recompile the libtensorflow-core.a according to the modified Makefile. Otherwise, following error may be generated during the runtime:
```
Error adding graph to session:
No OpKernel was registered to support Op 'Less' with these attrs.  
Registered devices: [CPU],     Registered kernels: device='CPU';
 T in [DT_FLOAT]......
 ```
Once you finish the above process, you could run the project by click the build button in the Xcode

### Label Config
In order to get the lable name for each detected box, you have to use proto buffer data structure. In the SSDMobilenet model, the label file is stored as a proto buffer structure, so that you need to proto's own function to extract the data. 

To use proto buffer, first install it by 
```
brew install protobuf
```
Then follow https://developers.google.com/protocol-buffers/docs/cpptutorial to compile the proto buffer.
After the compiling, you'll get a .h and a .cc files which contain the declaration and implementation of your classes.
```
example.pb.h
example.pn.cc
```
Finally you could use the funcition in the files to extract your label data.

### FAQ
  1. If you still get errors like after finishing the above instruction:
  ```
  Invalid argument: No OpKernel was registered to support Op 'xxx' with these attrs.  Registered devices: [CPU], Registered kernels:
  <no registered kernels>
  ```
  - Solution: First check if you use the certain ops_to_register.h for the model you choose.
  Then check the file "tensorflow/contrib/makefile/tf_op_files.txt" and add the "tensorflow/core/kernels/cwise_op_xxx.cc" into the txt file if it is not in there.
  
  2. Make sure you've added the  "-O3  -DANDROID_TYPES=ANDROID_TYPES_FULL -DSELECTIVE_REGISTRATION -DSUPPORT_SELECTIVE_REGISTRATION" when run the "compile_ios_tensorflow_s.sh".
  

  3. Invalid argument: No OpKernel was registered to support Op 'Conv2D' with these attrs. Registered devices: [CPU], Registered kernels:
  ```
   [[Node: FeatureExtractor/InceptionV2/InceptionV2/Conv2d_1a_7x7/separable_conv2d = Conv2D[T=DT_FLOAT, data_format="NHWC", padding="VALID", strides=[1, 1, 1, 1], use_cudnn_on_gpu=true](FeatureExtractor/InceptionV2/InceptionV2/Conv2d_1a_7x7/separable_conv2d/depthwise, FeatureExtractor/InceptionV2/Conv2d_1a_7x7/pointwise_weights/read)]]
  ```
  - Solution: Because of the special structure of models, they include the GEMM function in the conv layers. However, the default Makefile does not use the GEMM for conv layer, so that you need to munually replace the line in the ops_to_register.h. In your ops_to_register.h replace the line "Conv2DOp<CPUDevice, float>" with "Conv2DUsingGemmOp< float, Im2ColConvFunctor<float, float, float, FastGemmFunctor<float, float, float>>>" and the problem will be solved.
