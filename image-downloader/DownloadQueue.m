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
        self.progress = [NSProgress progressWithTotalUnitCount:0];
        
        _isPaused = NO;
        
        // Initialier download session
        [self initializeBackgroundSession];
    }
    
    return self;
}


- (void)initializeBackgroundSession{
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"in.markg.image-downloader"];
    sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    _session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                 delegate:self
                                            delegateQueue:nil];
}

// Get index of DownloadInfo item in download list based on task identifier
- (DownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger) taskIdentifier{
    for (NSInteger i=0; i<self.mbDownloadGroups.count; i++) {
        DownloadGroupInfo *downloadGroup = self.mbDownloadGroups[i];
        DownloadInfo *download = [downloadGroup downloadInfoWithTaskIdentifier:taskIdentifier];
        if(download){
            return download;
        }
        
    }
    
    return nil;
}

// Get index of DownloadGroupInfo item in the list based on a DownloadInfo
- (DownloadGroupInfo *) downloadGroupWithDownloadInfo:(DownloadInfo *) download{
    for (NSInteger i=0; i<self.mbDownloadGroups.count; i++) {
        DownloadGroupInfo *downloadGroup = self.mbDownloadGroups[i];
        if([downloadGroup.downloads containsObject:download]){
            return downloadGroup;
        }
        
    }
    
    return nil;
}

-(void) queueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroup{
    [self.mbDownloadGroups addObject:downloadGroup];
    [self.waitingList addObject:downloadGroup];
    self.progress.totalUnitCount++;
    
    for (DownloadInfo *download in downloadGroup.downloads) {
        download.status = DownloadStatusQueuing;
       
        // Delegate: didChange
        if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
            [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
        }
    }
    
    [self run];
}
-(void) unQueueDownloadGroupInfo:(DownloadGroupInfo *)downloadGroup{
    if([self.mbDownloadGroups containsObject:downloadGroup]){
        [self.mbDownloadGroups removeObject:downloadGroup];
        [self.waitingList removeObject:downloadGroup];
        [self.runningList removeObject:downloadGroup];
    }
}


-(void) pause{
    _isPaused = YES;
    
    // Set status of all downloading task to paused
    for (DownloadGroupInfo *downloadGroup in self.mbDownloadGroups) {
        for (DownloadInfo *download in downloadGroup.downloads) {
            if(download.status == DownloadStatusDownloading
               || download.status == DownloadStatusQueuing){
                download.status = DownloadStatusPaused;
                [download.task cancelByProducingResumeData:^(NSData *resumeData){
                    download.resumeData = resumeData;
                }];
                
                if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                    [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                }
            }
        }
    }
    
    // Re-add item in running list to waiting list
    for (NSInteger i=self.runningList.count-1; i>=0; i--){
        DownloadGroupInfo *downloadGroup = self.runningList[i];
        [self.waitingList insertObject:downloadGroup atIndex:0];
    }
    
    [self.runningList removeAllObjects];
}

