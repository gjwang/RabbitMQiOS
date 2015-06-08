//
//  RBTMessage.m
//  JSQMessages
//
//  Created by gjwang on 6/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "RBTMessage.h"

@implementation RBTMessage

- (instancetype)initWithSenderId:(NSString *)senderId
               senderDisplayName:(NSString *)senderDisplayName
                        sendToId:(NSString *)sendToId
                      sendToName:(NSString *)sendToName
                            date:(NSDate *)date
                            text:(NSString *)text
{
    NSParameterAssert(sendToId != nil);
    //NSParameterAssert(sendToName != nil);
    
    self = [super initWithSenderId:senderId
                 senderDisplayName:senderDisplayName
                              date:date
                              text:text];;
    
    
    if (self) {
        _sendToId = sendToId;
        _sendToName = sendToName;
    }
    
    return self;
}

@end
