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

#import <Foundation/Foundation.h>

#include "tensorflow_utils.h"
#include "ios_image_load.h"


using tensorflow::Tensor;
using tensorflow::Status;
using tensorflow::string;
using tensorflow::int32;
using tensorflow::uint8;

#include <pthread.h>
#include <unistd.h>
#include <fstream>
#include <queue>
#include <sstream>
#include <string>

NSString* FilePathForResourceName(NSString* name, NSString* extension) {
    NSString* file_path =
    [[NSBundle mainBundle] pathForResource:name ofType:extension];
    if (file_path == NULL) {
        LOG(FATAL) << "Couldn't find '" << [name UTF8String] << "."
        << [extension UTF8String] << "' in bundle.";
        return nullptr;
    }
    return file_path;
}

tensorflow::Status LoadLabels(NSString* file_name, NSString* file_type,
                              std::vector<std::string>* label_strings) {
  // Read the label list
  NSString* labels_path = FilePathForResourceName(file_name, file_type);
  if (!labels_path) {
    LOG(ERROR) << "Failed to find model proto at" << [file_name UTF8String]
               << [file_type UTF8String];
    return tensorflow::errors::NotFound([file_name UTF8String],
                                        [file_type UTF8String]);
  }
  std::ifstream t;
  t.open([labels_path UTF8String]);
  std::string line;
  while (t) {
    std::getline(t, line);
    label_strings->push_back(line);
  }
  t.close();
  return tensorflow::Status::OK();
}



// Takes a file name, and loads a list of comma-separated box priors from it,
// one per line, and returns a vector of the values.
Status ReadLocationsFile(const string& file_name, std::vector<float>* result,
                         size_t* found_label_count) {
    std::ifstream file(file_name);
    if (!file) {
        return tensorflow::errors::NotFound("Labels file ", file_name,
                                            " not found.");
    }
    result->clear();
    string line;
    while (std::getline(file, line)) {
        std::vector<float> tokens;
        CHECK(tensorflow::str_util::SplitAndParseAsFloats(line, ',', &tokens));
        for (auto number : tokens) {
            result->push_back(number);
        }
    }
    *found_label_count = result->size();
    return Status::OK();
}

// Given an image file name, read in the data, try to decode it as an image,
// resize it to the requested size, and then scale the values as desired.
Status ReadTensorFromImageFile(const string& file_name, const int input_height, const int input_width,
                               int *width, int *height, int *channels,
                               const float input_mean, const float input_std,
                               std::vector<Tensor>* out_tensors) {
    
    const int wanted_channels = 3;
    
    std::vector<tensorflow::uint8> original_image_data;
    std::vector<tensorflow::uint8> image_data;
    
    int image_width, image_height, image_channels;
    int ret = LoadImageFromFileAndScale(file_name.c_str(), image_width, image_height, image_channels,
                                        input_width, input_height,
                                        &original_image_data, &image_data);
    
    *width = image_width; *height = image_height; *channels = image_channels;
    assert(image_channels >= wanted_channels && ret == 0);
    
    tensorflow::Tensor resized_tensor(
                                      tensorflow::DT_FLOAT,
                                      tensorflow::TensorShape({1, input_height, input_width, wanted_channels}));
    auto image_tensor_mapped = resized_tensor.tensor<float, 4>();
    
    //change scaled image data to float and normalize
    tensorflow::uint8* in = image_data.data();
    float* out = image_tensor_mapped.data();
    for (int y = 0; y < input_height; ++y) {
        tensorflow::uint8* in_row = in + (y * input_width * image_channels);
        float* out_row = out + (y * input_width * wanted_channels);
        for (int x = 0; x < input_width; ++x) {
            tensorflow::uint8* in_pixel = in_row + (x * image_channels);
            float* out_pixel = out_row + (x * wanted_channels);
            for (int c = 0; c < wanted_channels; ++c) {
                out_pixel[c] = ((float)in_pixel[c] - input_mean) / input_std;
            }
        }
    }
#if 0
    tensorflow::Tensor image_tensors_org(
                                         tensorflow::DT_UINT8,
                                         tensorflow::TensorShape({1, image_height, image_width, image_channels}));
    
    auto image_tensor_org_mapped = image_tensors_org.tensor<uint8, 4>();
    memcpy(image_tensor_org_mapped.data(), original_image_data.data(), image_height*image_width*image_channels);

    out_tensors->push_back(resized_tensor);
    out_tensors->push_back(image_tensors_org);
#else

    tensorflow::Tensor image_tensors_org(
                                         tensorflow::DT_UINT8,
                                         tensorflow::TensorShape({1, image_height, image_width, wanted_channels}));
    
    auto image_tensor_org_mapped = image_tensors_org.tensor<uint8, 4>();
    //memcpy(image_tensor_org_mapped.data(), original_image_data.data(), image_height*image_width*image_channels);
    

    in = original_image_data.data();
    uint8* c_out = image_tensor_org_mapped.data();
    for (int y = 0; y < image_height; ++y) {
        tensorflow::uint8* in_row = in + (y * image_width * image_channels);
        uint8* out_row = c_out + (y * image_width * wanted_channels);
        for (int x = 0; x < image_width; ++x) {
            tensorflow::uint8* in_pixel = in_row + (x * image_channels);
            uint8* out_pixel = out_row + (x * wanted_channels);
            for (int c = 0; c < wanted_channels; ++c) {
                out_pixel[c] = in_pixel[c];
            }
        }
    }

    tensorflow::Tensor image_tensors_org4(
                                         tensorflow::DT_UINT8,
                                         tensorflow::TensorShape({1, image_height, image_width, image_channels}));
    
    auto image_tensor_org4_mapped = image_tensors_org4.tensor<uint8, 4>();
    memcpy(image_tensor_org4_mapped.data(), original_image_data.data(), image_height*image_width*image_channels);
    
    out_tensors->push_back(resized_tensor);
    out_tensors->push_back(image_tensors_org);
    out_tensors->push_back(image_tensors_org4);

#endif
    
    
    
    
    
    return Status::OK();
}

