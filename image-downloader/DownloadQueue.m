//
//  DownloadQueue.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadQueue.h"
#import "DownloadGroupInfo.h"
#import "AppDelegate.h"

@interface DownloadQueue ()
@property (nonatomic, strong) NSMutableArray *mbDownloadGroups;
@property (nonatomic, strong) NSMutableArray *runningList;
@property (nonatomic, strong) NSMutableArray *waitingList;

@end

@implementation DownloadQueue
-(instancetype) init{
    self = [super init];
    if(self != nil){
        self.mbDownloadGroups = [[NSMutableArray alloc] init];
        self.runningList = [[NSMutableArray alloc] init];
        self.waitingList = [[NSMutableArray alloc] init];
        _isPaused = NO;
        
        // Initialier download session
        [self initializeBackgroundSession];
    }
    
    return self;
}


- (void)initializeBackgroundSession{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"in.markg.image-downloader"];
//    sessionConfiguration.HTTPMaximumConnectionsPerHost = 10;
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

// Get index of DownloadInfo item in download list based on task identifier
- (DownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger) taskIdentifier{
    for (NSInteger i=0; i<self.mbDownloadGroups.count; i++) {
        DownloadGroupInfo *downloadGroupInfo = self.mbDownloadGroups[i];
        DownloadInfo *downloadInfo = [downloadGroupInfo downloadInfoWithTaskIdentifier:taskIdentifier];
        if(downloadInfo){
            return downloadInfo;
        }
        
    }
    
    return nil;
}

// Get index of DownloadGroupInfo item in the list based on a DownloadInfo
- (DownloadGroupInfo *) downloadGroupWithDownloadInfo:(DownloadInfo *) downloadInfo{
    for (NSInteger i=0; i<self.mbDownloadGroups.count; i++) {
        DownloadGroupInfo *downloadGroupInfo = self.mbDownloadGroups[i];
        if([downloadGroupInfo.downloadInfos containsObject:downloadInfo]){
            return downloadGroupInfo;
        }
        
    }
    
    return nil;
}

-(void) queueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroupInfo{
    [self.mbDownloadGroups addObject:downloadGroupInfo];
    [self.waitingList addObject:downloadGroupInfo];
    
    for (DownloadInfo *downloadInfo in downloadGroupInfo.downloadInfos) {
        downloadInfo.status = DownloadStatusQueuing;
        [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
    }
    
    [self run];
}
-(void) unQueueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroupInfo{
    if([self.mbDownloadGroups containsObject:downloadGroupInfo]){
        [self.mbDownloadGroups removeObject:downloadGroupInfo];
        [self.waitingList removeObject:downloadGroupInfo];
        [self.runningList removeObject:downloadGroupInfo];
    }
}


-(void) pause{
    _isPaused = YES;
    
    // Set status of all downloading task to paused
    for (DownloadGroupInfo *downloadGroupInfo in self.mbDownloadGroups) {
        for (DownloadInfo *downloadInfo in downloadGroupInfo.downloadInfos) {
            if(downloadInfo.status == DownloadStatusDownloading
               || downloadInfo.status == DownloadStatusQueuing){
                downloadInfo.status = DownloadStatusPaused;
                [downloadInfo.task cancelByProducingResumeData:^(NSData *resumeData){
                    downloadInfo.resumeData = resumeData;
                }];
                
                if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroupInfo:)]){
                    [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
                }
            }
        }
    }
    
    // Re-add item in running list to waiting list
    for (DownloadGroupInfo *downloadGroupInfo in self.runningList) {
        [self.waitingList insertObject:downloadGroupInfo atIndex:0];
    }
    [self.runningList removeAllObjects];
}

-(void) resume{
    _isPaused = NO;
    for (DownloadGroupInfo *downloadGroupInfo in self.mbDownloadGroups) {
        for (DownloadInfo *downloadInfo in downloadGroupInfo.downloadInfos) {
            if(downloadInfo.status == DownloadStatusPaused){
                downloadInfo.status = DownloadStatusQueuing;
                
                // Delegate
                if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroupInfo:)]){
                    [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
                }
            }
        }
    }

    [self run];
}

