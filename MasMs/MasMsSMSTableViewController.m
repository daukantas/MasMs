//
//  MasMsSMSTableViewController.m
//  MasMs
//
//  Created by Jack Qiu on 12/24/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import "MasMsSMSTableViewController.h"
#import "MasMsEditorViewController.h"
#import "MasMsEditorViewControllerDelegate.h"
#import <AddressBook/AddressBook.h>

#define HAS_RUN_APP_ONCE_KEY @"hasRunAppOnceKey"
#define TEMPLATES_KEY @"templateKey"
#define NEW_TEMPLATE_INDEX -1

@interface MasMsSMSTableViewController () <MasMsEditorViewControllerDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) NSArray *templates;
@property (nonatomic) NSInteger index;
@property (nonatomic) BOOL canLoadContacts;
@end

@implementation MasMsSMSTableViewController

- (void)saveSMS:(NSString *)sms {
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *templates = [[defaults arrayForKey:TEMPLATES_KEY] mutableCopy];
    
    if (self.index == NEW_TEMPLATE_INDEX) {
        [templates addObject:sms];
    } else {
        [templates replaceObjectAtIndex:self.index withObject:sms];
    }
    
   [defaults setObject:templates forKey:TEMPLATES_KEY];
   [defaults synchronize];
   [self.tableView reloadData];
}

- (IBAction)new:(id)sender {
    self.index = NEW_TEMPLATE_INDEX;
    [self performSegueWithIdentifier:@"SMS Editor" sender:self];
}

- (NSArray *) templates {

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey:HAS_RUN_APP_ONCE_KEY] == NO) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultSMS" ofType:@"plist"];
        NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
        NSArray *default_templates = [dict objectForKey:@"DefaultTemplates"];
        
        [defaults setObject:default_templates forKey:TEMPLATES_KEY];
        [defaults setBool:YES forKey:HAS_RUN_APP_ONCE_KEY];
        [defaults synchronize];
    }
    
    return [defaults arrayForKey:TEMPLATES_KEY];
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)alertPrivacy {
    self.canLoadContacts = NO;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warnning"
                                                    message:@"Please check your Contacts Privacy setting."
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:NULL];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    [alert show];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
    
    if (status == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
            self.canLoadContacts = granted;
        });
        CFRelease(addressBook);
    } else if (status == kABAuthorizationStatusDenied || status == kABAuthorizationStatusRestricted) {
        [self alertPrivacy];
    } else if (status == kABAuthorizationStatusAuthorized) {
        self.canLoadContacts = YES;
    }
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SMS Editor"]) {
        NSString *sms = self.index == NEW_TEMPLATE_INDEX ? @"" : [self.templates objectAtIndex:self.index];
        MasMsEditorViewController *editor = segue.destinationViewController;
        editor.delegate = self;
        [editor setSms:sms];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.templates count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SMS Template";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *sms = [self.templates objectAtIndex:indexPath.row];
    cell.textLabel.text = sms;
  
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    self.index = indexPath.row;
    [self performSegueWithIdentifier:@"SMS Editor" sender:self];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (! self.canLoadContacts) {
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        [self alertPrivacy];
    } else {
        [self performSegueWithIdentifier:@"Choose Contacts" sender:self];
    }
}

@end
