//
//  ViewController.m
//  AppleOCBlurEffect
//
//  Created by Phoenix on 2016/12/21.
//  Copyright © 2016年 Wolkamo. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+ImageEffects.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (IBAction)valueChanged:(UISlider *)sender {

    UIImage *image = [UIImage imageNamed:@"mountains"];
    UIImage *newImage = [image applyBlurWithRadius:sender.value tintColor:[UIColor colorWithWhite:0.2 alpha:0.1] saturationDeltaFactor:1.5 maskImage:nil];
    self.imageView.image = newImage;
}

@end
