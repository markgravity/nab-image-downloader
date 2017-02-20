//
//  NSString+Extension.m
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "NSString+Extension.h"

@implementation NSString(Extension)

-(NSString *) fileNameWithoutExtension{
    NSMutableArray *parts = [self.lastPathComponent componentsSeparatedByString:@"."].mutableCopy;
    [parts removeLastObject];
    
    return [parts componentsJoinedByString:@"."];
}
@end
