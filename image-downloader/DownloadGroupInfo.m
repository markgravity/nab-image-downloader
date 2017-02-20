//
//  DownloadGroupInfo.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadGroupInfo.h"


@implementation DownloadGroupInfo
-(id)initWithTitle:(NSString *)title andDownloadInfos:(NSArray *)downloadInfos{
    self = [super init];
    
    if(self != nil){
        self.title = title;
        self.downloadInfos = downloadInfos;
        for (DownloadInfo *downloadInfo in self.downloadInfos) {
            downloadInfo.downloadGroupInfo = self;
        }
    }
    
    return self;
}

-(DownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger) taskIdentifier{
    for (DownloadInfo *downloadInfo in self.downloadInfos) {
        if(downloadInfo.task != nil
           && downloadInfo.task.taskIdentifier == taskIdentifier){
            return downloadInfo;
        }
            
    }
    
    return nil;
}

-(double) progress{
    return (double)self.finshedCount / (double)self.downloadInfos.count;
}

-(DownloadStatus) status{
    if(self.downloadingCount > 0){
        return DownloadStatusDownloading;
    } else if(self.finshedCount == self.downloadInfos.count){
        return DownloadStatusFinished;
    } else if(self.queuingCount == self.downloadInfos.count - self.finshedCount){
        return DownloadStatusQueuing;
    }
    
    return DownloadStatusReady;
}
@end
