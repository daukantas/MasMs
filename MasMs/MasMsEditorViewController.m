//
//  MasMsEditorViewController.m
//  MasMs
//
//  Created by Jack Qiu on 12/24/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import "MasMsEditorViewController.h"

@interface MasMsEditorViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@end

@implementation MasMsEditorViewController

- (BOOL)checkSMS {
    NSString *value = [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

    return ([value length] != 0) ? YES : NO;
}

- (void)textViewDidChange:(UITextView *)textView {
    self.saveButton.enabled = [self checkSMS];
}

- (IBAction)save:(id)sender {
    if ([self checkSMS]) {
        [self.delegate saveSMS:self.textView.text];
        [self.navigationController popViewControllerAnimated:YES];
    }
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
    
    self.textView.text = self.sms;
    self.textView.delegate = self;
    self.saveButton.enabled = [self checkSMS];
    
    [self.textView becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
