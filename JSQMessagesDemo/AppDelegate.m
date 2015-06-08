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

#import "AppDelegate.h"

#import "NSUserDefaults+DemoSettings.h"
//#import "DemoSettingsViewController.h"
//#import "ChatMessagesViewController.h"
//#import "TableViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Load our default settings
    [NSUserDefaults saveIncomingAvatarSetting:YES];
    [NSUserDefaults saveOutgoingAvatarSetting:YES];

/*
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    UIViewController *settingViewController = [[DemoSettingsViewController alloc] init];
    UIViewController *jsqMsgViewController = [[ChatMessagesViewController alloc] init];
    UIViewController *tableViewConntroller = [[TableViewController alloc] init];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[settingViewController, jsqMsgViewController, tableViewConntroller];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
*/
    return YES;
}

@end
