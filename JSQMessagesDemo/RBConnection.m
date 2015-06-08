//
//  RBConnection.m
//  JSQMessages
//
//  Created by gjwang on 5/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "RBConnection.h"

NSUInteger MAX_RETRY_TIMES = 3;

NSString * const RBRecvMsgNotification = @"RecvMsgNotification";
NSString * const RBLostNotification = @"RBLostNotification";
NSString * const RBLoginFailedNotification = @"RBLoginFailedNotification";

@interface RBConnection()

@property (readwrite, nonatomic) amqp_connection_state_t conn;
@property (readwrite, nonatomic) NSUInteger retry_times;

- (NSString *)consumeMsg;
@end

@implementation RBConnection


- (instancetype)initWithReiverId: (NSString*) receiverId{
    NSParameterAssert(receiverId != nil);
    
    self = [super init];
    if (self) {
        _conn = NULL;
        _retry_times = 0;
        _rbConnStatus = RBConnLogout;
        _receiveFromId = receiverId;
    }
    return self;
}

- (RBConnStatus) login
{
    if (self.rbConnStatus == RBConnLogging /*| self.rbConnStatus == RBConnLogSuccess*/) {
        NSLog(@"rbconnecting is logging or aleady loggin");
        return self.rbConnStatus;
    }
    
    self.rbConnStatus = RBConnLogging;
    
    NSLog(@"loginRabbitMqServer");
    char const *hostname = rabbit_hostname;
    char const *username = login_rabbit_username;
    char const *password = login_rabbit_password;
    const int port = rabbit_port;
    
    amqp_connection_state_t conn = NULL;
    conn = amqp_new_connection();
    if (conn == NULL) {
        NSLog(@"amqp_new_connection failed");
        goto failed;
    }
    
    amqp_socket_t *socket = NULL;
    socket = amqp_tcp_socket_new(conn);
    if (!socket) {
        NSLog(@"creating TCP socket failed");
        goto failed;
    }
    
    int status;
    status = amqp_socket_open(socket, hostname, port);
    if (status) {
        NSLog(@"opening TCP socket failed");
        goto failed;
    }
    
    amqp_rpc_reply_t res;
    res = amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, username, password);
    
    if (AMQP_RESPONSE_NORMAL != res.reply_type) {
        NSLog(@"amqp login failed! reply_code=%d", res.reply_type);
        goto failed;
    }
    
    amqp_channel_t const channel = 1;
    amqp_channel_open(conn, channel);
    res = amqp_get_rpc_reply(conn);
    
    if (AMQP_RESPONSE_NORMAL != res.reply_type) {
        NSLog(@"amqp_channel_open failed! reply_code=%d", res.reply_type);
        goto failed;
    }
    
    self.conn = conn;
    if ([RBConnection bindRecvRabbitMq:conn
                         receiveFromId:self.receiveFromId]) {
        NSLog(@"loggin Success");
        //TODO: fire a notification to begin consuming msg
        
        self.rbConnStatus = RBConnLogSuccess;
        [self receiveMessage];
        return self.rbConnStatus;
    }else{
        NSLog(@"login failed");
        goto failed;
    }
    
failed:
    
    if (conn) {
        amqp_destroy_connection(conn);
        conn = NULL;
    }
    
    //Logining failed, fire a notification
    self.rbConnStatus = RBConnLogFailed;
    return self.rbConnStatus;
}

