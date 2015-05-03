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
#import "Reachability.h"

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
        [self networkReachability];
        [self loginManager];
        
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
    
    return self;
}

- (void) networkReachability
{
    //it seems not totally works in simulator
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.baidu.com"];
    
    //reach.reachableOnWWAN = YES;
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        // keep in mind this is called on a background thread
        // and if you are updating the UI it needs to happen
        // on the main thread, like this:
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"REACHABLE!");
            //TODO: Fire a notification
            self.isNetworkReachable = true;
        });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        NSLog(@"UNREACHABLE!");
        //TODO: fire a nofitcation
        self.isNetworkReachable = false;
        self.isLoginSuccess = false;
    };
    
    // Start the notifier, which will cause the reachability object to retain itself!
    [reach startNotifier];
}

//it should not need this, if Reachabily works
- (void)loginManager
{
    self.conn = NULL;
    self.isLoginSuccess = false;
    self.isNetworkReachable = false;
    
    dispatch_queue_t connRecvQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(connRecvQueue, ^(void){
        while (true) {
            
            int retry_times = 0;
            while( self.isLoginSuccess == false ) {
                retry_times++;
                NSLog(@"try to reconnect to server, retry_times=%d", retry_times);
                //FIXME: should update logging status in main_queue?
                [self reloginRabbitMqServer];
                
                int interval = 3;
                sleep(interval);
            }
            
            //TODO: wait for relogin notification
            sleep(1);
        }
        
    });
    
}

- (void) loginRabbitMqServer
{
    //TODO: use async login
    NSLog(@"loginRabbitMqServer");
    
    char const *hostname = rabbit_hostname;
    char const *username = login_rabbit_username;
    char const *password = login_rabbit_password;
    const int port = rabbit_port;
    
    amqp_connection_state_t conn;
    conn = amqp_new_connection();
    if (conn == NULL) {
        NSLog(@"amqp_new_connection failed");
        return;
    }

    amqp_socket_t *socket = NULL;
    socket = amqp_tcp_socket_new(conn);
    if (!socket) {
        NSLog(@"creating TCP socket failed");
        return;
    }
    
    int status;
    status = amqp_socket_open(socket, hostname, port);
    if (status) {
        NSLog(@"opening TCP socket failed");
        return;
    }
    
    amqp_rpc_reply_t res;
    res = amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, username, password);
    
    if (AMQP_RESPONSE_NORMAL != res.reply_type) {
        NSLog(@"amqp login failed! reply_code=%d", res.reply_type);
        self.isLoginSuccess = false;
        return;
    }
    
    amqp_channel_t const channel = 1;
    amqp_channel_open(conn, channel);
    res = amqp_get_rpc_reply(conn);

    if (AMQP_RESPONSE_NORMAL != res.reply_type) {
        NSLog(@"amqp_channel_open failed! reply_code=%d", res.reply_type);
        self.isLoginSuccess = false;
        return;
    }
    
    self.conn = conn;
    if ([self bindRecvRabbitMq]) {
        NSLog(@"loggin Success");
        
        self.isLoginSuccess = true;
        //TODO: fire a notification to begin consuming msg
    }else{
        NSLog(@"login failed");
    }
}

- (void) reloginRabbitMqServer
{
    NSLog(@"reloginRabbitMqServer");
        
    [self closeConnRabbitMq];
    [self loginRabbitMqServer];
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
        return true;
    }
    
    return false;
}

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
            self.isLoginSuccess = false;
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
        //TODO: fire a notification
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
        //update msg status
        //use KVO to udpate UI?
        if (responseStatus != AMQP_STATUS_OK) {
            NSLog(@"send msg failed %d", responseStatus);
            //TODO: fire a notification
            //self.isLoginSuccess = false;//cause to relogin
        }
    }
}

- (void)closeConnRabbitMq
{
    NSLog(@"closeConnRabbitMq");

    const amqp_connection_state_t conn = self.conn;

    if (conn) {
        //NSLog(@"amqp_channel_close ...");
        //unfortunatly, it will block by amqp_channel_close and amqp_connection_close
        //const amqp_channel_t channel = 1;
        //amqp_channel_close(conn, channel, AMQP_REPLY_SUCCESS);
        //NSLog(@"amqp_connection_close ...");
        //amqp_connection_close(conn, AMQP_REPLY_SUCCESS);
        
        NSLog(@"amqp_destroy_connection ...");
        amqp_destroy_connection(conn);
        NSLog(@"close OK");
    }
    
    self.conn = NULL;
    self.isLoginSuccess = false;
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
