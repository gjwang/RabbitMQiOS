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

#import "DemoModelData.h"

#import "NSUserDefaults+DemoSettings.h"
#import "amqp_tcp_socket.h"


/**
 *  This is for demo/testing purposes only.
 *  This object sets up some fake model data.
 *  Do not actually do anything like this.
 */

@implementation DemoModelData

- (instancetype)init
{
    self = [super init];
    
    NSLog(@"DemoModelData init");
    
    if (self) {
        
        if ([NSUserDefaults emptyMessagesSetting]) {
            self.messages = [NSMutableArray new];
        }
        else {
            NSLog(@"DemoModelData init loadFakeMessages");

            [self loadFakeMessages];
        }
        
        
        /**
         *  Create avatar images once.
         *
         *  Be sure to create your avatars one time and reuse them for good performance.
         *
         *  If you are not using avatars, ignore this.
         */
        JSQMessagesAvatarImage *jsqImage = [JSQMessagesAvatarImageFactory avatarImageWithUserInitials:@"JSQ"
                                                                                      backgroundColor:[UIColor colorWithWhite:0.85f alpha:1.0f]
                                                                                            textColor:[UIColor colorWithWhite:0.60f alpha:1.0f]
                                                                                                 font:[UIFont systemFontOfSize:14.0f]
                                                                                             diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *cookImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_cook"]
                                                                                       diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *jobsImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_jobs"]
                                                                                       diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        JSQMessagesAvatarImage *wozImage = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"demo_avatar_woz"]
                                                                                      diameter:kJSQMessagesCollectionViewAvatarSizeDefault];
        
        self.avatars = @{ kJSQDemoAvatarIdSquires : jsqImage,
                          kJSQDemoAvatarIdCook : cookImage,
                          kJSQDemoAvatarIdJobs : jobsImage,
                          kJSQDemoAvatarIdWoz : wozImage };
        
        
        self.users = @{ kJSQDemoAvatarIdJobs : kJSQDemoAvatarDisplayNameJobs,
                        kJSQDemoAvatarIdCook : kJSQDemoAvatarDisplayNameCook,
                        kJSQDemoAvatarIdWoz : kJSQDemoAvatarDisplayNameWoz,
                        kJSQDemoAvatarIdSquires : kJSQDemoAvatarDisplayNameSquires };
        
        
        /**
         *  Create message bubble images objects.
         *
         *  Be sure to create your bubble images one time and reuse them for good performance.
         *
         */
        JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
        
        self.outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
        self.incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleGreenColor]];
    }
    
    [self connToTheRabbitMqServer];
    
    return self;
}


//TODO: use the same connection with send msg connection
- (void) connRecvRabbitMq
{
    NSLog(@"receivConnRabbitMq");
    
    
    char const *hostname = "localhost";
    char const *username = "test";
    char const *password = "test";
    
    int port = 5672;
    int status;
    char const *exchange = "amq.direct";
    //char const *exchange = "";
    char const *routingkey = "pythonguy";
    amqp_socket_t *socket = NULL;
    amqp_connection_state_t conn;
    
    amqp_bytes_t queuename;
    
    char const *bindingkey = routingkey;
    
    NSLog(@"amqp_new_connection");
    conn = amqp_new_connection();
    
    socket = amqp_tcp_socket_new(conn);
    if (!socket) {
        NSLog(@"creating TCP socket");
    }
    
    NSLog(@"amqp_socket_open");
    status = amqp_socket_open(socket, hostname, port);
    if (status) {
        NSLog(@"opening TCP socket failed");
        return;
    }
    
    NSLog(@"amqp_login");
    amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, username, password);
    amqp_channel_open(conn, 1);
    
    amqp_get_rpc_reply(conn);
    
    {
        amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, amqp_empty_bytes, 0, 0, 0, 1,
                                                        amqp_empty_table);
        amqp_get_rpc_reply(conn);
        queuename = amqp_bytes_malloc_dup(r->queue);
        if (queuename.bytes == NULL) {
            NSLog(@"Out of memory while copying queue name");
            return;
        }
    }
    
    NSLog(@"amqp_queue_bind");
    amqp_queue_bind(conn, 1, queuename, amqp_cstring_bytes(exchange), amqp_cstring_bytes(bindingkey),
                    amqp_empty_table);
    amqp_get_rpc_reply(conn);
    
    NSLog(@"amqp_basic_consume");
    amqp_basic_consume(conn, 1, queuename, amqp_empty_bytes, 0, 1, 0, amqp_empty_table);
    amqp_get_rpc_reply(conn);
    
    self.recvConn = conn;
    //connecting = true;
}