// Reads a model graph definition from disk, and creates a session object you
// can use to run it.
Status LoadGraph(const string& graph_file_name,
                 std::unique_ptr<tensorflow::Session>* session) {
    tensorflow::GraphDef graph_def;
    Status load_graph_status =
    ReadBinaryProto(tensorflow::Env::Default(), graph_file_name, &graph_def);
    if (!load_graph_status.ok()) {
        return tensorflow::errors::NotFound("Failed to load compute graph at '",
                                            graph_file_name, "'");
    }
    session->reset(tensorflow::NewSession(tensorflow::SessionOptions()));
    Status session_create_status = (*session)->Create(graph_def);
    if (!session_create_status.ok()) {
        return session_create_status;
    }
    return Status::OK();
}

// Analyzes the output of the MultiBox graph to retrieve the highest scores and
// their positions in the tensor, which correspond to individual box detections.
Status GetTopDetections(const std::vector<Tensor>& outputs, int how_many_labels,
                        Tensor* indices, Tensor* scores) {
    auto root = tensorflow::Scope::NewRootScope();
    using namespace ::tensorflow::ops;  // NOLINT(build/namespaces)
    
    string output_name = "top_k";
    TopK(root.WithOpName(output_name), outputs[0], how_many_labels);
    // This runs the GraphDef network definition that we've just constructed, and
    // returns the results in the output tensors.
    tensorflow::GraphDef graph;
    TF_RETURN_IF_ERROR(root.ToGraphDef(&graph));
    
    std::unique_ptr<tensorflow::Session> session(
                                                 tensorflow::NewSession(tensorflow::SessionOptions()));
    TF_RETURN_IF_ERROR(session->Create(graph));
    // The TopK node returns two outputs, the scores and their original indices,
    // so we have to append :0 and :1 to specify them both.
    std::vector<Tensor> out_tensors;
    TF_RETURN_IF_ERROR(session->Run({}, {output_name + ":0", output_name + ":1"},
                                    {}, &out_tensors));
    *scores = out_tensors[0];
    *indices = out_tensors[1];
    return Status::OK();
}

// Converts an encoded location to an actual box placement with the provided
// box priors.
void DecodeLocation(const float* encoded_location, const float* box_priors,
                    float* decoded_location) {
    bool non_zero = false;
    for (int i = 0; i < 4; ++i) {
        const float curr_encoding = encoded_location[i];
        non_zero = non_zero || curr_encoding != 0.0f;
        
        const float mean = box_priors[i * 2];
        const float std_dev = box_priors[i * 2 + 1];
        
        float currentLocation = curr_encoding * std_dev + mean;
        
        currentLocation = std::max(currentLocation, 0.0f);
        currentLocation = std::min(currentLocation, 1.0f);
        decoded_location[i] = currentLocation;
    }
    
    if (!non_zero) {
        LOG(WARNING) << "No non-zero encodings; check log for inference errors.";
    }
}

float DecodeScore(float encoded_score) { return 1 / (1 + exp(-encoded_score)); }

