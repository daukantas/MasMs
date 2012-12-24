//
//  MasMsEditorViewController.m
//  MasMs
//
//  Created by Jack Qiu on 12/24/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import "MasMsEditorViewController.h"

@interface MasMsEditorViewController ()
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation MasMsEditorViewController
- (IBAction)save:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.textView becomeFirstResponder];
    
    if (self.sms) self.textView.text = self.sms;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
