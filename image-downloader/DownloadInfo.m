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
        self.status = DownloadStatusReady;
        self.thumbnailImage = nil;
        self.progress = [NSProgress progressWithTotalUnitCount:0];
        self.unzippingProgress = [NSProgress progressWithTotalUnitCount:1];
        self.task = nil;
    }
    
    return self;
}

-(void) setStatus:(DownloadStatus)status{
    DownloadStatus previousStatus = _status;
    _status = status;
    
    // Recount queue, downloading, finished number
    // for the download group
    if(self.downloadGroup){
        if(previousStatus == DownloadStatusDownloading){
            self.downloadGroup.downloadingCount--;
        }
        
        if(previousStatus == DownloadStatusQueuing){
            self.downloadGroup.queuingCount--;
        }
        
        if(previousStatus == DownloadStatusFinished
           || previousStatus == DownloadStatusUnzipping
           || previousStatus == DownloadStatusFailed
           || previousStatus == DownloadStatusUsable){
            self.downloadGroup.finshedCount--;
        }
        
        switch (status) {
            case DownloadStatusQueuing:
                self.downloadGroup.queuingCount++;
                break;
                
            case DownloadStatusDownloading:
                self.downloadGroup.downloadingCount++;
                break;
                
            case DownloadStatusFinished:
            case DownloadStatusUnzipping:
            case DownloadStatusFailed:
            case DownloadStatusUsable:
                self.downloadGroup.finshedCount++;

                break;
                
            default:
                break;
        }
        
        if(self.downloadGroup.finshedCount < 0){
            self.downloadGroup.finshedCount = 0;
        }
        
        if(self.downloadGroup.downloadingCount < 0){
            self.downloadGroup.downloadingCount = 0;
        }
        
        if(self.downloadGroup.queuingCount < 0){
            self.downloadGroup.queuingCount = 0;
        }

    }
    
    _status = status;
}
@end
