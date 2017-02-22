//
//  DownloadTableViewCell.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DownloadGroupInfo;

@interface DownloadGroupTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

-(void) updateViewsWith:(DownloadGroupInfo *)downloadGroup;
@end
