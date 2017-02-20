//
//  ScreenNo3Controller.h
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "ViewController.h"

@class DownloadGroupInfo;

@interface ScreenNo3Controller : ViewController
@property (weak, nonatomic) DownloadGroupInfo *downloadGroup;
@property (nonatomic) NSInteger initialIndex;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *pageLabel;
- (IBAction)cancelButtonTouchUp:(id)sender;

@end
