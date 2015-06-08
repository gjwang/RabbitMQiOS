//
//  NetworkManager.h
//  JSQMessages
//
//  Created by gjwang on 5/5/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "RBConnection.h"

@interface NetworkManager : NSObject

@property (readwrite, nonatomic) BOOL isNetworkReachable;
@property(readwrite, nonatomic, copy) NSString *receiverId;//comsume msg from receiverId

- (void)sendMessage:(JSQMessage *)msg;

+ (instancetype)shareNetworkManager;

@end