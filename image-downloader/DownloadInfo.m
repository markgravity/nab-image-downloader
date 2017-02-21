//
//  DownloadInfo.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadInfo.h"
#import "DownloadGroupInfo.h"

@implementation DownloadInfo
-(id)initWithDownloadUrl:(NSString *)url{
    self = [super init];
    if(self != nil){
        self.url = url;
        self.progress = 0.0;
        self.status = DownloadStatusReady;
        self.thumbnailImage = nil;
        self.task = nil;
    }
    
    return self;
}

-(void) setStatus:(DownloadStatus)status{
    DownloadStatus previousStatus = _status;
    _status = status;
    
    // Recount queue, downloading, finished number
    // for the download group
    if(self.downloadGroupInfo){
        if(previousStatus == DownloadStatusDownloading){
            self.downloadGroupInfo.downloadingCount--;
        }
        
        if(previousStatus == DownloadStatusQueuing){
            self.downloadGroupInfo.queuingCount--;
        }
        
        if(previousStatus == DownloadStatusFinished
           || previousStatus == DownloadStatusUnzipping
           || previousStatus == DownloadStatusFailed
           || previousStatus == DownloadStatusUsable){
            self.downloadGroupInfo.finshedCount--;
        }
        
        switch (status) {
            case DownloadStatusQueuing:
                self.downloadGroupInfo.queuingCount++;
                break;
                
            case DownloadStatusDownloading:
                self.downloadGroupInfo.downloadingCount++;
                break;
                
            case DownloadStatusFinished:
            case DownloadStatusUnzipping:
            case DownloadStatusFailed:
            case DownloadStatusUsable:
                self.downloadGroupInfo.finshedCount++;

                break;
                
            default:
                break;
        }
        
        if(self.downloadGroupInfo.finshedCount < 0){
            self.downloadGroupInfo.finshedCount = 0;
        }
        
        if(self.downloadGroupInfo.downloadingCount < 0){
            self.downloadGroupInfo.downloadingCount = 0;
        }
        
        if(self.downloadGroupInfo.queuingCount < 0){
            self.downloadGroupInfo.queuingCount = 0;
        }

    }
    
    _status = status;
}
@end
