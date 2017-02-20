//
//  DownloadManagerController.h
//  image-downloader
//
//  Created by Mark G on 2/18/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "ViewController.h"
#import "DownloadQueue.h"

@interface ScreenNo1Controller : ViewController<DownloadQueueDelegate, UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseBarButton;
@property (weak, nonatomic) IBOutlet UIButton *pauseButton;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISlider *connectionNumberSlider;


- (IBAction)resetButtonTouchUp:(id)sender;
- (IBAction)pauseButtonTouchUp:(id)sender;
- (IBAction)addButtonTouchUp:(id)sender;
- (IBAction)connectionNumberSliderChanged:(id)sender;

@end
