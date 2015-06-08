//
//  RBTMessage.h
//  JSQMessages
//
//  Created by gjwang on 6/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "JSQMessage.h"

@interface RBTMessage : JSQMessage
@property(nonatomic, readonly, copy)NSString *sendToName;
@property(nonatomic, readonly, copy)NSString *sendToId;

- (instancetype)initWithSenderId:(NSString *)senderId
               senderDisplayName:(NSString *)senderDisplayName
                        sendToId:(NSString *)sendToId
                      sendToName:(NSString *)sendToName
                            date:(NSDate *)date
                            text:(NSString *)text;
@end