//Modified RBConnection Status in main queue
- (RBConnStatus) loginAsync{
    if (self.rbConnStatus == RBConnLogging /*| self.rbConnStatus == RBConnLogSuccess*/) {
        NSLog(@"rbconnecting is logging or aleady loggin");
        return self.rbConnStatus;
    }
    self.rbConnStatus = RBConnLogging;
    
    NSLog(@"loginRabbitMqServer logginAsync");

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char const *hostname = rabbit_hostname;
        char const *username = login_rabbit_username;
        char const *password = login_rabbit_password;
        const int port = rabbit_port;
        
        amqp_connection_state_t conn = NULL;
        BOOL failed = NO;
        
        conn = amqp_new_connection();
        if (conn != NULL) {
            amqp_socket_t *socket = NULL;
            socket = amqp_tcp_socket_new(conn);
            if (socket != NULL) {
                int status;
                status = amqp_socket_open(socket, hostname, port);
                if (status == AMQP_STATUS_OK) {
                    amqp_rpc_reply_t res;
                    res = amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, username, password);
                    NSLog(@"amqp_login Success");
                    
                    if (AMQP_RESPONSE_NORMAL == res.reply_type) {
                        amqp_channel_t const channel = 1;
                        amqp_channel_open(conn, channel);
                        res = amqp_get_rpc_reply(conn);
                        
                        if (AMQP_RESPONSE_NORMAL == res.reply_type) {
                            RBConnStatus rbConnStatus;
                            if ([RBConnection bindRecvRabbitMq:conn
                                                 receiveFromId:self.receiveFromId]) {
                                NSLog(@"bindRecvRabbitMq Success");
                                //TODO: fire a notification to begin consuming msg, or KVO
                                rbConnStatus = RBConnLogSuccess;
                                failed = NO;
                            }else{
                                rbConnStatus = RBConnLogFailed;
                                failed = YES;
                                
                                NSLog(@"bindRecvRabbitMq failed");
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.conn = conn;
                                self.rbConnStatus = rbConnStatus;
                                if (self.rbConnStatus == RBConnLogSuccess) {
                                    [self receiveMessage];
                                }
                            });
                        }else{
                            failed = YES;
                            NSLog(@"amqp_channel_open failed! reply_code=%d", res.reply_type);
                        }
                    }else{
                        failed = YES;
                        NSLog(@"amqp login failed! reply_code=%d", res.reply_type);
                    }
                }else{
                    failed = YES;
                    NSLog(@"opening TCP socket failed");
                }
            }else{
                failed = YES;
                NSLog(@"creating TCP socket failed");
            }
        }else{
            failed = YES;
            NSLog(@"New connection failed");
        }
        
        if (failed) {
            if (conn) {
                amqp_destroy_connection(conn);
                conn = NULL;
            }
            
            //operation on RBConnection should keep in main queue
            dispatch_async(dispatch_get_main_queue(), ^{
                self.rbConnStatus = RBConnLogFailed;
                
                NSLog(@"Fire RBConnection Login failed");
                
                NSNotification *connLost = [NSNotification notificationWithName:RBLoginFailedNotification
                                                                         object:self
                                                                       userInfo:nil
                                            ];
                [[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)connLost];
            });

        }
    });
    
    return self.rbConnStatus;
    
}

+ (BOOL) bindRecvRabbitMq:(amqp_connection_state_t) conn
            receiveFromId:(NSString *)receiveFromId
{
    NSParameterAssert(receiveFromId != nil);
    NSLog(@"receiveFromId %@", receiveFromId);
    
    char const *bindingkey = [receiveFromId UTF8String];
    char const *exchange = "amq.direct";
    
    
    if (conn != NULL) {
        amqp_channel_t const channel = 1;
        amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, channel, amqp_empty_bytes, 0, 0, 0, 1,
                                                        amqp_empty_table);
        amqp_get_rpc_reply(conn);
        
        amqp_bytes_t queuename;
        queuename = amqp_bytes_malloc_dup(r->queue);
        if (queuename.bytes == NULL) {
            NSLog(@"Out of memory while copying queue name");
            return false;
        }
        
        NSLog(@"amqp_queue_bind");
        amqp_queue_bind(conn, channel, queuename, amqp_cstring_bytes(exchange),
                        amqp_cstring_bytes(bindingkey),amqp_empty_table);
        amqp_get_rpc_reply(conn);
        
        NSLog(@"amqp_basic_consume");
        amqp_basic_consume(conn, channel, queuename, amqp_empty_bytes, 0, 1, 0, amqp_empty_table);
        amqp_get_rpc_reply(conn);
        
        amqp_bytes_free(queuename);
        return YES;
    }
    
    return NO;
}


