//
//  DownloadCollectionViewCell.m
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadCollectionViewCell.h"
#import "DownloadInfo.h"
#import "NSString+Extension.h"
#import "PDFUtility.h"
#import "Utils.h"

@implementation DownloadCollectionViewCell

-(void) updateViewsWith:(DownloadInfo *)downloadInfo{
    NSInteger percent = round(downloadInfo.progress*100);
    UIImage *image;
    self.thumbnailImageView.backgroundColor = [UIColor lightGrayColor];
    self.thumbnailImageView.image = nil;
    switch (downloadInfo.status) {
        case DownloadStatusUsable:
            self.statusLabel.text = @"";
            if([downloadInfo.savedURL.path.pathExtension isEqualToString:@"pdf"]){
                image = ImageFromPDFFile(downloadInfo.savedURL.path, self.thumbnailImageView.frame.size);
                self.thumbnailImageView.backgroundColor = [UIColor whiteColor];
                
            } else {
                image = [UIImage imageWithContentsOfFile:downloadInfo.savedURL.path];
                
                CGSize thumbnailImageViewSize = self.thumbnailImageView.frame.size;
                CGSize size = CGSizeMake(thumbnailImageViewSize.width, thumbnailImageViewSize.width * image.size.height / image.size.width);
                if(size.height < thumbnailImageViewSize.height){
                    size.height = thumbnailImageViewSize.height;
                    size.width = size.height * thumbnailImageViewSize.width / thumbnailImageViewSize.height;
                }
                
                size = CGSizeMake(size.width*2, size.height*2);
                image = [Utils imageWithImage:image convertToSize:size];
            }
            
            self.thumbnailImageView.image = image;
            
            break;
            
        case DownloadStatusDownloading:
            self.statusLabel.text = [NSString stringWithFormat:@"Downloading %@%%", @(percent).stringValue];
            break;
            
        case DownloadStatusQueuing:
            self.statusLabel.text = @"Queuing";
            break;
            
        case DownloadStatusFailed:
            self.statusLabel.text = @"Error";
            break;
            
        case DownloadStatusUnzipping:
            self.statusLabel.text = @"Unzipping";
            break;
            
        default:
            self.statusLabel.text = @"";
           
            break;
    }

}
@end
