//
//  DownloadGroupController.h
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "ViewController.h"
#import "App.h"

@class DownloadGroupInfo;

@interface ScreenNo2Controller : ViewController<UICollectionViewDelegate, UICollectionViewDataSource>

@property (weak, nonatomic) DownloadGroupInfo *downloadGroup;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
- (IBAction)reloadButtonTouchUp:(id)sender;

@end
