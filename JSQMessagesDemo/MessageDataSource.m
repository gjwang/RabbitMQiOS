//
//  MessageDataSource.m
//  JSQMessages
//
//  Created by gjwang on 6/5/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "MessageDataSource.h"
#import "DemoModelData.h"

#import "NSUserDefaults+DemoSettings.h"

/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation MessageDataSource

- (instancetype)init: (NSString *)senderName
{
    self = [super init];
    
    NSLog(@"MessageDataSource init");
    
    if (self) {
        if ([NSUserDefaults emptyMessagesSetting]) {
            self.messages = [NSMutableArray new];
        }else {
            self.messages = [NSMutableArray new];
            NSLog(@"MessageDataSource init loadFakeMessages");
        }
        
        self.myselfId = kJSQDemoAvatarIdSquires;
        self.myselfName = kJSQDemoAvatarDisplayNameSquires;
        
        DemoModelData *modelData = [DemoModelData shareDemoDodelData];
        
        for (JSQMessage *msg in modelData.messages) {
            if ([msg.senderDisplayName isEqualToString:self.myselfName]
                ||[msg.senderDisplayName isEqualToString:senderName]
                ){
                
                //NSLog(@"msgSenderName=%@, msg.text = %@----", msg.senderDisplayName, msg.text);
                [self.messages addObject:msg];
            }
        }
        
        //NSArray *copyOfMessages = [[DemoModelData shareDemoDodelData].messages copy];
        //[self.messages addObjectsFromArray:copyOfMessages];
        
        //[self addPhotoMediaMessage];
        //[self addVideoMediaMessage];
        
        self.avatars = modelData.avatars;
        self.users = modelData.users;
        
        self.outgoingBubbleImageData = modelData.outgoingBubbleImageData;
        self.incomingBubbleImageData = modelData.incomingBubbleImageData;
    }

    
    return self;
}

- (void)addPhotoMediaMessage
{
    JSQPhotoMediaItem *photoItem = [[JSQPhotoMediaItem alloc] initWithImage:[UIImage imageNamed:@"goldengate"]];
    JSQMessage *photoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:photoItem];
    [self.messages addObject:photoMessage];
}

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion
{
    CLLocation *ferryBuildingInSF = [[CLLocation alloc] initWithLatitude:37.795313 longitude:-122.393757];
    
    JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
    [locationItem setLocation:ferryBuildingInSF withCompletionHandler:completion];
    
    JSQMessage *locationMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                      displayName:kJSQDemoAvatarDisplayNameSquires
                                                            media:locationItem];
    [self.messages addObject:locationMessage];
}

- (void)addVideoMediaMessage
{
    // don't have a real video, just pretending
    NSURL *videoURL = [NSURL URLWithString:@"file://"];
    
    JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
    JSQMessage *videoMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                   displayName:kJSQDemoAvatarDisplayNameSquires
                                                         media:videoItem];
    [self.messages addObject:videoMessage];
}

@end
