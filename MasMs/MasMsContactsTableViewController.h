//
//  MasMsContactsTableViewController.h
//  MasMs
//
//  Created by Jack Qiu on 12/25/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@interface MasMsContactsTableViewController : UITableViewController <MFMessageComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scrollDown;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scrollUp;
@property (nonatomic, strong) NSString *message;
@end
