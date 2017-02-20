//
//  DownloadTableViewCell.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "DownloadGroupTableViewCell.h"
#import "DownloadGroupInfo.h"

@implementation DownloadGroupTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void) updateViewsWith:(DownloadGroupInfo *)downloadGroupInfo{
    self.titleLabel.text = downloadGroupInfo.title;
    self.progressView.progress = downloadGroupInfo.progress;
    
    switch (downloadGroupInfo.status) {
        case DownloadGroupStatusDownloading:
            self.statusLabel.text = @"Downloading..";
            self.progressView.hidden = NO;
            break;
            
        case DownloadGroupStatusQueuing:
            self.statusLabel.text = @"Queuing";
            self.progressView.hidden = NO;
            break;
            
        case DownloadGroupStatusFinished:
            self.statusLabel.text = @"Finished";
            self.progressView.hidden = NO;
            break;
            
        case DownloadGroupStatusReady:
            self.statusLabel.text = @"";
            self.progressView.hidden = NO;
            break;
            
        default:
            self.statusLabel.text = @"";
            self.progressView.hidden = YES;
            break;
    }
}
@end
