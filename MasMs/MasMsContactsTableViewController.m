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

@interface MasMsContactsTableViewController ()
@property (nonatomic, weak) IBOutlet UIBarButtonItem *sendButton;

@property (nonatomic) NSInteger checkedCount;
@property (nonatomic) BOOL isSending;
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *people;
@end

@implementation MasMsContactsTableViewController

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
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:(1 + ABAddressBookGetGroupCount(addressBook))];
    NSMutableArray *people = [NSMutableArray arrayWithCapacity:(1 + ABAddressBookGetGroupCount(addressBook))];
    
    [(NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(addressBook)) enumerateObjectsUsingBlock:^(id obj_g, NSUInteger idx, BOOL *stop) {
        ABRecordRef g = (__bridge ABRecordRef)obj_g;
        [groups addObject:CFBridgingRelease(ABRecordCopyCompositeName(g))];
        [people addObject:[[[NSArray alloc] init] mutableCopy]];
    }];
    
    NSString *ungrouped = NSLocalizedString(@"UNGROUPED", NULL);
    
    [groups addObject:ungrouped];
    [people addObject:[[[NSArray alloc] init] mutableCopy]];
    
    [(NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllPeople(addressBook)) enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ABRecordRef ref = (__bridge ABRecordRef)obj;
        ABRecordRef group_ref = ABAddressBookGetGroupWithRecordID(addressBook, ABRecordGetRecordID(ref));
        ABMultiValueRef numbers_ref = ABRecordCopyValue(ref, kABPersonPhoneProperty);
        
        NSString *pname = CFBridgingRelease(ABRecordCopyCompositeName(ref));
        NSString *gname = (group_ref == NULL) ? ungrouped : CFBridgingRelease(ABRecordCopyCompositeName(group_ref));
        
        NSMutableArray *gpeople = [people objectAtIndex:[groups indexOfObject:gname]];
        
        [(NSArray *) CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(numbers_ref)) enumerateObjectsUsingBlock:^(id num, NSUInteger idx, BOOL *stop) {
            NSString *pnumber = CFBridgingRelease(CFBridgingRetain(num));
            
            MasMsContact *new_c = [[MasMsContact alloc] init];
            new_c.name = pname;
            new_c.number = pnumber;
            new_c.group = gname;
            new_c.checked = NO;
            
            [gpeople addObject:new_c];
        }];
        
        CFRelease(numbers_ref);
    }];
    
    CFRelease(addressBook);
    
    self.people = [people copy];
    self.groups = [groups copy];
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
    self.isSending = YES;
    
    [self setSpinner];
    
    UIView *originLabel = self.navigationItem.titleView;
    UIProgressView *progress = [self setProgress];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *col = [[NSMutableArray alloc] init];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"checked == YES"];
        
        for (NSArray *array in self.people) {
            [col addObjectsFromArray:[array filteredArrayUsingPredicate:predicate]];
        }
        
        [col enumerateObjectsUsingBlock:^(MasMsContact *obj, NSUInteger idx, BOOL *stop) {
            NSLog(@"simulator send message to %@", obj.name);
            
            float rate = [[NSNumber numberWithUnsignedInteger:(idx + 1)] floatValue] / col.count;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [progress setProgress:rate animated:YES];
            });
            
            sleep(1.5);
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.isSending = NO;
            self.navigationItem.rightBarButtonItem = sender;
            self.navigationItem.titleView = originLabel;
        });
    });
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
    
    CGRect rect = CGRectMake(5, 0, 300, 30);
    UILabel *label = [[UILabel alloc] initWithFrame:rect];
    
    label.text = [self.groups objectAtIndex:section];
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [UIColor clearColor];
    
    view.backgroundColor = [UIColor grayColor];
    [view addSubview:label];
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

@end
