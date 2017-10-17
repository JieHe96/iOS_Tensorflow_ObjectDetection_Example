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

    image = [UIImage imageNamed:image_file];
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
    
    std::vector<float> boxScore;
    std::vector<float> boxRect;
    std::vector<std::string> boxName;
    
    //int ret = runModel(image_file_name, image_file_type, &image_data, &width, &height, &channels, boxScore, boxRect, boxName);
    int ret=runModel(image, &image_data, &width, &height, &channels, boxScore, boxRect, boxName);
    if (ret != 0 || image_data == NULL) return;
    
    //displaying running result
    CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();
    int bytes_per_row = (width * channels);
    
    const int bits_per_component = 8;
    
    CGContextRef context = CGBitmapContextCreate(image_data, width, height,
                                                 bits_per_component, bytes_per_row, color_space,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(color_space);
    
    //draw deteced box, write detected name and score
    //if no transform, the text will be rotated
    CGAffineTransform normalState=CGContextGetCTM(context);
    CGContextTranslateCTM(context, 0, height);
    CGContextScaleCTM(context, 1, -1);
    
    
    UIGraphicsPushContext(context);
    
    for(int i=0; i<boxName.size(); i++)
    {
        //draw text
        NSString *detectedName = [NSString stringWithFormat:@"%s %5.3f", boxName.at(i).c_str(), boxScore.at(i)];
        UIColor *textColor =[UIColor colorWithRed:0.1f green:0.1f blue:1.0f alpha:1.0f];
        UIFont *helveticaBold = [UIFont fontWithName:@"HelveticaNeue" size:15.0f];
        NSDictionary *dicAttribute = @{NSFontAttributeName:helveticaBold, NSForegroundColorAttributeName:textColor};
        float l = boxRect.at(i*4+0);
        float t = boxRect.at(i*4+1);
        float r = boxRect.at(i*4+2);
        float b = boxRect.at(i*4+3);
        
        CGRect textRect = CGRectMake(l, t-20>0 ? t-20 : 10, 100, 30);
        CGRect drawRect = CGRectMake(l, t, r-l, b-t);
        [detectedName drawWithRect:textRect options:NSStringDrawingUsesLineFragmentOrigin
                        attributes:dicAttribute context:nil];
        
        //draw rect
        CGContextSetRGBStrokeColor(context, 0.18, 0.72, 0.95, 0.95);//rect color
        CGContextSetLineWidth(context, 2.0);
        CGContextAddRect(context, drawRect);
        CGContextStrokePath(context);
        
    }
    
    
    UIGraphicsPopContext();
    CGContextConcatCTM(context, normalState);

    
    
    CGImageRef toCGImage = CGBitmapContextCreateImage(context);
    image = [[UIImage alloc] initWithCGImage:toCGImage];

    //for test: write image to disk for simulator running 
//    NSData * png = UIImagePNGRepresentation(image);
//    NSString *file_str=@"/Users/hejie/Desktop/ios_result.png";
//    
//    [png writeToFile: file_str atomically:YES];
    
    //displaying detected result
    CGFloat imageView_X = (image.size.width > self.view.frame.size.width) ? self.view.frame.size.width : image.size.width;
    CGFloat imageView_Y = 0.0f;
    CGFloat origin;
    
    if(image.size.width > self.view.frame.size.width){
        origin = self.view.frame.size.width/image.size.width;
        imageView_Y = image.size.height*origin;
    }
    /*
    UIImageView *imgView1 = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width-imageView_X)/2,
                                                           (self.view.frame.size.height-imageView_Y)/2,
                                                           imageView_X, imageView_Y)];
    
    
    [imgView1 setImage:image];
    imgView1.contentMode =  UIViewContentModeScaleAspectFit;
    
    [self.view addSubview:imgView1];
    */
    [imgView setImage:image];
    imgView.contentMode=UIViewContentModeScaleAspectFit;
    
    CGContextRelease(context);
    CFRelease(toCGImage);
    free(image_data);
    
}

- (IBAction)choosePhoto:(id)sender {
    // 实例化 UIImagePickerController 对象
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    // 设置代理
    imagePickerController.delegate = self;
    // 设置是否需要做图片编辑，default NO
    imagePickerController.allowsEditing = YES;
    // 判断数据来源是否可用
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        // 设置数据来源
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // 打开相机/相册/图库
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    // 从info中将图片取出，并加载到imageView当中
    image = [info objectForKey:UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    CGFloat imageView_X = (image.size.width > self.view.frame.size.width) ? self.view.frame.size.width : image.size.width;
    CGFloat imageView_Y = 0.0f;
    CGFloat origin;
    
    if(image.size.width > self.view.frame.size.width){
        origin = self.view.frame.size.width/image.size.width;
        imageView_Y = image.size.height*origin;
    }
    [imgView setImage:image];
    imgView.contentMode =  UIViewContentModeScaleToFill;
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}
@end