-(void) resume{
    _isPaused = NO;
    for (DownloadGroupInfo *downloadGroup in self.mbDownloadGroups) {
        for (DownloadInfo *download in downloadGroup.downloads) {
            if(download.status == DownloadStatusPaused){
                download.status = DownloadStatusQueuing;
                
                // Delegate
                if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                    [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
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
    for (DownloadGroupInfo *downloadGroup in self.waitingList) {
        if(self.runningList.count < self.maximumDownloadedGroup){
            [self.runningList addObject:downloadGroup];
            [removedObjects addObject:downloadGroup];
            
            NSInteger runningCount = 0;
            for (NSInteger i=0; i<downloadGroup.downloads.count; i++) {
                if(runningCount < self.maximumDownloadedPerGroup){
                    DownloadInfo *download = downloadGroup.downloads[i];
                    if(download.status == DownloadStatusFinished
                       || download.status == DownloadStatusUnzipping
                       || download.status == DownloadStatusFailed
                       || download.status == DownloadStatusUsable){
                        continue;
                    }
                        
                    // Initializer a download task
                    NSURL *URL = [NSURL URLWithString:download.url];
                    if(download.task == nil
                       || download.resumeData == nil){
                        
                        download.task = [self.session downloadTaskWithURL:URL];
                    } else {
                    
                        download.task = [self.session downloadTaskWithResumeData:download.resumeData];
                        
                    }
                    [download.task resume];
                    download.status = DownloadStatusDownloading;
                    
                    // Delegate
                    if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                        [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                    }
                    
                    runningCount++;
                } else {
                    break;
                }
            }
        } else {
            break;
        }
    }
    
    // Remove running downloads from waiting list
    for(DownloadGroupInfo *downloadGroup in removedObjects){
        [self.waitingList removeObject:downloadGroup];
    }
}
-(void) reloadDownloadGroup:(DownloadGroupInfo *) downloadGroup{
    if([self.mbDownloadGroups containsObject:downloadGroup]){
        downloadGroup.downloadingCount = 0;
        downloadGroup.queuingCount = 0;
        downloadGroup.finshedCount = 0;
        downloadGroup.progress.completedUnitCount = 0;
        
        for(DownloadInfo *download in downloadGroup.downloads){
            if(!self.isPaused){
                download.status = DownloadStatusQueuing;
            } else {
                download.status = DownloadStatusPaused;
            }
            
            download.resumeData = nil;
            download.savedURL = nil;
            download.thumbnailImage = nil;
            downloadGroup.progress.completedUnitCount = 0;
            
            if(download.task){
                [download.task cancel];
            }
            download.task = nil;
            
            // Delegate
            if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
            }
        }
    }
    
    // For the case this group is finished
    if(![self.runningList containsObject:downloadGroup]
       && ![self.waitingList containsObject:downloadGroup]){
        [self.waitingList insertObject:downloadGroup atIndex:0];
    }
    
    
    if(!self.isPaused){
        [self pause];
        [self resume];
    }
}
-(void) runNextDownloadInDownloadGroup:(DownloadGroupInfo *)downloadGroup{
    for (DownloadInfo *downloadInfoInLoop in downloadGroup.downloads) {
        if(downloadInfoInLoop.status == DownloadStatusQueuing
           && downloadGroup.downloadingCount < self.maximumDownloadedPerGroup){
            
            NSURL *URL = [NSURL URLWithString:downloadInfoInLoop.url];
            
            if(downloadInfoInLoop.task == nil
               || downloadInfoInLoop.resumeData == nil){
                downloadInfoInLoop.task = [self.session downloadTaskWithURL:URL];
            } else {
                downloadInfoInLoop.task = [self.session downloadTaskWithResumeData:downloadInfoInLoop.resumeData];
            }
            
            
            [downloadInfoInLoop.task resume];
            
            downloadInfoInLoop.status = DownloadStatusDownloading;
            
            // Delegate: didChange
            if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                [self.delegate downloadQueue:self didChangeDownloadInfo:downloadInfoInLoop downloadGroup:downloadGroup];
            }

            
        } else if(downloadGroup.downloadingCount >= self.maximumDownloadedPerGroup){
            break;
        }
    }

}

#pragma mark - NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error{
     [self initializeBackgroundSession];
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    
    // Find assocciated download info
    DownloadInfo *download = [self downloadInfoWithTaskIdentifier:downloadTask.taskIdentifier];
    
    if(download
       && download.status != DownloadStatusFailed){
        // Find assocciated download group info
        DownloadGroupInfo *downloadGroup = [self downloadGroupWithDownloadInfo:download];
        
        if(downloadGroup){
            download.status = DownloadStatusFinished;
            
            if(downloadGroup.status != DownloadGroupStatusFinished){
                // Try to download the next download info
                [self runNextDownloadInDownloadGroup:downloadGroup];
            } else {

                // Try to download the next download group
                [self.runningList removeObject:downloadGroup];
                [self run];
            }
            
            
            // Delegate: didChange
            if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
            }
            
            // Delegate: didFinish
            if([self.delegate respondsToSelector:@selector(downloadQueue:download:downloadGroup:didFinishDownloadingToURL:)]){
                [self.delegate downloadQueue:self download:download downloadGroup:downloadGroup didFinishDownloadingToURL:location];
            }
            
            download.progress.completedUnitCount = download.progress.totalUnitCount;
        }
    }
    
}


-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    // Find assocciated download info
    DownloadInfo *download = [self downloadInfoWithTaskIdentifier:task.taskIdentifier];
    
    if(download
       && error != nil
       && ![error.localizedDescription isEqualToString:@"cancelled"]){
        
        // Find assocciated download group info
        DownloadGroupInfo *downloadGroup = [self downloadGroupWithDownloadInfo:download];
        if(downloadGroup){
            download.status = DownloadStatusFailed;
            // Delegate: didChange
            if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
            }

            
            download.progress.completedUnitCount = download.progress.totalUnitCount;
            
            // Try to download the next download info
            [self runNextDownloadInDownloadGroup:downloadGroup];
        }
    }
}


