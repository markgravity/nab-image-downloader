//
//  DownloadGroupInfo.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadGroupInfo.h"


@implementation DownloadGroupInfo
-(id)initWithTitle:(NSString *)title andDownloadInfos:(NSArray *)downloads{
    self = [super init];
    
    if(self != nil){
        self.title = title;
        self.downloads = downloads;
        self.downloadingCount = 0;
        self.queuingCount = 0;
        self.finshedCount = 0;
        self.progress = [NSProgress progressWithTotalUnitCount:downloads.count];
        
        for (DownloadInfo *download in self.downloads) {
            download.downloadGroup = self;
            [self.progress addChild:download.progress withPendingUnitCount:1];
        }
    }
    
    return self;
}

-(DownloadInfo *) downloadInfoWithTaskIdentifier:(NSUInteger) taskIdentifier{
    for (DownloadInfo *download in self.downloads) {
        if(download.task != nil
           && download.task.taskIdentifier == taskIdentifier){
            return download;
        }
            
    }
    
    return nil;
}

-(DownloadGroupStatus) status{
    if(self.downloadingCount > 0){
        return DownloadGroupStatusDownloading;
    } else if(self.finshedCount == self.downloads.count){
        return DownloadGroupStatusFinished;
    } else if(self.queuingCount == self.downloads.count - self.finshedCount){
        return DownloadGroupStatusQueuing;
    }
    
    return DownloadGroupStatusReady;
}
@end
