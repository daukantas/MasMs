//
//  MasMsEditorViewController.h
//  MasMs
//
//  Created by Jack Qiu on 12/24/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MasMsEditorViewController : UIViewController

@property (nonatomic) NSInteger sms_index; // edit SMS index in templates
@property (nonatomic, strong) NSString *sms; // edit SMS content

@end
