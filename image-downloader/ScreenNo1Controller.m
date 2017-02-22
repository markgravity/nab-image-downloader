//
//  DownloadManagerController.m
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import <SSZipArchive/SSZipArchive.h>

#import "ScreenNo1Controller.h"
#import "App.h"
#import "DownloadInfo.h"
#import "DownloadGroupTableViewCell.h"
#import "AppDelegate.h"
#import "DownloadGroupInfo.h"
#import "Utils.h"
#import "ScreenNo2Controller.h"
#import "NSString+Extension.h"
#import "Alert.h"


@interface ScreenNo1Controller ()
@property (nonatomic, strong) NSURL *documentDirectoryURL;
@property (nonatomic, strong) DownloadQueue *downloadQueue;
@property (nonatomic) BOOL didReloadedTableView;

@end

@implementation ScreenNo1Controller

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.didReloadedTableView = NO;
    
    // Get document path, we will save downloaded files in "downloads" folder
    NSArray *URLs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    self.documentDirectoryURL = [URLs objectAtIndex:0];
    self.documentDirectoryURL = [self.documentDirectoryURL URLByAppendingPathComponent:@"Download"];
    
    // Initialize download queue
    self.downloadQueue = [[DownloadQueue alloc] init];
    self.downloadQueue.maximumDownloadedPerGroup = self.connectionNumberSlider.value;
    self.downloadQueue.maximumDownloadedGroup = self.connectionNumberSlider.value;
    self.downloadQueue.delegate = self;
    [App current].downloadQueue = self.downloadQueue;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)viewWillAppear:(BOOL)animated{
    self.pauseBarButton.enabled = NO;
}

- (void) dealloc{
    @try{
        [self unRegisterObserveForDownloadGroups:self.downloadQueue.downloadGroups];
    }
    @catch(NSException *e){
        
    }
}

#pragma mark - Observes
-(void) registerObserveForDownloadGroups:(NSArray *) downloadGroups{
    for (DownloadGroupInfo *downloadGroup in downloadGroups) {
        [downloadGroup addObserver:self forKeyPath:@"progress.completedUnitCount" options:NSKeyValueObservingOptionInitial context:nil];
    }
}
-(void) unRegisterObserveForDownloadGroups:(NSArray *) downloadGroups{
    for (DownloadGroupInfo *downloadGroup in downloadGroups) {
        [downloadGroup removeObserver:self forKeyPath:@"progress.completedUnitCount"];
    }
}
-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if([keyPath isEqualToString:@"progress.completedUnitCount"]){
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self updateForDownloadGroup:object];
            [self updateToolbars];
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
-(void) updateForDownloadGroup:(DownloadGroupInfo *) downloadGroup{
    NSInteger index = [self.downloadQueue.downloadGroups indexOfObject:downloadGroup];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    DownloadGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    [cell updateViewsWith:downloadGroup];

}

