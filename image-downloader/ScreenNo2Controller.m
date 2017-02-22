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
    [self registerObserveForDownload:self.downloadGroup.downloads];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated{

}


- (void) dealloc{
    @try{
        [self unRegisterObserveForDownloads:self.downloadGroup.downloads];
    }
    @catch(NSException *e){
        
    }
}

#pragma mark - Observes
-(void) registerObserveForDownload:(NSArray *) downloads{
    for (DownloadInfo *download in downloads) {
        [download addObserver:self forKeyPath:@"progress.completedUnitCount" options:NSKeyValueObservingOptionInitial context:nil];
        [download addObserver:self forKeyPath:@"unzippingProgress.completedUnitCount" options:NSKeyValueObservingOptionInitial context:nil];
    }
}
-(void) unRegisterObserveForDownloads:(NSArray *) downloads{
    for (DownloadInfo *download in downloads) {
        [download removeObserver:self forKeyPath:@"progress.completedUnitCount"];
        [download removeObserver:self forKeyPath:@"unzippingProgress.completedUnitCount"];
    }
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"progress.completedUnitCount"]
       || [keyPath isEqualToString:@"unzippingProgress.completedUnitCount"]){
        [self updateForDownloadGroup:object];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
-(void) updateForDownloadGroup:(DownloadInfo *) download{
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSInteger index = [self.downloadGroup.downloads indexOfObject:download];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        DownloadCollectionViewCell *cell = (DownloadCollectionViewCell* )[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell updateViewsWith:download];
    });
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
    return self.downloadGroup.downloads.count;
}

// The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    DownloadCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"DownloadCollectionViewCell" forIndexPath:indexPath];
    DownloadInfo *download = self.downloadGroup.downloads[indexPath.row];
    [cell updateViewsWith:download];
    
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
    [self.collectionView reloadData];
    button.enabled = YES;
}
@end