-(void) reset{
    [self.session invalidateAndCancel];

    [self.runningList removeAllObjects];
    [self.waitingList removeAllObjects];
    [self.mbDownloadGroups removeAllObjects];
    
    _isPaused = NO;
}

// Find the next download files will be downloaded and start
-(void) run{
    NSMutableArray *removedObjects = [[NSMutableArray alloc] init];
    for (DownloadGroupInfo *downloadGroupInfo in self.waitingList) {
        if(self.runningList.count < self.maximumDownloadedGroup){
            [self.runningList addObject:downloadGroupInfo];
            [removedObjects addObject:downloadGroupInfo];
            
            NSInteger runningCount = 0;
            for (NSInteger i=0; i<downloadGroupInfo.downloadInfos.count; i++) {
                if(runningCount < self.maximumDownloadedPerGroup){
                    DownloadInfo *downloadInfo = downloadGroupInfo.downloadInfos[i];
                    if(downloadInfo.status == DownloadStatusFinished
                       || downloadInfo.status == DownloadStatusUnzipping
                       || downloadInfo.status == DownloadStatusFailed
                       || downloadInfo.status == DownloadStatusUsable){
                        continue;
                    }
                        
                    // Initializer a download task
                    NSURL *URL = [NSURL URLWithString:downloadInfo.url];
                    if(downloadInfo.task == nil
                       || downloadInfo.resumeData == nil){
                        
                        downloadInfo.task = [self.session downloadTaskWithURL:URL];
                    } else {
                    
                        downloadInfo.task = [self.session downloadTaskWithResumeData:downloadInfo.resumeData];
                        
                    }
                    [downloadInfo.task resume];
                    downloadInfo.status = DownloadStatusDownloading;
                    
                    // Delegate
                    if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroupInfo:)]){
                        [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
                    }
                    
                    runningCount++;
                } else {
                    break;
                }
            }
        }
    }
    
    // Remove running downloads from waiting list
    for(DownloadGroupInfo *downloadGroupInfo in removedObjects){
        [self.waitingList removeObject:downloadGroupInfo];
    }
}
-(void) reloadDownloadGroup:(DownloadGroupInfo *) downloadGroupInfo{
    if([self.mbDownloadGroups containsObject:downloadGroupInfo]){
        for(DownloadInfo *downloadInfo in downloadGroupInfo.downloadInfos){
            downloadInfo.status = DownloadStatusQueuing;
            downloadInfo.resumeData = nil;
            downloadInfo.savedURL = nil;
            downloadInfo.progress = 0.0;
            
            if(downloadInfo.task){
                [downloadInfo.task cancel];
            }
            downloadInfo.task = nil;
        }
    }
    
    // For the case thid group is all finished
    if(![self.runningList containsObject:downloadGroupInfo]
       && ![self.waitingList containsObject:downloadGroupInfo]){
        [self.waitingList insertObject:downloadGroupInfo atIndex:0];
    }
    
    [self pause];
    [self resume];
}
#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
     [self initializeBackgroundSession];
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    // Find assocciated download info
    DownloadInfo *downloadInfo = [self downloadInfoWithTaskIdentifier:downloadTask.taskIdentifier];
    
    if(downloadInfo){
        // Find assocciated download group info
        DownloadGroupInfo *downloadGroupInfo = [self downloadGroupWithDownloadInfo:downloadInfo];
        
        if(downloadGroupInfo){
            downloadInfo.status = DownloadStatusFinished;
            [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
            
            if(downloadGroupInfo.status != DownloadStatusFinished){
                
                // Try to download the next download info
                for (DownloadInfo *downloadInfoInLoop in downloadGroupInfo.downloadInfos) {
                    if(downloadInfoInLoop.status == DownloadStatusQueuing
                       && downloadGroupInfo.downloadingCount < self.maximumDownloadedPerGroup){
                        
                        NSURL *URL = [NSURL URLWithString:downloadInfoInLoop.url];
                        
                        if(downloadInfoInLoop.task == nil
                           || downloadInfoInLoop.resumeData == nil){
                            downloadInfoInLoop.task = [self.session downloadTaskWithURL:URL];
                        } else {
                            downloadInfoInLoop.task = [self.session downloadTaskWithResumeData:downloadInfoInLoop.resumeData];
                        }

                        
                        [downloadInfoInLoop.task resume];
                        
                        downloadInfoInLoop.status = DownloadStatusDownloading;
                        [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];

                    }
                }
            } else {
                // Try to download the next download group
                [self.runningList removeObject:downloadGroupInfo];
                [self run];
            }
            
            
            // Delegate
            if([self.delegate respondsToSelector:@selector(downloadQueue:downloadInfo:downloadGroupInfo:didFinishDownloadingToURL:)]){
                [self.delegate downloadQueue:self downloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo didFinishDownloadingToURL:location];
            }
        }
    }
    
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    // Find assocciated download info
    DownloadInfo *downloadInfo = [self downloadInfoWithTaskIdentifier:task.taskIdentifier];
    
    if(downloadInfo
       && error != nil
       && ![error.localizedDescription isEqualToString:@"cancelled"]){
        downloadInfo.status = DownloadStatusFailed;
    }
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    // Find assocciated download info
    DownloadInfo *downloadInfo = [self downloadInfoWithTaskIdentifier:downloadTask.taskIdentifier];
    
    if(downloadInfo){
        
        // Find assocciated download group info
        DownloadGroupInfo *downloadGroupInfo = [self downloadGroupWithDownloadInfo:downloadInfo];
        
        // Delegate
        if([self.delegate respondsToSelector:@selector(downloadQueue:downloadInfo:downloadGroupInfo:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]){
            [self.delegate downloadQueue:self downloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
        }
        
//        NSLog(@"DOWNLOADING: %@", downloadGroupInfo.title);
    }
    
}


-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session{
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    // Check if all download tasks have been finished.
    [self.session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        
        if ([downloadTasks count] == 0) {
            if (appDelegate.backgroundSessionCompletionHandler) {
                void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
                appDelegate.backgroundSessionCompletionHandler = nil;
                completionHandler();
            }

        }
    }];
}


#pragma mark Get & Set
-(NSArray *) downloadGroups{
    return self.mbDownloadGroups.copy;
}
-(void) setMaximumDownloadedGroup:(NSInteger)maximumDownloadedGroup{
    _maximumDownloadedGroup = maximumDownloadedGroup;
    
    // Dont run the code bellow when all download are paused
    if(self.isPaused){
        return;
    }
    
    // Requeue when maximumDownloadedGroup changed
    if(self.runningList.count > maximumDownloadedGroup){
        NSMutableArray *removedObjects = [[NSMutableArray alloc] init];
        
        // Bring back to waiting list
        for (NSInteger i = self.runningList.count-1; i>=maximumDownloadedGroup; i--) {
            DownloadGroupInfo *downloadGroupInfo = self.runningList[i];
            for (DownloadInfo *downloadInfo in downloadGroupInfo.downloadInfos) {
                if(downloadInfo.status == DownloadStatusDownloading){
                    downloadInfo.status = DownloadStatusQueuing;
                    [downloadInfo.task cancelByProducingResumeData:^(NSData *resumeData){
                        downloadInfo.resumeData = resumeData;
                    }];
                    
                    if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroupInfo:)]){
                        [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfo downloadGroupInfo:downloadGroupInfo];
                    }
                }
            }
            
            [removedObjects addObject:downloadGroupInfo];
            [self.waitingList insertObject:downloadGroupInfo atIndex:0];
        }
        
        // Remove from running list
        for(DownloadGroupInfo *downloadGroupInfo in removedObjects){
            [self.runningList removeObject:downloadGroupInfo];
        }
    } else if(self.runningList.count < maximumDownloadedGroup){
        [self run];
    }
}

@end