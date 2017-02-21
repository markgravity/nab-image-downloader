//
//  Alert.h
//  zacs
//
//  Created by Mark G on 1/16/17.
//  Copyright © 2017 Mark G. All rights reserved.
//

#import <UIKit/UIKit.h>

static void alert(NSString *message)
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Alert" message:message delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil, nil];
    [alertView show];

}

