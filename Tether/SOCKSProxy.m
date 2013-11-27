//
//  SOCKSProxy.m
//  Tether
//
//  Created by Christopher Ballinger on 11/26/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "SOCKSProxy.h"
#import "SOCKSProxySocket.h"

@interface SOCKSProxy()
@property (nonatomic, strong) GCDAsyncSocket *listeningSocket;
@property (nonatomic) dispatch_queue_t listeningQueue;
@property (nonatomic, strong) NSMutableSet *activeSockets;
@end

@implementation SOCKSProxy

- (id) init {
    if (self = [super init]) {
        self.listeningQueue = dispatch_queue_create("SOCKS delegate queue", 0);
        self.listeningSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.listeningQueue];
        self.activeSockets = [NSMutableSet set];
    }
    return self;
}

- (void) startProxy {
    [self startProxyOnPort:9050];
}

- (void) startProxyOnPort:(uint16_t)port {
    _listeningPort = port;
    NSError *error = nil;
    [self.listeningSocket acceptOnPort:port error:&error];
    if (error) {
        NSLog(@"Error listening on port %d: %@", port, error.userInfo);
    }
    NSLog(@"Listening on port %d", port);
}

- (void) socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"Accepted new socket: %@", newSocket);
    SOCKSProxySocket *proxySocket = [[SOCKSProxySocket alloc] initWithSocket:newSocket delegate:self];
    [self.activeSockets addObject:proxySocket];
}

- (void) proxySocketDidDisconnect:(SOCKSProxySocket *)proxySocket withError:(NSError *)error {
    dispatch_async(self.listeningQueue, ^{
        [self.activeSockets removeObject:proxySocket];
    });
}

@end
