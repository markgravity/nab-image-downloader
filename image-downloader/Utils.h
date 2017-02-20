//
//  Utils.h
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Utils : NSObject
+ (NSString *)jsonEncode:(NSDictionary *)data;
+ (id)jsonDecode:(NSString *)json;
+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size;
@end
