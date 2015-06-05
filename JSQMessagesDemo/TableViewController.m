//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "TableViewController.h"
#import "DemoSettingsViewController.h"

@interface TableViewController(){
    NSUInteger userNumber;
    NSArray *userNamesArray;
}

@end

@implementation TableViewController

#pragma mark - View lifecycle

- (id) init
{
    self = [super init];
    if (self) {
        self.title = NSLocalizedString(@"JSQMessagesViewController", @"JSQMessagesViewController");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"History";
    
    self.demoData = [[DemoModelData alloc] init];
    
    userNumber = [self.demoData.users count];
    userNamesArray = [self.demoData.users allValues];
    
    self.networkManager = [NetworkManager shareNetworkManager];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 1) {
        return 1;
    }

    return userNumber;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        NSLog(@"cell is nill");
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if (indexPath.section == 0) {
        cell.textLabel.text = userNamesArray[indexPath.row];
        
    }else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Settings";
                break;
        }
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return @"History";
        case 1:
            return @"Demo options";
        default:
            return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return (section == [tableView numberOfSections] - 1) ? @"Copyright © 2014\nJesse Squires\nMIT License" : nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        //
        NSString *senderName = userNamesArray[indexPath.row];
        NSLog(@"performSegueWithIdentifier senderName= %@", senderName);
        
        [self performSegueWithIdentifier:@"seguePushDemoVC" sender:senderName];
    }else if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"SegueToSettings" sender:self];
    }
}

#pragma mark - Table view delete
/*
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
           editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}
*/

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    //NSLog(@"prepareForSegue id=%@, name=%@", segue.identifier, sender);
    
    if ([segue.identifier isEqualToString:@"seguePushDemoVC"]) {
        
        DemoMessagesViewController *msgViewController = segue.destinationViewController;
        msgViewController.senderName = sender;
    }
}

- (IBAction)unwindSegue:(UIStoryboardSegue *)sender { }

#pragma mark - Demo delegate

- (void)didDismissJSQDemoViewController:(DemoMessagesViewController *)vc
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) dealloc{
    NSLog(@"TableViewController dealloc");
}

@end
