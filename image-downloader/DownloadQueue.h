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
-(void)downloadQueue:(DownloadQueue *)downloadQueue downloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo didFinishDownloadingToURL:(NSURL *)location;

// A download info that has a download task did write data
-(void)downloadQueue:(DownloadQueue *)downloadQueue downloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;

// A download info did change something
-(void)downloadQueue:(DownloadQueue *)downloadQueue didChangeDownloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo;
@end
@interface DownloadQueue : NSObject<NSURLSessionDelegate>

@property (nonatomic, strong, readonly) NSURLSession *session;
@property (nonatomic, strong, readonly) NSArray *downloadGroups;
@property (nonatomic) NSInteger maximumDownloadedGroup;
@property (nonatomic) NSInteger maximumDownloadedPerGroup;
@property (weak, nonatomic) id<DownloadQueueDelegate> delegate;
@property (nonatomic, readonly) BOOL isPaused;

-(void) queueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroupInfo;
-(void) unQueueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroupInfo;
-(void) reloadDownloadGroup:(DownloadGroupInfo *) downloadGroupInfo;

-(void) pause;
-(void) resume;
-(void) reset;

@end
