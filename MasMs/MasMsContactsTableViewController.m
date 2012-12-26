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
@property (nonatomic, strong) NSArray *groups;
@property (nonatomic, strong) NSArray *people;
@end

@implementation MasMsContactsTableViewController

- (void) loadAddressBook {
    // 生成索引顺序相同的两个数组来存放Group (NSString) 与People (MasMsContact)
    // @[group1, group2, group3] @[@[group1_p1, group1_p2], @[group2_p1], @[]]
    
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    NSMutableArray *groups = [NSMutableArray arrayWithCapacity:ABAddressBookGetGroupCount(addressBook)];
    NSMutableArray *people = [NSMutableArray arrayWithCapacity:ABAddressBookGetGroupCount(addressBook)];
    
    [(NSArray *)CFBridgingRelease(ABAddressBookCopyArrayOfAllGroups(addressBook)) enumerateObjectsUsingBlock:^(id obj_g, NSUInteger idx, BOOL *stop) {
        ABRecordRef g = (__bridge ABRecordRef)obj_g;
        NSString *gname = CFBridgingRelease(ABRecordCopyCompositeName(g));
        
        NSMutableArray *gp = [[[NSArray alloc] init] mutableCopy];
        
        [(NSArray *)CFBridgingRelease(ABGroupCopyArrayOfAllMembers(g)) enumerateObjectsUsingBlock:^(id obj_p, NSUInteger idx, BOOL *stop) {
            ABRecordRef p = (__bridge ABRecordRef)obj_p;
            ABMultiValueRef numbers = ABRecordCopyValue(p, kABPersonPhoneProperty);
            
            NSString *pname = CFBridgingRelease(ABRecordCopyCompositeName(p));
            
            [(NSArray *) CFBridgingRelease(ABMultiValueCopyArrayOfAllValues(numbers)) enumerateObjectsUsingBlock:^(id obj_n, NSUInteger idx, BOOL *stop) {
                NSString *pnumber = CFBridgingRelease(CFBridgingRetain(obj_n));
                
                MasMsContact *new_c = [[MasMsContact alloc] init];
                new_c.name = pname;
                new_c.number = pnumber;
                new_c.group = gname;
                
                [gp addObject:new_c];
            }];
            
            CFRelease(numbers);
        }];
        
        [people addObject:[gp copy]];
        [groups addObject:gname];
    }];
    
    CFRelease(addressBook);
    
    self.people = [people copy];
    self.groups = [groups copy];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadAddressBook];
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
    cell.accessoryType = (indexPath.row % 2 == 1) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - TableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
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
