//
//  ViewController.h
//  ex_SSD_Mobilenet_TF
//
//  Created by He Caiguang on 2017/7/6.
//  Copyright © 2017年 He Caiguang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController<UINavigationControllerDelegate,UIImagePickerControllerDelegate> {
    UIImageView *imgView;
}
@property(nonatomic,retain) UIImage *image_before_process;
@property(nonatomic,retain) UIImage *image_after_process;

- (IBAction)runButton:(id)sender;
- (IBAction)choosePhoto:(id)sender;

@end

