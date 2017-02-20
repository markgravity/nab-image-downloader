//
//  DownloadCollectionViewCell.h
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <UIKit/UIKit.h>
@class DownloadInfo;
@interface DownloadCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

-(void) updateViewsWith:(DownloadInfo *)downloadInfo;
@end
