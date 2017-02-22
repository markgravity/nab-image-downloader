//
//  DownloadInfo.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef enum {
    DownloadStatusReady = 0,
    DownloadStatusQueuing,
    DownloadStatusDownloading,
    DownloadStatusPaused,
    DownloadStatusFinished,
    DownloadStatusUnzipping,
    DownloadStatusFailed,
    DownloadStatusUsable
}DownloadStatus;

@class DownloadGroupInfo;
@interface DownloadInfo : NSObject


@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSURLSessionDownloadTask *task;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURL *savedURL;
@property (nonatomic, strong) UIImage *thumbnailImage;
@property (nonatomic) DownloadStatus status;
@property (nonatomic, strong) NSProgress *progress;
@property (nonatomic, strong) NSProgress *unzippingProgress;

// The group that contains this
@property (nonatomic) DownloadGroupInfo *downloadGroup;

-(id)initWithDownloadUrl:(NSString *)url;
@end
