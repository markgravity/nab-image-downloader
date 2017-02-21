//
//  UIImage+Editor.h
//  image-downloader
//
//  Created by Mark G on 2/21/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage(Editor)
+ (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size;
+ (UIImage *)imageWithImage:(UIImage *)image cropToRect:(CGRect)rect;
@end
