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
    self.downloadQueue.maximumDownloadedPerGroup = 2;
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([segue.identifier isEqualToString:@"toScreenNo2Controller"]){
        ScreenNo2Controller *dstController = segue.destinationViewController;
        dstController.downloadGroup = sender;
    }
}


#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.downloadQueue.downloadGroups.count;
}

- (DownloadGroupTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadGroupTableViewCell" forIndexPath:indexPath];
    
    DownloadGroupInfo *downloadGroupInfo = self.downloadQueue.downloadGroups[indexPath.row];
    [cell updateViewsWith:downloadGroupInfo];
    
    return cell;
}
#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    DownloadGroupInfo *downloadGroupInfo = self.downloadQueue.downloadGroups[indexPath.row];
    [self performSegueWithIdentifier:@"toScreenNo2Controller" sender:downloadGroupInfo];
}

#pragma mark - DownloadQueueDelegate
-(void)downloadQueue:(DownloadQueue *)downloadQueue downloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo didFinishDownloadingToURL:(NSURL *)location{
    
    NSURL *folderURL = [self.documentDirectoryURL URLByAppendingPathComponent:downloadGroupInfo.title];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL success;
    NSURL *savedURL;
    
    
    // Handle file type
    if([downloadInfo.task.currentRequest.URL.path.pathExtension isEqualToString:@"zip"]){
        downloadInfo.status = DownloadStatusUnzipping;
        //  Notify a change of download
        [App current].downloadChangedHandler(downloadInfo, downloadGroupInfo);
        
        // Reload the cell at asscociated download group
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSInteger index = [self.downloadQueue.downloadGroups indexOfObject:downloadGroupInfo];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            DownloadGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell updateViewsWith:downloadGroupInfo];
        });
        
        NSURL *tempFolderURL = [folderURL URLByAppendingPathComponent:downloadInfo.task.currentRequest.URL.path.fileNameWithoutExtension];
        success = [SSZipArchive unzipFileAtPath:location.path toDestination:tempFolderURL.path];
        
        if(success){
            NSString *fileName = [fileManager contentsOfDirectoryAtPath:tempFolderURL.path error:nil].firstObject;
            NSURL *fileInTempUrl = [tempFolderURL URLByAppendingPathComponent:fileName];
            savedURL = [folderURL URLByAppendingPathComponent:fileName];
            [fileManager moveItemAtPath:fileInTempUrl.path toPath:savedURL.path error:nil];
            [fileManager removeItemAtPath:fileInTempUrl.path error:nil];
        }
    } else {
        // Save downloaded file to download folder
        NSError *error;
        
        NSString *filename = downloadInfo.task.currentRequest.URL.lastPathComponent;
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
    }
    
    if(success){
        downloadInfo.status = DownloadStatusUsable;
        downloadInfo.savedURL = savedURL;
    } else {
        downloadInfo.status = DownloadStatusFailed;
    }

    //  Notify a change of download
    [App current].downloadChangedHandler(downloadInfo, downloadGroupInfo);
    
    // Reload the cell at asscociated download group
    dispatch_async(dispatch_get_main_queue(), ^(){
        NSInteger index = [self.downloadQueue.downloadGroups indexOfObject:downloadGroupInfo];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        DownloadGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        [cell updateViewsWith:downloadGroupInfo];
    });
}


-(void)downloadQueue:(DownloadQueue *)downloadQueue downloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    
    if (totalBytesExpectedToWrite == NSURLSessionTransferSizeUnknown) {
        downloadInfo.status = DownloadStatusFailed;
    }
    else{
        // Calculate the progress.
        downloadInfo.progress = (double)totalBytesWritten / (double)totalBytesExpectedToWrite;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^(){
        // Reload the cell
        NSInteger index = [self.downloadQueue.downloadGroups indexOfObject:downloadGroupInfo];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        DownloadGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.progressView.progress = downloadGroupInfo.progress;
        
        [App current].downloadChangedHandler(downloadInfo, downloadGroupInfo);
    });
}
-(void)downloadQueue:(DownloadQueue *)downloadQueue didChangeDownloadInfo:(DownloadInfo *)downloadInfo downloadGroupInfo:(DownloadGroupInfo *) downloadGroupInfo{
    
    // Reload cell at asscociated download group
    if(self.didReloadedTableView){
        [App current].downloadChangedHandler(downloadInfo, downloadGroupInfo);
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSInteger index = [self.downloadQueue.downloadGroups indexOfObject:downloadGroupInfo];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            DownloadGroupTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            [cell updateViewsWith:downloadGroupInfo];
            
            
            // Update enable state for Pause/Resume button, anytime has a changed download
            self.pauseButton.enabled = self.pauseButton.tag == 1;
            for (DownloadGroupInfo *downloadGroupInfo in self.downloadQueue.downloadGroups) {
                if(downloadGroupInfo.downloadingCount > 0){
                    self.pauseButton.enabled = YES;
                    break;
                }
            }
        });
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
    UIButton *button = sender;
    button.enabled = NO;
    
    // Download package data
//    NSURL *URL = [NSURL URLWithString:@"http://localhost/JSON%20files%20updated.zip"];
    NSURL *URL = [NSURL URLWithString:@"http://markg.in/JSON%20files%20updated.zip"];
    NSURLRequest *downloadRequest = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData timeoutInterval:90];
    
    NSURLSessionDownloadTask *downloadTask = [[NSURLSession sharedSession] downloadTaskWithRequest:downloadRequest completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error){
        
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
                    NSMutableArray *downloadInfos = [[NSMutableArray alloc] init];
                    for (NSString *downloadUrl in data) {
                        DownloadInfo *downloadInfo = [[DownloadInfo alloc] initWithDownloadUrl:downloadUrl];
                        [downloadInfos addObject:downloadInfo];
                    }
                    
                    // Get title
                    NSString *title = jsonFileName.fileNameWithoutExtension;
                    DownloadGroupInfo *downloadGroupInfo = [[DownloadGroupInfo alloc] initWithTitle:title andDownloadInfos:downloadInfos];
                    
                    // Add to queue
                    [self.downloadQueue queueDownloadGroupInfo:downloadGroupInfo];
                    
                }
                
            }
            
            // Reload table
            dispatch_async(dispatch_get_main_queue(), ^(){
                [self.tableView reloadData];
                self.didReloadedTableView = YES;
            });
        }
    }];
    
    [downloadTask resume];
}

- (IBAction)connectionNumberSliderChanged:(id)sender {
    self.downloadQueue.maximumDownloadedGroup = round(self.connectionNumberSlider.value);
}
@end
