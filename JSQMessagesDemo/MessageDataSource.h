//
//  MessageDataSource.h
//  JSQMessages
//
//  Created by gjwang on 6/5/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "JSQMessages.h"
#import "amqp_tcp_socket.h"

/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@interface MessageDataSource : NSObject

@property (strong, nonatomic)NSString *myselfId;
@property (strong, nonatomic)NSString *myselfName;

@property (strong, nonatomic) NSDictionary *avatars;
@property (strong, nonatomic) NSDictionary *users;
@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;
@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

- (instancetype)init:(NSString *)senderName;

- (void)addPhotoMediaMessage;
- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;
- (void)addVideoMediaMessage;
@end