- (NSString *)consumeMsg
{
    NSString *retString = nil;
    
    const amqp_connection_state_t conn = self.conn;
    if ( self.rbConnStatus == RBConnLogSuccess && conn != NULL ) {
        amqp_rpc_reply_t res;
        amqp_envelope_t envelope;
        
        amqp_maybe_release_buffers(conn);
        
        NSLog(@"consuming msg...");
        res = amqp_consume_message(conn, &envelope, NULL, 0);
        
        if (AMQP_RESPONSE_NORMAL != res.reply_type) {
            //TODO: something bad happed
            NSLog(@"amqp_consume_message failed, res.reply_type=%d", res.reply_type);
            self.rbConnStatus = RBConnLogout;
            return retString;
        }
        
        //NSLog(@"Delivery %u, exchange %.*s routingkey %.*s\n",
        //       (unsigned) envelope.delivery_tag,
        //       (int) envelope.exchange.len, (char *) envelope.exchange.bytes,
        //       (int) envelope.routing_key.len, (char *) envelope.routing_key.bytes);
        
        if (envelope.message.properties._flags & AMQP_BASIC_CONTENT_TYPE_FLAG) {
            NSLog(@"Content-type: %.*s\n",
                  (int) envelope.message.properties.content_type.len,
                  (char *) envelope.message.properties.content_type.bytes);
        }
        
        NSUInteger len = (NSUInteger)envelope.message.body.len;
        
        retString = [[NSString alloc] initWithBytes: envelope.message.body.bytes
                                             length: len
                                           encoding: NSUTF8StringEncoding];
        
        NSLog(@"recv nsmsg=%@", retString);
        amqp_destroy_envelope(&envelope);
    }
    
    return retString;
}

- (void) sendMessage: (RBTMessage *)msg
{
    //TODO: 1. store msg in a queue
    
    //not thread safe
    
    //NSLog(@"RBConnection sendMessage");
    
    const amqp_connection_state_t conn = self.conn;
    char const *exchange = "amq.direct";
    amqp_channel_t const channel = 1;
    
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = 2; // persistent delivery mode
    
    if (self.rbConnStatus == RBConnLogSuccess && conn != NULL) {
        char const *routingkey = [msg.sendToId UTF8String];
        //char const *sendTo = sendToId;
        //char const *routingkey = sendTo;
        char const *messagebody = [msg.text UTF8String];
        
        NSLog(@"publish routingkey = %s", routingkey);
        
        //basic.publish is an async method
        amqp_status_enum responseStatus = amqp_basic_publish(conn,
                                                             channel,
                                                             amqp_cstring_bytes(exchange),
                                                             amqp_cstring_bytes(routingkey),
                                                             0,
                                                             0,//immediate
                                                             &props,
                                                             amqp_cstring_bytes(messagebody));
        //NSLog(@"%d", responseStatus);
        if (responseStatus != AMQP_STATUS_OK) {
            NSLog(@"send msg failed %d", responseStatus);
        }
    }
}

- (void)receiveMessage
{
    dispatch_queue_t connRecvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(connRecvQueue, ^{
        while (self.rbConnStatus == RBConnLogSuccess) {
            //TODO: wait for logginSuccess Msg
            
            NSString *recvMsg = [self consumeMsg];
            
            if (recvMsg != nil) {
                NSLog(@"Post recvMsg notificatin msg=%@", recvMsg);
                NSDictionary *msgDict = @{@"RecvMsg" : recvMsg};
                
                NSNotification *recvMsgNote = [NSNotification notificationWithName:RBRecvMsgNotification
                                                                            object:self
                                                                          userInfo:msgDict
                                               ];
                [[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)recvMsgNote];
            }else{
                NSLog(@"recv msg failed");
                break;
            }
        }
        
        //operation on RBConnection should keep in main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            self.rbConnStatus = RBConnLogout;
            [self destroyConn];
        });
    });
}

- (void) close{
    //It may be called more than once, and should be OK if calls from the same main queue
    //NSLog(@"RBConnection close");
    
    self.rbConnStatus = RBConnLogout;
    
    //not directly cal destroyConn, wait for receiveMessage to breakout instead
}

- (void)destroyConn
{
    NSLog(@"destroyConn");
    self.rbConnStatus = RBConnLogout;
    
    if (self.conn) {
        //NSLog(@"amqp_channel_close ...");
        //unfortunatly, it will block by amqp_channel_close and amqp_connection_close
        //const amqp_channel_t channel = 1;
        //amqp_channel_close(conn, channel, AMQP_REPLY_SUCCESS);
        //NSLog(@"amqp_connection_close ...");
        //amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
        
        NSLog(@"amqp_destroy_connection ...");
        amqp_destroy_connection(self.conn);
        NSLog(@"ampq close OK");
    }
    
    self.conn = NULL;
    
    NSLog(@"Fire %@", RBLostNotification);
    NSNotification *connLost = [NSNotification notificationWithName:RBLostNotification
                                                             object:self
                                                           userInfo:nil
                                ];
    [[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)connLost];
}

- (void)dealloc{
    NSLog(@"RBConnetion dealloc");
}

@end
