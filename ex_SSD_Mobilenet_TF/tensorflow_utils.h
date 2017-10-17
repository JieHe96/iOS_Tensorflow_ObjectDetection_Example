// Copyright 2015 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef TENSORFLOW_CONTRIB_IOS_EXAMPLES_CAMERA_TENSORFLOW_UTILS_H_
#define TENSORFLOW_CONTRIB_IOS_EXAMPLES_CAMERA_TENSORFLOW_UTILS_H_

#import <UIKit/UIKit.h>
#include "tensorflow/cc/ops/const_op.h"
#include "tensorflow/core/public/session.h"

NSString* FilePathForResourceName(NSString* name, NSString* extension);
// Takes a text file with a single label on each line, and returns a list.
tensorflow::Status LoadLabels(NSString* file_name, NSString* file_type,
                              std::vector<std::string>* label_strings);

// runModel from hard disk
int runModel(NSString* file_name, NSString* file_type,
             void ** image_data, int *width, int *height, int *channels,
             std::vector<float>& boxScore,
             std::vector<float>& boxRect,
             std::vector<std::string>& boxName);

// runModel from memory
int runModel(UIImage* image,
             void ** image_data, int *width, int *height, int *channels,
             std::vector<float>& boxScore,
             std::vector<float>& boxRect,
             std::vector<std::string>& boxName);
#endif  // TENSORFLOW_CONTRIB_IOS_EXAMPLES_CAMERA_TENSORFLOW_UTILS_H_
