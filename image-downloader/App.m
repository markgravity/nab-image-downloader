//
//  App.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "App.h"
#import "DownloadInfo.h"
#import "DownloadGroupInfo.h"

static App *_current = nil;

@implementation App
+(instancetype) current{
    if(_current == nil){
        _current = [[App alloc] init];
    }
    
    return _current;
}

-(instancetype) init{
    self = [super init];
    
    if(self != nil){
        self.downloadChangedHandler = ^(DownloadInfo *downloadInfo, DownloadGroupInfo *downloadGroupInfo){
            
        };
    }
    
    return self;
}
@end