- (NSString *)consumeMsg{
    NSLog(@"consumeMsg");
    NSString *retString = nil;
    
    const amqp_connection_state_t conn = self.recvConn;
    amqp_rpc_reply_t res;
    amqp_envelope_t envelope;
            
    amqp_maybe_release_buffers(conn);
            
    NSLog(@"consuming msg...");
    res = amqp_consume_message(conn, &envelope, NULL, 0);
            
    //NSLog(@"amqp_consume_message END");
            
    if (AMQP_RESPONSE_NORMAL != res.reply_type) {
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
            
    //NSLog(@"recv msg= %.*s\n",
    //      (int) envelope.message.body.len, (char *) envelope.message.body.bytes);
            
    NSUInteger len = (NSUInteger)envelope.message.body.len;
    
    retString = [[NSString alloc] initWithBytes: envelope.message.body.bytes
                                         length: len
                                       encoding: NSUTF8StringEncoding];
            
            
    NSLog(@"recv nsmsg=%@", retString);
    amqp_destroy_envelope(&envelope);
    
    return retString;
}


//where to call closeRecvConn
- (void)closeRecvConn{
    NSLog(@"closeRecvConn");
    const amqp_connection_state_t conn = self.recvConn;
    
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);
}

- (void)connToTheRabbitMqServer
{
    NSLog(@"connToTheRabbitMqServer conn init");
    
    char const *hostname = "localhost";
    char const *username = "test";
    char const *password = "test";
    
    int port = 5672;
    int status;
    char const *exchange = "amq.direct";
    //char const *exchange = "";
    char const *routingkey = "pythonguy";
    //char const *messagebody = "hello, world!";
    //char const *messagebody = [message.text UTF8String];
    amqp_socket_t *socket = NULL;
    amqp_connection_state_t conn;
    
    conn = amqp_new_connection();
    socket = amqp_tcp_socket_new(conn);
    if (!socket) {
        NSLog(@"creating TCP socket failed");
    }
    
    status = amqp_socket_open(socket, hostname, port);
    if (status) {
        NSLog(@"opening TCP socket failed");
    }
    
    amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, username, password);
    
    amqp_channel_open(conn, 1);
    amqp_get_rpc_reply(conn);
    
    self.conn = conn;
    self.exchange = [NSString stringWithFormat:@"%s", exchange];
    self.routingkey = [NSString stringWithFormat:@"%s", routingkey];
}
- (void) sendMessage: (NSString *)msg
{
    //[self connToTheRabbitMqServer];
    
    const amqp_connection_state_t conn = self.conn;
    char const *exchange = [self.exchange UTF8String];
    char const *routingkey = [self.routingkey UTF8String];
    char const *messagebody = [msg UTF8String];
    
    amqp_basic_properties_t props;
    props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
    props.content_type = amqp_cstring_bytes("text/plain");
    props.delivery_mode = 2; // persistent delivery mode
    amqp_status_enum responseStatus = amqp_basic_publish(conn,
                                                         1,
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
    
    //[self closeConnOfTheRabbitMqServer];
}

//TODO: where to call close?
- (void) closeConnOfTheRabbitMqServer{
    NSLog(@"closeConnOfTheRabbitMqServer");
    
    const amqp_connection_state_t conn = self.conn;
    
    amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS);
    amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
    amqp_destroy_connection(conn);
}


- (void)loadFakeMessages
{
    /**
     *  Load some fake messages for demo.
     *
     *  You should have a mutable array or orderedSet, or something.
     */
    self.messages = [[NSMutableArray alloc] initWithObjects:
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdSquires
                                        senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                                     date:[NSDate distantPast]
                                                     text:@"Welcome to JSQMessages: A messaging UI framework for iOS."],
                     
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdWoz
                                        senderDisplayName:kJSQDemoAvatarDisplayNameWoz
                                                     date:[NSDate distantPast]
                                                     text:@"It is simple, elegant, and easy to use. There are super sweet default settings, but you can customize like crazy."],
                     
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdSquires
                                        senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                                     date:[NSDate distantPast]
                                                     text:@"It even has data detectors. You can call me tonight. My cell number is 123-456-7890. My website is www.hexedbits.com."],
                     
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdJobs
                                        senderDisplayName:kJSQDemoAvatarDisplayNameJobs
                                                     date:[NSDate date]
                                                     text:@"JSQMessagesViewController is nearly an exact replica of the iOS Messages App. And perhaps, better."],
                     
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdCook
                                        senderDisplayName:kJSQDemoAvatarDisplayNameCook
                                                     date:[NSDate date]
                                                     text:@"It is unit-tested, free, open-source, and documented."],
                     
                     [[JSQMessage alloc] initWithSenderId:kJSQDemoAvatarIdSquires
                                        senderDisplayName:kJSQDemoAvatarDisplayNameSquires
                                                     date:[NSDate date]
                                                     text:@"Now with media messages!"],
                     nil];
    
    [self addPhotoMediaMessage];
    
    /**
     *  Setting to load extra messages for testing/demo
     */
    if ([NSUserDefaults extraMessagesSetting]) {
        NSArray *copyOfMessages = [self.messages copy];
        for (NSUInteger i = 0; i < 4; i++) {
            [self.messages addObjectsFromArray:copyOfMessages];
        }
    }
    
    
    /**
     *  Setting to load REALLY long message for testing/demo
     *  You should see "END" twice
     */
    if ([NSUserDefaults longMessageSetting]) {
        JSQMessage *reallyLongMessage = [JSQMessage messageWithSenderId:kJSQDemoAvatarIdSquires
                                                            displayName:kJSQDemoAvatarDisplayNameSquires
                                                                   text:@"Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? END Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur? END"];
        
        [self.messages addObject:reallyLongMessage];
    }
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
