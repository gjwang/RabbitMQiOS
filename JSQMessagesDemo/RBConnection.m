//
//  RBConnection.m
//  JSQMessages
//
//  Created by gjwang on 5/8/15.
//  Copyright (c) 2015 Hexed Bits. All rights reserved.
//

#import "RBConnection.h"

@interface RBConnection()

@property (readwrite, nonatomic) amqp_connection_state_t conn;
@property (readwrite, nonatomic) BOOL stop;

- (NSString *)consumeMsg;
@end

@implementation RBConnection

- (instancetype)init{
    self = [super init];
    if (self) {
        self.isLoginSuccess = NO;
        self.isLogging = NO;
        self.conn = NULL;
    }
    return self;
}

- (BOOL) login
{
    if (self.isLogging) {
        NSLog(@"rbconnecting is logging...");
    }
    
    self.isLogging = YES;
    
    NSLog(@"loginRabbitMqServer");
    char const *hostname = rabbit_hostname;
    char const *username = login_rabbit_username;
    char const *password = login_rabbit_password;
    const int port = rabbit_port;
    
    self.isLoginSuccess = NO;
    
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
    if ([self bindRecvRabbitMq]) {
        NSLog(@"loggin Success");
        //TODO: fire a notification to begin consuming msg
        
        self.isLoginSuccess = YES;
        self.isLogging = NO;
        [self receiveMessage];
        return self.isLoginSuccess;
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
    self.isLogging = NO;
    return self.isLoginSuccess;
}

- (BOOL) bindRecvRabbitMq
{
    char const *exchange = "amq.direct";
    
    char const * selfId = "iphoneguy";
    char const *recvRoutingkey = selfId;
    char const *bindingkey = recvRoutingkey;
    
    amqp_connection_state_t const conn = self.conn;
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

NSString * const RecvMsgNotification = @"RecvMsgNotification";
NSString * const ConnectionLostNotification = @"ConnectionLostNotification";


- (NSString *)consumeMsg
{
    NSString *retString = nil;
    
    const amqp_connection_state_t conn = self.conn;
    if ( self.isLoginSuccess && conn != NULL ) {
        amqp_rpc_reply_t res;
        amqp_envelope_t envelope;
        
        amqp_maybe_release_buffers(conn);
        
        NSLog(@"consuming msg...");
        res = amqp_consume_message(conn, &envelope, NULL, 0);
        
        if (AMQP_RESPONSE_NORMAL != res.reply_type) {
            //TODO: something bad happed
            NSLog(@"amqp_consume_message failed, res.reply_type=%d", res.reply_type);
            _stop = YES;
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


- (void) sendMessage: (JSQMessage *)msg
{
    //TODO: 1. store msg in a queue

    const amqp_connection_state_t conn = self.conn;
    char const *exchange = "amq.direct";
    amqp_channel_t const channel = 1;
    
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = 2; // persistent delivery mode
    
    if (self.isLoginSuccess && conn != NULL) {
        //char const *routingkey = [msg.senderId UTF8String];
        char const *routingkey = "pythonguy";
        char const *messagebody = [msg.text UTF8String];
        
        amqp_status_enum responseStatus = amqp_basic_publish(conn,
                                                             channel,
                                                             amqp_cstring_bytes(exchange),
                                                             amqp_cstring_bytes(routingkey),
                                                             0,
                                                             0,
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
    if (!_isLoginSuccess | _stop) {
        return;
    }
    
    dispatch_queue_t connRecvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(connRecvQueue, ^{
        while (!_stop) {
            //TODO: wait for logginSuccess Msg
            
            NSString *recvMsg = [self consumeMsg];
            
            if (recvMsg != nil) {
                NSLog(@"Post recvMsg notificatin msg=%@", recvMsg);
                NSDictionary *msgDict = @{@"RecvMsg" : recvMsg};
                
                NSNotification *recvMsgNote = [NSNotification notificationWithName:RecvMsgNotification
                                                                            object:self
                                                                          userInfo:msgDict
                                               ];
                [[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)recvMsgNote];
            }else{
                //operation on RBConnection should keep in main queue
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"Fire ConnectionLostNotification");
                    NSNotification *connLost = [NSNotification notificationWithName:ConnectionLostNotification
                                                                             object:self
                                                                           userInfo:nil
                                                ];
                    [[NSNotificationCenter defaultCenter] postNotification:(NSNotification *)connLost];
                });
                
                break;
            }
        }
        
        //operation on RBConnection should keep in main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self destroyConn];
        });
        
    });
}

- (void) close{
    _isLoginSuccess = NO;
    _stop = YES;
}

- (void)destroyConn
{
    NSLog(@"destroyConn");
    self.isLoginSuccess = NO;
    
    if (self.conn) {
        //NSLog(@"amqp_channel_close ...");
        //unfortunatly, it will block by amqp_channel_close and amqp_connection_close
        //const amqp_channel_t channel = 1;
        //amqp_channel_close(conn, channel, AMQP_REPLY_SUCCESS);
        //NSLog(@"amqp_connection_close ...");
        //amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
        
        NSLog(@"amqp_destroy_connection ...");
        amqp_destroy_connection(self.conn);
        NSLog(@"close OK");
    }
    
    self.conn = NULL;
    
}

- (void)dealloc{
    NSLog(@"RBConnetion dealloc");
    [self close];
}

@end
