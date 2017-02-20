//
//  ScreenNo3Controller.m
//  image-downloader
//
//  Created by Mark G on 2/19/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "ScreenNo3Controller.h"
#import "DownloadGroupInfo.h"
#import "DownloadInfo.h"
#import "App.h"
#import "PDFUtility.h"
#import "ScreenNo2Controller.h"

@interface ScreenNo3Controller ()
@property (nonatomic) NSInteger currentIndex;
@end

@implementation ScreenNo3Controller

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Hidden navigation bar
    [self.navigationController setNavigationBarHidden:YES];
    
    // Setup initial views
    self.currentIndex = self.initialIndex;
    [self updateViews];
    
    // Update on change
    __weak ScreenNo3Controller *weakSelf = self;
    DownloadInfo *currentDownloadInfo = self.downloadGroup.downloadInfos[self.currentIndex];
    [App current].downloadChangedHandler = ^(DownloadInfo *downloadInfo, DownloadGroupInfo *downloadGroupInfo){
        if(currentDownloadInfo == downloadInfo){
             [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                 [weakSelf updateViews];
             }];
        }
    };
    
    // Register a swipe
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRightToLeft)];
    [swipeGesture setNumberOfTouchesRequired:1];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [self.view addGestureRecognizer:swipeGesture];
    
    swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeftToRight)];
    [swipeGesture setNumberOfTouchesRequired:1];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeGesture];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.navigationController setNavigationBarHidden:NO];
}
-(void) updateViews{
    DownloadInfo *downloadInfo = self.downloadGroup.downloadInfos[self.currentIndex];
    
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.image = nil;
    
    if(downloadInfo.status == DownloadStatusUsable){
        UIImage *image;
        if([downloadInfo.savedURL.path.pathExtension isEqualToString:@"pdf"]){
            image = ImageFromPDFFile(downloadInfo.savedURL.path, self.imageView.frame.size);
            self.imageView.backgroundColor = [UIColor whiteColor];
            
        } else {
            image = [UIImage imageWithContentsOfFile:downloadInfo.savedURL.path];
        }
        
        self.imageView.image = image;
    }
    
    self.pageLabel.text = [NSString stringWithFormat:@"%@/%@",
                           @(self.currentIndex+1).stringValue,
                           @(self.downloadGroup.downloadInfos.count)];
}

-(void) swipeRightToLeft{
    self.currentIndex++;
    if(self.currentIndex >= self.downloadGroup.downloadInfos.count){
        self.currentIndex = self.downloadGroup.downloadInfos.count-1;
        return;
    }
    
    [self updateViews];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromRight];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[self.imageView layer] addAnimation:animation forKey:nil];
}

-(void) swipeLeftToRight{
    self.currentIndex--;
    if(self.currentIndex < 0){
        self.currentIndex = 0;
        return;
    }
    
    [self updateViews];
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.5];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromLeft];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [[self.imageView layer] addAnimation:animation forKey:nil];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)cancelButtonTouchUp:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    ScreenNo2Controller *controller = self.navigationController.viewControllers.lastObject;
    [controller.collectionView reloadData];
}
@end
