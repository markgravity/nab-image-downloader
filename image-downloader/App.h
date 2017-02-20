//
//  App.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DownloadInfo;
@class DownloadGroupInfo;
@class DownloadQueue;
typedef void(^DownloadChangedHandler)(DownloadInfo *downloadInfo, DownloadGroupInfo *downloadGroupInfo);

@interface App : NSObject

@property (strong, nonatomic) DownloadQueue *downloadQueue;
@property (strong, nonatomic) DownloadChangedHandler downloadChangedHandler;

+(instancetype) current;
@end