-(void) updateToolbars{
    if(!self.downloadQueue.isPaused){
        self.pauseButton.enabled = NO;;
        for (DownloadGroupInfo *downloadGroup in self.downloadQueue.downloadGroups) {
            if(downloadGroup.status == DownloadGroupStatusDownloading){
                self.pauseButton.enabled = YES;
                break;
            }
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"toScreenNo2Controller"]){
        ScreenNo2Controller *dstController = segue.destinationViewController;
        
        if(self.downloadQueue.isPaused)
            dstController.reloadButton.enabled = NO;
        
        dstController.downloadGroup = sender;
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.downloadQueue.downloadGroups.count;
}

- (DownloadGroupTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadGroupTableViewCell" forIndexPath:indexPath];
    
    DownloadGroupInfo *downloadGroup = self.downloadQueue.downloadGroups[indexPath.row];
    [cell updateViewsWith:downloadGroup];
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadGroupInfo *downloadGroup = self.downloadQueue.downloadGroups[indexPath.row];
    [self performSegueWithIdentifier:@"toScreenNo2Controller" sender:downloadGroup];
}

#pragma mark - DownloadQueueDelegate
-(void)downloadQueue:(DownloadQueue *)downloadQueue download:(DownloadInfo *)download downloadGroup:(DownloadGroupInfo *) downloadGroup didFinishDownloadingToURL:(NSURL *)location{
    
    NSURL *folderURL = [self.documentDirectoryURL URLByAppendingPathComponent:downloadGroup.title];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success;
    
    // Handle file type
    if([download.task.currentRequest.URL.path.pathExtension isEqualToString:@"zip"]){
        // It is zip file
        download.status = DownloadStatusUnzipping;
        
        
        // Move it to group folder
        NSError *error;
        NSURL *tempFolderURL = [folderURL URLByAppendingPathComponent:download.task.currentRequest.URL.path.fileNameWithoutExtension];

        NSURL *tempFileURL = [tempFolderURL URLByAppendingPathComponent:location.lastPathComponent];
        
        [fileManager createDirectoryAtPath:tempFolderURL.path withIntermediateDirectories:YES attributes:nil error:&error];
        [fileManager copyItemAtURL:location toURL:tempFileURL error:&error];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            
            // Extract it to temp folder
            NSError *error;
            BOOL succeeded = [SSZipArchive unzipFileAtPath:tempFileURL.path toDestination:tempFolderURL.path  overwrite:YES password:nil error:&error];
            if(succeeded){
                
                // Move back to parent folder
                NSString *fileName = [fileManager contentsOfDirectoryAtPath:tempFolderURL.path error:nil].firstObject;
                NSURL *fileInTempFolderUrl = [tempFolderURL URLByAppendingPathComponent:fileName];
                NSURL *savedURL = [folderURL URLByAppendingPathComponent:fileName];
                [fileManager moveItemAtPath:fileInTempFolderUrl.path toPath:savedURL.path error:nil];
                
                // Remove temp folder
                [fileManager removeItemAtPath:tempFolderURL.path error:nil];
                
                download.status = DownloadStatusUsable;
                download.savedURL = savedURL;
                download.resumeData = nil;
                download.task = nil;
            } else {
                download.status = DownloadStatusFailed;
            }
            
            download.unzippingProgress.completedUnitCount = download.unzippingProgress.totalUnitCount;
        });
    } else {
        // It is image or PDF
        // Save downloaded file to download folder
        NSError *error;
        NSURL *savedURL;
        
        NSString *filename = download.task.currentRequest.URL.lastPathComponent;
        savedURL = [folderURL URLByAppendingPathComponent:filename];
        
        
        // Remove if exists
        if ([fileManager fileExistsAtPath:[savedURL path]]) {
            [fileManager removeItemAtURL:savedURL error:nil];
        } else if(![fileManager fileExistsAtPath:folderURL.path]){
            [fileManager createDirectoryAtPath:folderURL.path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        success = [fileManager copyItemAtURL:location
                                            toURL:savedURL
                                            error:&error];
        
        if(success){
            download.status = DownloadStatusUsable;
            download.savedURL = savedURL;
            download.resumeData = nil;
            download.task = nil;
            
        } else {
            download.status = DownloadStatusFailed;
        }
    }
}

#pragma mark - IBAction
- (IBAction)resetButtonTouchUp:(id)sender {
    self.addButton.enabled = YES;
    [self.pauseButton setTitle:@"Pause" forState:UIControlStateNormal];
    self.pauseButton.tag = 0;
    self.pauseButton.enabled = NO;
    
    
    [self.downloadQueue reset];
    [[NSFileManager defaultManager] removeItemAtPath:self.documentDirectoryURL.path error:nil];
    [self.tableView reloadData];
}

- (IBAction)pauseButtonTouchUp:(id)sender {
    UIButton *button = sender;
    if(button.tag == 0){
        button.tag = 1;
        [button setTitle:@"Resume" forState:UIControlStateNormal];
        [self.downloadQueue pause];
    } else {
        button.tag = 0;
        [button setTitle:@"Pause" forState:UIControlStateNormal];
        [self.downloadQueue resume];

    }
    
    [self.tableView reloadData];
}

- (IBAction)addButtonTouchUp:(id)sender {
    self.addButton.enabled = NO;
    self.resetButton.enabled = NO;
    
    // Download resources
    NSURL *URL = [NSURL URLWithString:DATA_PACKAGE_URL_STRING];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:90];
    
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:downloadRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error){
        
        if(!error){
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            // Unzip downloaded file
            BOOL success = [SSZipArchive unzipFileAtPath:location.path toDestination: self.documentDirectoryURL.path];
            
            if(success){
                NSMutableArray *parts = [URL.lastPathComponent componentsSeparatedByString:@"."].mutableCopy;
                [parts removeLastObject];
                NSString *folderName = [parts componentsJoinedByString:@"."];
                NSURL *folderURL = [self.documentDirectoryURL URLByAppendingPathComponent:folderName];
                
                // Get all json files in extracted folder
                NSArray *fileList = [fileManager contentsOfDirectoryAtPath:folderURL.path error:nil];
                for (NSString *jsonFileName in fileList) {
                    if([jsonFileName.pathExtension isEqualToString:@"json"]){
                        
                        // Decode json
                        NSString *jsonFilePath = [folderURL URLByAppendingPathComponent:jsonFileName].path;
                        NSString *json = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:nil];
                        NSArray *data = [Utils jsonDecode:json];
                        
                        // Make DownloadGroupInfo
                        NSMutableArray *downloads = [[NSMutableArray alloc] init];
                        for (NSString *downloadUrl in data) {
                            DownloadInfo *download = [[DownloadInfo alloc] initWithDownloadUrl:downloadUrl];
                            [downloads addObject:download];
                        }
                        
                        // Get title
                        NSString *title = jsonFileName.fileNameWithoutExtension;
                        DownloadGroupInfo *downloadGroup = [[DownloadGroupInfo alloc] initWithTitle:title andDownloadInfos:downloads];
                        
                        // Add to queue
                        [self.downloadQueue queueDownloadGroupInfo:downloadGroup];
                        
                    }
                    
                }
                
                // Reload table
                dispatch_async(dispatch_get_main_queue(), ^(){
                    [self registerObserveForDownloadGroups:self.downloadQueue.downloadGroups];
                    [self.tableView reloadData];
                    self.didReloadedTableView = YES;
                });
            }
            
            // Enable reset button
            dispatch_async(dispatch_get_main_queue(), ^(){
                self.resetButton.enabled = YES;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(){
                self.addButton.enabled = YES;
                alert(@"The resources not available. Please re-check your download link.");

            });
        }
        
    }];
    
    [downloadTask resume];
}

- (IBAction)connectionNumberSliderChanged:(id)sender {
    self.downloadQueue.maximumDownloadedGroup = round(self.connectionNumberSlider.value);
    self.downloadQueue.maximumDownloadedPerGroup = round(self.connectionNumberSlider.value);
    
    [self.tableView reloadData];
}
@end
