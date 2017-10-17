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
    UIImage *image;
}

- (IBAction)runButton:(id)sender;
- (IBAction)choosePhoto:(id)sender;

@end

