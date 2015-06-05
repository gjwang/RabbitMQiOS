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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "DemoModelData.h"
#import "DemoMessagesViewController.h"
#import "NetworkManager.h"

@interface TableViewController : UITableViewController <JSQDemoViewControllerDelegate>

- (IBAction)unwindSegue:(UIStoryboardSegue *)sender;

@property (strong, nonatomic) DemoModelData *demoData;
@property (weak, nonatomic) NetworkManager *networkManager;
@property (strong, nonatomic) UITabBarController *tabBarController;

@end
