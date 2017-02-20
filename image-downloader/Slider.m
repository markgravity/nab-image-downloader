//
//  Slider.m
//  image-downloader
//
//  Created by Mark G on 2/20/17.
//  Copyright © 2017 MarkG. All rights reserved.
//

#import "Slider.h"
#import "Utils.h"

@implementation Slider

-(void)endTrackingWithTouch:(UITouch *)touch
                  withEvent:(UIEvent *)event
{
    [super endTrackingWithTouch:touch withEvent:event];
    if (self.value != floorf(self.value))
    {
        CGFloat roundedFloat = (float)roundf(self.value);
        [self setValue:roundedFloat animated:YES];
    }
}

-(void)drawRect:(CGRect)rect
{
    CGFloat thumbOffset = self.currentThumbImage.size.width / 2.0f;
    NSInteger numberOfTicksToDraw = roundf(self.maximumValue - self.minimumValue) + 1;
    CGFloat distMinTickToMax = self.frame.size.width - (2 * thumbOffset);
    CGFloat distBetweenTicks = distMinTickToMax / ((float)numberOfTicksToDraw - 1);
    
    CGFloat xTickMarkPosition = thumbOffset; //will change as tick marks are drawn across slider
    CGFloat yTickMarkStartingPosition = self.frame.size.height / 2 - 4; //will not change
    CGFloat yTickMarkEndingPosition = yTickMarkStartingPosition+8; //will not change
    UIBezierPath *tickPath = [UIBezierPath bezierPath];
    for (int i = 0; i < numberOfTicksToDraw; i++)
    {
        if(i == 0 || i == numberOfTicksToDraw-1) {
            xTickMarkPosition += distBetweenTicks;
            continue;
        }
        
        [tickPath moveToPoint:CGPointMake(xTickMarkPosition, yTickMarkStartingPosition)];
        [tickPath addLineToPoint:CGPointMake(xTickMarkPosition, yTickMarkEndingPosition)];
        xTickMarkPosition += distBetweenTicks;
    }
    tickPath.lineWidth = 2;
    [[Utils colorFromHexString:@"#b7b6b7"] setStroke];
    [tickPath stroke];
}

@end
