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
#import "UIImage+Editor.h"

@implementation DownloadCollectionViewCell

-(void) updateViewsWith:(DownloadInfo *)download{
    NSInteger percent = download.progress.fractionCompleted*100;
    UIImage *image;
    self.thumbnailImageView.backgroundColor = [UIColor lightGrayColor];
    self.thumbnailImageView.image = nil;
    switch (download.status) {
        case DownloadStatusUsable:
            
            // Load image and resize it
            if(download.thumbnailImage == nil){
                if([download.savedURL.path.pathExtension isEqualToString:@"pdf"]){
                    image = ImageFromPDFFile(download.savedURL.path, self.thumbnailImageView.frame.size);
                } else {
                    image = [UIImage imageWithContentsOfFile:download.savedURL.path];
                    
                    // Get a minimum aspect fill size
                    CGSize thumbnailImageViewSize = self.thumbnailImageView.frame.size;
                    CGSize size = CGSizeMake(thumbnailImageViewSize.width, thumbnailImageViewSize.width * image.size.height / image.size.width);
                    if(size.height < thumbnailImageViewSize.height){
                        size.height = thumbnailImageViewSize.height;
                        size.width = size.height * thumbnailImageViewSize.width / thumbnailImageViewSize.height;
                    }
                    
                    size = CGSizeMake(size.width*2, size.height*2);
                    
                    // resize image
                    image = [UIImage imageWithImage:image convertToSize:size];
                }
                
                download.thumbnailImage = image;
            } else {
                image = download.thumbnailImage;
            }
            
            // Set to cell
            self.thumbnailImageView.image = image;
            self.statusLabel.text = @"";
            if([download.savedURL.path.pathExtension isEqualToString:@"pdf"]){
                self.thumbnailImageView.backgroundColor = [UIColor whiteColor];
            }

            
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
