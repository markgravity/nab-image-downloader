//
//  DownloadGroupInfo.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DownloadInfo.h"

typedef enum {
    DownloadGroupStatusReady = 0,
    DownloadGroupStatusQueuing,
    DownloadGroupStatusDownloading,
    DownloadGroupStatusFinished
}DownloadGroupStatus;

@interface DownloadGroupInfo : NSObject
@property (nonatomic, strong) NSString *title;

@property (nonatomic, strong) NSArray *downloadInfos;
@property (nonatomic, readonly) double progress;

// Available status:
// DownloadStatusReady
// DownloadStatusQueuing
// DownloadStatusDownloading
// DownloadStatusFinished
@property (nonatomic) DownloadGroupStatus status;
@property (atomic) NSInteger downloadingCount;
@property (atomic) NSInteger finshedCount;
@property (atomic) NSInteger queuingCount;

-(id)initWithTitle:(NSString *)title andDownloadInfos:(NSArray *)downloadInfos;
-(DownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger) taskIdentifier;
@end
