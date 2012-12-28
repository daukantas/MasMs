//
//  MasMsContactsTableViewController.m
//  MasMs
//
//  Created by Jack Qiu on 12/25/12.
//  Copyright (c) 2012 hpyhacking. All rights reserved.
//

#import "MasMsContactsTableViewController.h"
#import "MasMsContact.h"
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>

NSString * MOBILE = @"^1\\d{2}[-]{0,1}\\d{4}[-]{0,1}\\d{4}$";

@interface MasMsContactsTableViewController() 
@property (nonatomic, weak) IBOutlet UIBarButtonItem *sendButton;

@property (nonatomic) NSInteger checkedCount;
@property (nonatomic) BOOL isSending;
@property (nonatomic) NSInteger indexSection;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *people;

- (NSArray *) getReadyNumbers;
@end

@implementation MasMsContactsTableViewController

- (IBAction)scrollSection:(UIBarButtonItem *)sender {
    if (self.groups.count == 0) return;
    
    if (sender == self.scrollDown && self.indexSection + 1 < self.groups.count) self.indexSection += 1;
    if (sender == self.scrollUp && self.indexSection > 0) self.indexSection -= 1;
    
    if ([[self.people objectAtIndex:self.indexSection] count] == 0) {
        // 当前indexSection不在临界点时可继续滚动
        // 当前indexSection到达临界点时反向滚动
        if (self.indexSection > 0 && self.indexSection + 1 < self.groups.count) {
            [self scrollSection:sender];
        } else if (self.indexSection == 0) {
            [self scrollSection:self.scrollDown];
        } else if (self.indexSection + 1 == self.groups.count) {
            [self scrollSection:self.scrollUp];
        }
        
        return;
    }
    
    NSIndexPath *ndxPath = [NSIndexPath indexPathForRow:0 inSection:self.indexSection];
    [self.tableView scrollToRowAtIndexPath:ndxPath atScrollPosition:UITableViewScrollPositionTop  animated:YES];
}

- (UIProgressView *) setProgress {
    UIProgressView *progress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progress.frame = CGRectMake(0, 30-progress.frame.size.height, 200, progress.frame.size.height);
    self.navigationItem.titleView = progress;
    return progress;
}

- (void) setSpinner {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinner startAnimating];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
}

- (void) loadAddressBook {
    // 生成索引顺序相同的两个数组来存放Group (NSString) 与People (MasMsContact)
    // @[group1, group2, group3] @[@[group1_p1, group1_p2], @[group2_p1], @[]]
    
    NSString *ungrouped = NSLocalizedString(@"UNGROUPED", NULL);
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:(1 + ABAddressBookGetGroupCount(addressBook))];
    NSMutableArray *people = [NSMutableArray arrayWithCapacity:(1 + ABAddressBookGetGroupCount(addressBook))];
    NSMutableArray *ungroup_people = [(NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook)) mutableCopy];
    
    [(NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(addressBook)) enumerateObjectsUsingBlock:^(id obj_g, NSUInteger idx, BOOL *stop) {
        ABRecordRef group_ref = (__bridge ABRecordRef)obj_g;
        
        NSMutableArray *members = [[[NSArray alloc] init] mutableCopy];
        NSString *gname = (group_ref == NULL) ? ungrouped : CFBridgingRelease(ABRecordCopyCompositeName(group_ref));
        
        [(NSArray *)CFBridgingRelease(ABGroupCopyArrayOfAllMembers(group_ref)) enumerateObjectsUsingBlock:^(id obj_m, NSUInteger idx, BOOL *stop) {
            [ungroup_people removeObject:obj_m];
            [members addObjectsFromArray:[self makeContact:(__bridge ABRecordRef)obj_m withGroupName:gname]];
        }];
        
        if (members.count != 0) {
            [groups addObject:gname];
            [people addObject:members];
        }
    }];
    
    if (ungroup_people.count != 0) {
        NSMutableArray *members = [[[NSArray alloc] init] mutableCopy];
        
        [ungroup_people enumerateObjectsUsingBlock:^(id obj_m, NSUInteger idx, BOOL *stop) {
            [members addObjectsFromArray:[self makeContact:(__bridge ABRecordRef)obj_m withGroupName:ungrouped]];
        }];
    
        if (members.count != 0) {
            [groups addObject:ungrouped];
            [people addObject:members];
        }
    }
    
    CFRelease(addressBook);
    
    self.people = [people copy];
    self.groups = [groups copy];
}

