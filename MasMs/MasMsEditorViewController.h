//
//  MasMsEditorViewController.h
//  MasMs
//
//  Created by Jack Qiu on 12/24/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MasMsEditorViewControllerDelegate.h"

@interface MasMsEditorViewController : UIViewController

@property (nonatomic, strong) NSString *sms; // edit SMS content
@property (nonatomic, weak) id delegate;

@end
