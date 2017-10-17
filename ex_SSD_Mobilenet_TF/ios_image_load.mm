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

#include "ios_image_load.h"

#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

#import <UIKit/UIImage.h>
#import <UIKit/UIFont.h>
#import <UIKit/NSStringDrawing.h>
#import <UIKit/UIGraphics.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>

using tensorflow::uint8;

std::vector<uint8> LoadImageFromFile(const char* file_name,
				     int* out_width, int* out_height,
				     int* out_channels) {
  FILE* file_handle = fopen(file_name, "rb");
  fseek(file_handle, 0, SEEK_END);
  const size_t bytes_in_file = ftell(file_handle);
  fseek(file_handle, 0, SEEK_SET);
  std::vector<uint8> file_data(bytes_in_file);
  fread(file_data.data(), 1, bytes_in_file, file_handle);
  fclose(file_handle);
  CFDataRef file_data_ref = CFDataCreateWithBytesNoCopy(NULL, file_data.data(),
						      bytes_in_file,
						      kCFAllocatorNull);
  CGDataProviderRef image_provider =
    CGDataProviderCreateWithCFData(file_data_ref);

  const char* suffix = strrchr(file_name, '.');
  if (!suffix || suffix == file_name) {
    suffix = "";
  }
  CGImageRef image;
  if (strcasecmp(suffix, ".png") == 0) {
    image = CGImageCreateWithPNGDataProvider(image_provider, NULL, true,
					     kCGRenderingIntentDefault);
  } else if ((strcasecmp(suffix, ".jpg") == 0) ||
    (strcasecmp(suffix, ".jpeg") == 0)) {
    image = CGImageCreateWithJPEGDataProvider(image_provider, NULL, true,
					      kCGRenderingIntentDefault);
  } else {
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    fprintf(stderr, "Unknown suffix for file '%s'\n", file_name);
    *out_width = 0;
    *out_height = 0;
    *out_channels = 0;
    return std::vector<uint8>();
  }

  const int width = (int)CGImageGetWidth(image);
  const int height = (int)CGImageGetHeight(image);
  const int channels = 4;
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
  const int bytes_per_row = (width * channels);
  const int bytes_in_image = (bytes_per_row * height);
  std::vector<uint8> result(bytes_in_image);
  const int bits_per_component = 8;
  CGContextRef context = CGBitmapContextCreate(result.data(), width, height,
    bits_per_component, bytes_per_row, color_space,
    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(color_space);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  CGContextRelease(context);
  CFRelease(image);
  CFRelease(image_provider);
  CFRelease(file_data_ref);

  *out_width = width;
  *out_height = height;
  *out_channels = channels;
  return result;
}

int LoadImageFromUIImageAndScale(UIImage* iosimage,
                          int& out_width, int& out_height, int& out_channels,
                          int scale_width, int scale_height,
                          std::vector<uint8> * original_image,
                          std::vector<uint8> * scale_image
                          ) {
    CGImageRef image=iosimage.CGImage;
    out_width = (int)CGImageGetWidth(image);
    out_height = (int)CGImageGetHeight(image);
    
    int width = scale_width;//(int)CGImageGetWidth(image);
    int height = scale_height;//(int)CGImageGetHeight(image);
    int channels = 4;
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    int bytes_per_row = (width * channels);
    int bytes_in_image = (bytes_per_row * height);
    scale_image->resize(bytes_in_image);
    //std::vector<uint8> result(bytes_in_image);
    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(scale_image->data(), width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, scale_width, scale_height), image);
    
    CGContextRelease(context);
    
    width = out_width;//(int)CGImageGetWidth(image);
    height = out_height;//(int)CGImageGetHeight(image);
    bytes_per_row = (width * channels);
    bytes_in_image = (bytes_per_row * height);
    original_image->resize(bytes_in_image);
    
    context = CGBitmapContextCreate(original_image->data(), width, height,
                                    bits_per_component, bytes_per_row, color_space,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    CGContextRelease(context);
    CFRelease(image);
    out_channels = channels;
    return 0;
}

int
LoadImageFromFileAndScale(const char* file_name,
                          int& out_width, int& out_height, int& out_channels,
                          int scale_width, int scale_height,
                          std::vector<uint8> * original_image,
                          std::vector<uint8> * scale_image
                          ) {
    FILE* file_handle = fopen(file_name, "rb");
    fseek(file_handle, 0, SEEK_END);
    const size_t bytes_in_file = ftell(file_handle);
    fseek(file_handle, 0, SEEK_SET);
    std::vector<uint8> file_data(bytes_in_file);
    fread(file_data.data(), 1, bytes_in_file, file_handle);
    fclose(file_handle);
    CFDataRef file_data_ref = CFDataCreateWithBytesNoCopy(NULL, file_data.data(),
                                                          bytes_in_file,
                                                          kCFAllocatorNull);
    CGDataProviderRef image_provider =
    CGDataProviderCreateWithCFData(file_data_ref);
    
    const char* suffix = strrchr(file_name, '.');
    if (!suffix || suffix == file_name) {
        suffix = "";
    }
    CGImageRef image;
    if (strcasecmp(suffix, ".png") == 0) {
        image = CGImageCreateWithPNGDataProvider(image_provider, NULL, true,
                                                 kCGRenderingIntentDefault);
    } else if ((strcasecmp(suffix, ".jpg") == 0) ||
               (strcasecmp(suffix, ".jpeg") == 0)) {
        image = CGImageCreateWithJPEGDataProvider(image_provider, NULL, true,
                                                  kCGRenderingIntentDefault);
    } else {
        CFRelease(image_provider);
        CFRelease(file_data_ref);
        fprintf(stderr, "Unknown suffix for file '%s'\n", file_name);
        out_width = 0;
        out_height = 0;
        out_channels = 0;
        return -1;
    }
    
    out_width = (int)CGImageGetWidth(image);
    out_height = (int)CGImageGetHeight(image);
    
    int width = scale_width;//(int)CGImageGetWidth(image);
    int height = scale_height;//(int)CGImageGetHeight(image);
    int channels = 4;
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    int bytes_per_row = (width * channels);
    int bytes_in_image = (bytes_per_row * height);
    scale_image->resize(bytes_in_image);
    //std::vector<uint8> result(bytes_in_image);
    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(scale_image->data(), width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, scale_width, scale_height), image);
    
    CGContextRelease(context);
    
    width = out_width;//(int)CGImageGetWidth(image);
    height = out_height;//(int)CGImageGetHeight(image);
    bytes_per_row = (width * channels);
    bytes_in_image = (bytes_per_row * height);
    original_image->resize(bytes_in_image);
    //std::vector<uint8> result(bytes_in_image);
    
    context = CGBitmapContextCreate(original_image->data(), width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    CGContextSetInterpolationQuality(context, kCGInterpolationLow);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
    
    CGContextRelease(context);
    
    
    CFRelease(image);
    CFRelease(image_provider);
    CFRelease(file_data_ref);
    
    out_channels = channels;
    return 0;
}
UIImage* drawText(UIImage* image);

int SaveImageFromRawData(std::string file_name, void * image_data, int width, int height, int channels)
{
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    int bytes_per_row = (width * channels);
    //int bytes_in_image = (bytes_per_row * height);

    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(image_data, width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);

    //if no transform, the text will be rotated
    CGAffineTransform normalState=CGContextGetCTM(context);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    
    UIGraphicsPushContext(context);
    //draw text
    NSString *text1 = @"person";
    UIColor *textColor =[UIColor colorWithRed:0.99f green:0.99f blue:0.99f alpha:1.0f];
    UIFont *helveticaBold = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f];
    NSDictionary *dicAttribute = @{NSFontAttributeName:helveticaBold, NSForegroundColorAttributeName:textColor};
    CGRect textRect = CGRectMake(100, 120, 100, 200);
    [text1  drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin
                 attributes:dicAttribute context:nil];

    //draw rect
    CGContextSetRGBStrokeColor(context, 0.5, 0.5, 0.5, 0.5);
    CGContextSetLineWidth(context, 2.0);
    CGContextAddRect(context, CGRectMake(100, 100, 270, 270));
    CGContextStrokePath(context);
    
    
    UIGraphicsPopContext();

    CGContextConcatCTM(context, normalState);
    
    CGImageRef toCGImage = CGBitmapContextCreateImage(context);
    UIImage * uiimage = [[UIImage alloc] initWithCGImage:toCGImage];
    
    
    NSData * png = UIImagePNGRepresentation(uiimage);
    NSString *file_str=[NSString stringWithCString:file_name.c_str() encoding:[NSString defaultCStringEncoding]];

    [png writeToFile: file_str atomically:YES];

    CGContextRelease(context);
    CFRelease(toCGImage);

    return 0;
}


UIImage* drawText(UIImage* image)
{
    NSString *text1 = @"person";
    //UIFont *font = [UIFont boldSystemFontOfSize:12];
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)]; //image.size.
    UIColor *textColor =[UIColor colorWithRed:0.5f green:0.0f blue:0.5f alpha:1.0f];
    //  UIColor *textColor = [UIColor redColor];
    
    UIFont *helveticaBold = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f];
    //  UIFont *helveticaBold = [UIFont boldSystemFontOfSize:30];
    
    NSDictionary *dicAttribute = @{
                                   NSFontAttributeName:helveticaBold,
                                   NSForegroundColorAttributeName:textColor
                                   };
    CGRect textRect = CGRectMake(100, 120, 100, 200);
    [text1  drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin
              attributes:dicAttribute context:nil];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}