-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    // Find assocciated download info
    DownloadInfo *download = [self downloadInfoWithTaskIdentifier:downloadTask.taskIdentifier];
    
    if(download){
        
        // Find assocciated download group info
        DownloadGroupInfo *downloadGroup = [self downloadGroupWithDownloadInfo:download];
        if(downloadGroup){
            
            // Handle status code
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)downloadTask.response;
            if(httpResponse.statusCode != 200
               || totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown){
                [downloadTask cancel];
                download.status = DownloadStatusFailed;
                
                // Try to download the next download info
                [self runNextDownloadInDownloadGroup:downloadGroup];
                
                // Delegate: didChange
                if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                    [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                }
                
                download.progress.totalUnitCount = 1;
                download.progress.completedUnitCount = download.progress.totalUnitCount;
            } else {
                // Delegate
                download.progress.totalUnitCount = totalBytesExpectedToWrite+1;
                download.progress.completedUnitCount = totalBytesWritten;
                
                if([self.delegate respondsToSelector:@selector(downloadQueue:download:downloadGroup:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)]){
                    [self.delegate downloadQueue:self download:download downloadGroup:downloadGroup didWriteData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
                }
                
            }
        }
        
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
            DownloadGroupInfo *downloadGroup = self.runningList[i];
            for (DownloadInfo *download in downloadGroup.downloads) {
                if(download.status == DownloadStatusDownloading){
                    download.status = DownloadStatusQueuing;
                    [download.task cancelByProducingResumeData:^(NSData *resumeData){
                        download.resumeData = resumeData;
                    }];
                    
                    if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                        [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                    }
                }
            }
            
            [removedObjects addObject:downloadGroup];
            [self.waitingList insertObject:downloadGroup atIndex:0];
        }
        
        // Remove from running list
        for(DownloadGroupInfo *downloadGroup in removedObjects){
            [self.runningList removeObject:downloadGroup];
        }
    } else if(self.runningList.count < maximumDownloadedGroup){
        [self run];
    }
}

-(void) setMaximumDownloadedPerGroup:(NSInteger)maximumDownloadedPerGroup{
    NSInteger previousMaximumDownloadedPerGroup = _maximumDownloadedPerGroup;
    _maximumDownloadedPerGroup = maximumDownloadedPerGroup;
    
    // Dont run the code bellow when all download are paused
    if(self.isPaused){
        return;
    }
    
    if(previousMaximumDownloadedPerGroup > maximumDownloadedPerGroup){
        // Bring download task that out of new maximum downloaded per group
        // back to queue
        for (DownloadGroupInfo *downloadGroup in self.runningList) {
            NSInteger downloadingCount=0;
            for (DownloadInfo *download in downloadGroup.downloads) {
                if(download.status == DownloadStatusDownloading){
                     downloadingCount++;
                    
                    if(downloadingCount > maximumDownloadedPerGroup
                       && downloadingCount <= previousMaximumDownloadedPerGroup){
                        download.status = DownloadStatusQueuing;
                        [download.task cancelByProducingResumeData:^(NSData *resumeData){
                            download.resumeData = resumeData;
                        }];
                        
                        if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                            [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                        }
                    } else if(downloadingCount > previousMaximumDownloadedPerGroup){
                        break;
                    }
                    
                   
                }
                
            }
        }
    } else if(previousMaximumDownloadedPerGroup < maximumDownloadedPerGroup){
        
        // Open more download task
        for (DownloadGroupInfo *downloadGroup in self.runningList) {
            for (DownloadInfo *download in downloadGroup.downloads) {
                if(download.status == DownloadStatusQueuing
                   && downloadGroup.downloadingCount < self.maximumDownloadedPerGroup){
                    
                    NSURL *URL = [NSURL URLWithString:download.url];
                    
                    if(download.task == nil
                       || download.resumeData == nil){
                        download.task = [self.session downloadTaskWithURL:URL];
                    } else {
                        download.task = [self.session downloadTaskWithResumeData:download.resumeData];
                    }
                    
                    
                    [download.task resume];
                    
                    download.status = DownloadStatusDownloading;
                    
                    // Delegate: didChange
                    if([self.delegate respondsToSelector:@selector(downloadQueue:didChangeDownloadInfo:downloadGroup:)]){
                        [self.delegate downloadQueue:self didChangeDownloadInfo:download downloadGroup:downloadGroup];
                    }
                    
                } else if(downloadGroup.downloadingCount >= self.maximumDownloadedPerGroup){
                    break;
                }
            }

        }
    }
}
@end
