//
//  ViewController.m
//  ex_SSD_Mobilenet_TF
//
//

#import "ViewController.h"

#include "tensorflow_utils.h"


@interface ViewController ()
    
@end

@implementation ViewController

static NSString* image_file = @"image2.jpg";
static NSString* image_file_name = @"image2";
static NSString* image_file_type = @"jpg";

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    UIImage *image = [UIImage imageNamed:image_file];
    CGFloat imageView_X = (image.size.width > self.view.frame.size.width) ? self.view.frame.size.width : image.size.width;
    CGFloat imageView_Y = 0.0f;
    CGFloat origin;
    
    if(image.size.width > self.view.frame.size.width){
        origin = self.view.frame.size.width/image.size.width;
        imageView_Y = image.size.height*origin;
    }
    
    imgView = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-imageView_X)/2,
                                                                        (self.view.frame.size.height-imageView_Y)/2,
                                                                        imageView_X, imageView_Y)];
    
    
    [imgView setImage:image];
    imgView.contentMode =  UIViewContentModeScaleAspectFit;

    [self.view addSubview:imgView];
}


- (IBAction)runButton:(id)sender {
    [self.view willRemoveSubview:imgView];
    
    void * image_data = nullptr;
    int width;
    int height;
    int channels;
    
    int ret = runModel(image_file_name, image_file_type, &image_data, &width, &height, &channels);
    
    if (ret != 0 || image_data == NULL) return;
    
    //displaying running result
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    int bytes_per_row = (width * channels);
    
    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(image_data, width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    
    
    CGImageRef toCGImage = CGBitmapContextCreateImage(context);
    UIImage * image = [[UIImage alloc] initWithCGImage:toCGImage];

//    NSData * png = UIImagePNGRepresentation(image);
//    NSString *file_str=@"/Users/hecaiguang/Desktop/ios_result.png";//[NSString stringWithCString:image_out.c_str() encoding:[NSString defaultCStringEncoding]];
//    
//    [png writeToFile: file_str atomically:YES];
    
    CGFloat imageView_X = (image.size.width > self.view.frame.size.width) ? self.view.frame.size.width : image.size.width;
    CGFloat imageView_Y = 0.0f;
    CGFloat origin;
    
    if(image.size.width > self.view.frame.size.width){
        origin = self.view.frame.size.width/image.size.width;
        imageView_Y = image.size.height*origin;
    }
    
    UIImageView *imgView1 = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-imageView_X)/2,
                                                           (self.view.frame.size.height-imageView_Y)/2,
                                                           imageView_X, imageView_Y)];
    
    
    [imgView1 setImage:image];
    imgView1.contentMode =  UIViewContentModeScaleAspectFit;
    
    [self.view addSubview:imgView1];
    
    
    CGContextRelease(context);
    CFRelease(toCGImage);
    free(image_data);
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