- (NSArray *) makeContact:(ABRecordRef)member withGroupName:(NSString *)gname {
    NSString *pname = CFBridgingRelease(ABRecordCopyCompositeName(member));
    ABMultiValueRef numbers_ref = ABRecordCopyValue(member, kABPersonPhoneProperty);
    
    NSPredicate *regexMobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSMutableArray *result = [[[NSArray alloc] init] mutableCopy];
    
    [(NSArray *) CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(numbers_ref)) enumerateObjectsUsingBlock:^(id obj_num, NSUInteger idx, BOOL *stop) {
        NSString *pnumber = CFBridgingRelease(CFBridgingRetain(obj_num));
        
        if ([regexMobile evaluateWithObject:pnumber] == NO) {
            return;
        }
        
        MasMsContact *new_c = [[MasMsContact alloc] init];
        new_c.name = pname;
        new_c.number = pnumber;
        new_c.group = gname;
        new_c.checked = NO;
        
        [result addObject:new_c];
    }];
    
    return [result copy];
}

- (void)viewDidLoad {
    self.isSending = NO;
    
    [super viewDidLoad];
    [self loadAddressBook];
    [self setCheckCounter:0];
}

- (void)setCheckCounter:(NSInteger)count {
    if (count == 0) self.checkedCount = 0;
    if (count != 0) self.checkedCount = self.checkedCount + count;
    self.sendButton.enabled = (self.checkedCount > 0);
}

- (IBAction)send:(UIBarButtonItem *)sender {
    MFMessageComposeViewController *smsController;
    if ([MFMessageComposeViewController canSendText]) {
        smsController = [[MFMessageComposeViewController alloc] init];
        
        smsController.recipients = [self getReadyNumbers];
        smsController.body = self.message;
        smsController.messageComposeDelegate = self;
        [self presentViewController:smsController animated:YES completion:NULL];
    }
}

#pragma mark - TableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self.groups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self.people objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Contacts Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    MasMsContact *contac = [[self.people objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cell.textLabel.text = contac.name;
    cell.detailTextLabel.text = contac.number;
    cell.accessoryType = contac.checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - TableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.isSending == NO) {
        MasMsContact *contac = [[self.people objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
        contac.checked = !contac.checked;
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = contac.checked ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        [self setCheckCounter:contac.checked == YES ? 1 : -1];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor grayColor];
    
    UILabel *groupName = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, 300, 40)];
    
    groupName.text = [self.groups objectAtIndex:section];
    groupName.font = [UIFont boldSystemFontOfSize:12];
    groupName.textColor = [UIColor whiteColor];
    groupName.backgroundColor = [UIColor clearColor];
    
    UIButton * headerBtn = [[UIButton alloc] initWithFrame:CGRectZero];
    headerBtn.backgroundColor = [UIColor grayColor];
    headerBtn.frame = CGRectMake(225.0, 5.0, 100.0, 30.0);
    
    [headerBtn setTag:section];
    [headerBtn setTitle:@"Select All" forState:UIControlStateNormal];
    [headerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [headerBtn addTarget:self action:@selector(selectAll:) forControlEvents:UIControlEventTouchDown];
    
    [view addSubview:groupName];
    [view addSubview:headerBtn];
    
    return view;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 40;
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	
	
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failed"
                                                    message:@"Send message failed."
                                                   delegate:NULL
                                          cancelButtonTitle:@"I got it"
                                          otherButtonTitles:NULL];
    alert.alertViewStyle = UIAlertViewStyleDefault;
    
	[self dismissViewControllerAnimated:YES completion:^() {
        switch (result) {
            case MessageComposeResultCancelled:
                break;
            case MessageComposeResultFailed:
                [alert show];
                break;
            default:
                [self.navigationController popViewControllerAnimated:YES];
                break;
        }
    
    }];
}

#pragma mark - private

- (NSArray *) getReadyNumbers {
    NSMutableArray *numbers = [[[NSArray alloc] init] mutableCopy];
    
    [self.people enumerateObjectsUsingBlock:^(NSMutableArray *members, NSUInteger idx, BOOL *stop) {
        [members enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj checked]) [numbers addObject:[obj number]];
        }];
    }];
    
    return [numbers copy];
}

- (void) selectAll:(UIButton *)sender {
    __block BOOL allSelect = YES;
    
    [[self.people objectAtIndex:sender.tag] enumerateObjectsUsingBlock:^(MasMsContact *obj, NSUInteger idx, BOOL *stop) {
        if (!obj.checked) allSelect = NO;
        
        if (obj.checked == NO) {
            obj.checked = YES;
            [self setCheckCounter:1];
        }
    }];
    
    if (allSelect) {
        [[self.people objectAtIndex:sender.tag] enumerateObjectsUsingBlock:^(MasMsContact *obj, NSUInteger idx, BOOL *stop) {
            if (obj.checked == YES) {
                obj.checked = NO;
                [self setCheckCounter:-1];
            }
        }];
    }
    
    [self.tableView reloadData];
}

@end
