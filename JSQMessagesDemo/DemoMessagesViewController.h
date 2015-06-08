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


// Import all the things
//#import "JSQMessages.h"
#import "RBTMessage.h"

#import "MessageDataSource.h"
#import "NSUserDefaults+DemoSettings.h"
#import "NetworkManager.h"


@class DemoMessagesViewController;

@protocol JSQDemoViewControllerDelegate <NSObject>

- (void)didDismissJSQDemoViewController:(DemoMessagesViewController *)vc;

@end




@interface DemoMessagesViewController : JSQMessagesViewController <UIActionSheetDelegate>

@property (weak, nonatomic) id<JSQDemoViewControllerDelegate> delegateModal;

@property (strong, nonatomic) MessageDataSource *messageDataSource;
@property (strong, nonatomic) NSString *sendToName;
@property (strong, nonatomic) NSString *sendToId;

@property (strong, nonatomic) NSNotificationCenter *recvMsgNotificationCenter;
@property (strong, nonatomic) id recvMsgObserver;

@property (weak, nonatomic) NetworkManager *networkManager;

- (void)receiveMessagePressed:(UIBarButtonItem *)sender;

- (void)closePressed:(UIBarButtonItem *)sender;

@end
