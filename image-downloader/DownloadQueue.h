//
//  DownloadQueue.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DownloadGroupInfo;
@class DownloadInfo;
@class DownloadGroupInfo;
@class DownloadQueue;
@protocol DownloadQueueDelegate <NSObject>

@optional
// A download info that has a download task did finish
-(void)downloadQueue:(DownloadQueue *)downloadQueue download:(DownloadInfo *)download downloadGroup:(DownloadGroupInfo *) downloadGroup didFinishDownloadingToURL:(NSURL *)location;

// A download info that has a download task did write data
-(void)downloadQueue:(DownloadQueue *)downloadQueue download:(DownloadInfo *)download downloadGroup:(DownloadGroupInfo *) downloadGroup didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

// A download info did change something
-(void)downloadQueue:(DownloadQueue *)downloadQueue didChangeDownloadInfo:(DownloadInfo *)download downloadGroup:(DownloadGroupInfo *) downloadGroup;
@end
@interface DownloadQueue : NSObject<NSURLSessionDataDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) NSArray *downloadGroups;
@property (nonatomic) NSInteger maximumDownloadedGroup;
@property (nonatomic) NSInteger maximumDownloadedPerGroup;
@property (weak, nonatomic) id<DownloadQueueDelegate> delegate;
@property (nonatomic, readonly) BOOL isPaused;
@property (nonatomic, strong) NSProgress *progress;

-(void) queueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroup;
-(void) unQueueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroup;
-(void) reloadDownloadGroup:(DownloadGroupInfo *) downloadGroup;

-(void) pause;
-(void) resume;
-(void) reset;

@end