void DrawBox(const int image_width, const int image_height, int left, int top,
             int right, int bottom, tensorflow::TTypes<uint8>::Flat* image) {
    tensorflow::TTypes<uint8>::Flat image_ref = *image;
    
    top = std::max(0, std::min(image_height - 1, top));
    bottom = std::max(0, std::min(image_height - 1, bottom));
    
    left = std::max(0, std::min(image_width - 1, left));
    right = std::max(0, std::min(image_width - 1, right));
    
    int image_channels = 4;
    for (int i = 0; i < 3; ++i) {
        uint8 val = i == 2 ? 255 : 0;
        for (int x = left; x <= right; ++x) {
            image_ref((top * image_width + x) * image_channels + i) = val;
            image_ref((bottom * image_width + x) * image_channels + i) = val;
        }
        for (int y = top; y <= bottom; ++y) {
            image_ref((y * image_width + left) * image_channels + i) = val;
            image_ref((y * image_width + right) * image_channels + i) = val;
        }
    }
}

// Given the output of a model run, and the name of a file containing the labels
// this prints out the top five highest-scoring values.
Status PrintTopDetections(const std::vector<Tensor>& outputs,
                          const string& labels_file_name,
                          const int num_boxes,
                          const int num_detections,
                          const string& image_file_name,
                          Tensor* original_tensor) {
    std::vector<float> locations;
    size_t label_count;
    Status read_labels_status =
    ReadLocationsFile(labels_file_name, &locations, &label_count);
    if (!read_labels_status.ok()) {
        LOG(ERROR) << read_labels_status;
        return read_labels_status;
    }
    CHECK_EQ(label_count, num_boxes * 8);
    
    const int how_many_labels =
    std::min(num_detections, static_cast<int>(label_count));
    Tensor indices;
    Tensor scores;
    TF_RETURN_IF_ERROR(
                       GetTopDetections(outputs, how_many_labels, &indices, &scores));
    
    tensorflow::TTypes<float>::Flat scores_flat = scores.flat<float>();
    
    tensorflow::TTypes<int32>::Flat indices_flat = indices.flat<int32>();
    
    const Tensor& encoded_locations = outputs[1];
    auto locations_encoded = encoded_locations.flat<float>();

    LOG(INFO) << original_tensor->DebugString();
    const int image_width = (int)original_tensor->shape().dim_size(2);
    const int image_height = (int)original_tensor->shape().dim_size(1);
    
    tensorflow::TTypes<uint8>::Flat image_flat = original_tensor->flat<uint8>();

    LOG(INFO) << "===== Top " << how_many_labels << " Detections ======";
    for (int pos = 0; pos < how_many_labels; ++pos) {
        const int label_index = indices_flat(pos);
        const float score = scores_flat(pos);
        
        float decoded_location[4];
        DecodeLocation(&locations_encoded(label_index * 4),
                       &locations[label_index * 8], decoded_location);
        
        float left = decoded_location[0] * image_width;
        float top = decoded_location[1] * image_height;
        float right = decoded_location[2] * image_width;
        float bottom = decoded_location[3] * image_height;
        
        LOG(INFO) << "Detection " << pos << ": "
        << "L:" << left << " "
        << "T:" << top << " "
        << "R:" << right << " "
        << "B:" << bottom << " "
        << "(" << label_index << ") score: " << DecodeScore(score);
        
        DrawBox(image_width, image_height, left, top, right, bottom, &image_flat);
    }
    
     if (!image_file_name.empty()) {
         SaveImageFromRawData(image_file_name, original_tensor->tensor<uint8, 4>().data(), image_width, image_height, 4);
     }
    return Status::OK();
}

Status PrintTopDetections(std::vector<Tensor>& outputs,
                          //const string& labels_file_name,
                          const int num_boxes,
                          const int num_detections,
                          const string& image_file_name,
                          Tensor* original_tensor) {
    std::vector<float> locations;
    //size_t label_count;

    
    //Tensor &indices = outputs;
    Tensor &scores = outputs[1];
    
    tensorflow::TTypes<float>::Flat scores_flat = scores.flat<float>();
    
    //tensorflow::TTypes<int32>::Flat indices_flat = indices.flat<int32>();
    
    const Tensor& encoded_locations = outputs[0];
    auto locations_encoded = encoded_locations.flat<float>();
    
    LOG(INFO) << original_tensor->DebugString();
    const int image_width = (int)original_tensor->shape().dim_size(2);
    const int image_height = (int)original_tensor->shape().dim_size(1);
    
    tensorflow::TTypes<uint8>::Flat image_flat = original_tensor->flat<uint8>();
    
    for (int pos = 0; pos < 20; ++pos) {
        //const int label_index = indices_flat(pos);
        const float score = scores_flat(pos);
        
        if (score < 0.5) break;
        
//        float decoded_location[4];
//        DecodeLocation(&locations_encoded(pos * 4),
//                       &locations[pos * 8], decoded_location);
        
        float left = locations_encoded(pos * 4 + 1) * image_width;
        float top = locations_encoded(pos * 4 + 0) * image_height;
        float right = locations_encoded(pos * 4 + 3) * image_width;
        float bottom = locations_encoded((pos * 4 + 2)) * image_height;
        
        LOG(INFO) << "Detection " << pos << ": "
        << "L:" << left << " "
        << "T:" << top << " "
        << "R:" << right << " "
        << "B:" << bottom << " "
        << "(" << pos << ") score: " << score;
        
        DrawBox(image_width, image_height, left, top, right, bottom, &image_flat);
    }
    
    if (!image_file_name.empty()) {
        //SaveImageFromRawData(image_file_name, original_tensor->tensor<uint8, 4>().data(), image_width, image_height, 4);
    }
    return Status::OK();
}

