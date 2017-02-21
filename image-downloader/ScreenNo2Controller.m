//
//  DownloadGroupController.m
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "ScreenNo2Controller.h"
#import "DownloadGroupInfo.h"
#import "DownloadCollectionViewCell.h"
#import "DownloadInfo.h"
#import "App.h"
#import "DownloadQueue.h"
#import "ScreenNo3Controller.h"

@interface ScreenNo2Controller ()

@end

@implementation ScreenNo2Controller

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = self.downloadGroup.title;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated{
    __weak ScreenNo2Controller *weakSelf = self;
    [App current].downloadChangedHandler = ^(DownloadInfo *downloadInfo, DownloadGroupInfo *downloadGroupInfo){
        if(self.downloadGroup == downloadGroupInfo){
            [[NSOperationQueue mainQueue] addOperationWithBlock:^(){
                NSInteger index = [weakSelf.downloadGroup.downloadInfos indexOfObject:downloadInfo];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [weakSelf.collectionView reloadItemsAtIndexPaths:@[indexPath]];
            }];
        }
    };
}
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.identifier isEqualToString:@"toScreenNo3Controller"]){
        NSIndexPath *indexPath = sender;
        
        ScreenNo3Controller *dstController = segue.destinationViewController;
        dstController.downloadGroup = self.downloadGroup;
        dstController.initialIndex = indexPath.row;
    }
}


#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.downloadGroup.downloadInfos.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    DownloadCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DownloadCollectionViewCell" forIndexPath:indexPath];
    DownloadInfo *downloadInfo = self.downloadGroup.downloadInfos[indexPath.row];
    [cell updateViewsWith:downloadInfo];
    
    return cell;
}
#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    [self performSegueWithIdentifier:@"toScreenNo3Controller" sender:indexPath];
}

#pragma mark - IBActions

- (IBAction)reloadButtonTouchUp:(id)sender {
    UIButton *button = sender;
    button.enabled = NO;
    [[App current].downloadQueue reloadDownloadGroup:self.downloadGroup];
    button.enabled = YES;
}
@end
