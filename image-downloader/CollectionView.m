//
//  CollectionView.m
//  image-downloader
//
//  Created by Mark G on 2/20/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "CollectionView.h"

@implementation CollectionView
-(void) awakeFromNib{
    [super awakeFromNib];
    [self setup];
}
- (void) prepareForInterfaceBuilder{
    [self setup];
}
-(void) setup{
    if(self.numberOfColumns > 0){
        UICollectionViewFlowLayout *flow = (UICollectionViewFlowLayout*) self.collectionViewLayout;
        CGFloat width = [UIScreen mainScreen].bounds.size.width - self.contentInset.left - self.contentInset.right - (flow.minimumInteritemSpacing * (self.numberOfColumns-1));
        flow.itemSize = CGSizeMake(width/self.numberOfColumns, flow.itemSize.height);

    }
}
@end