static NSString* model_file_name = @"frozen_inference_graph";//@"multibox_model";
static NSString* model_file_type = @"pb";

static NSString* image_file_name = @"image2";
static NSString* image_file_type = @"jpg";

// If you have your own model, point this to the labels file.
static NSString* labels_file_name = @"graph";//@"multibox_location_priors";
static NSString* labels_file_type = @"pbtxt";




int runModel(NSString* file_name, NSString* file_type,
             void ** image_data, int *width, int *height, int *channels) {
    string image_path = [FilePathForResourceName(file_name, file_type) UTF8String];
    string graph = [FilePathForResourceName(model_file_name, model_file_type) UTF8String];
    string box_priors = [FilePathForResourceName(labels_file_name, labels_file_type) UTF8String];

    int32 input_width = 224;
    int32 input_height = 224;
    int32 input_mean = 128;
    int32 input_std = 128;
    int32 num_detections = 30;
    int32 num_boxes = 784;
//    string input_layer = "ResizeBilinear";//"image_tensor";
//    string output_location_layer = "output_locations/Reshape";
//    string output_score_layer = "output_scores/Reshape";
//    string root_dir = "";
    string image_out = "/Users/hecaiguang/Desktop/ios_result.png";
    
    
    // First we load and initialize the model.
    std::unique_ptr<tensorflow::Session> session;
    //string graph_path = tensorflow::io::JoinPath(root_dir, graph);
    Status load_graph_status = LoadGraph(graph,
                                         &session);
    if (!load_graph_status.ok()) {
        LOG(ERROR) << load_graph_status;
        return -1;
    }

    int image_width;
    int image_height;
    int image_channels;
    //const int wanted_channels = 3;

    // Get the image from disk as a float array of numbers, resized and normalized
    // to the specifications the main graph expects.
    std::vector<Tensor> image_tensors;
    //string image_path = tensorflow::io::JoinPath(root_dir, image);
    
    Status read_tensor_status = ReadTensorFromImageFile(image_path, input_height, input_width,
                                                        &image_width, &image_height, &image_channels,
                                                        input_mean,input_std, &image_tensors);
    if (!read_tensor_status.ok()) {
        LOG(ERROR) << read_tensor_status;
        return -1;
    }
    const Tensor& resized_tensor = image_tensors[1];
    //for debug
    //string db_tensor0 = resized_tensor.DebugString();
    //string db_tensor1 = image_tensors[1].DebugString();

    
    
    // Actually run the image through the model.
    std::vector<Tensor> outputs;
    Status run_status =
//    session->Run({{input_layer, resized_tensor}},
//                 {output_score_layer, output_location_layer}, {}, &outputs);
    session->Run({{"image_tensor", resized_tensor}},
                 {"detection_boxes", "detection_scores", "detection_classes", "num_detections"}, {}, &outputs);
    if (!run_status.ok()) {
        LOG(ERROR) << "Running model failed: " << run_status;
        return -1;
    }
    
    
    tensorflow::TTypes<float>::Flat scores_flat = outputs[1].flat<float>();
    std::vector<float> v_scores;
    for(int i=0; i<10; i++)
        v_scores.push_back(scores_flat(i));
    
//    Status print_status = PrintTopDetections(outputs, box_priors, num_boxes, num_detections, image_out,
//                                             &image_tensors[1]);
    Status print_status = PrintTopDetections(outputs, num_boxes, num_detections, image_out,
                                             &image_tensors[2]);
    
    
    
    
    if (!print_status.ok()) {
        LOG(ERROR) << "Running print failed: " << print_status;
        return -1;
    }
    
    //SaveImageFromRawData(image_out, image_tensors[2].tensor<uint8, 4>().data(), image_width, image_height, 4);
    *image_data = malloc(image_width*image_height*image_channels+8192);
    memcpy(*image_data, image_tensors[2].tensor<uint8, 4>().data(), image_width*image_height*image_channels);
    //*image_data = image_tensors[2].tensor<uint8, 4>().data();
    *width = image_width;
    *height = image_height;
    *channels = image_channels;
    
    return 0;
}
