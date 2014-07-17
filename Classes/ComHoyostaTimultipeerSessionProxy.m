/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2014年 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */

#import "ComHoyostaTimultipeerSessionProxy.h"
#import "TiUtils.h"

@implementation ComHoyostaTimultipeerSessionProxy
@synthesize peerName, serviceType;

#pragma mark Public

-(id)advertize:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary)

    if (!_advertiser) {
        [self initSession:args];
        _advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:_peer
                                                        discoveryInfo:nil
                                                          serviceType:serviceType];
        _advertiser.delegate = self;
    }
    [_advertiser startAdvertisingPeer];

    NSLog(@"Advertiser: start %@ (peerName=%@)", serviceType, peerName);
}

-(id)browse:(id)args
{
    ENSURE_SINGLE_ARG_OR_NIL(args, NSDictionary)
    
    if (!_browser) {
        [self initSession:args];
        _browser = [[MCNearbyServiceBrowser alloc] initWithPeer:_peer
                                                    serviceType:serviceType];
        _browser.delegate = self;
    }
    [_browser startBrowsingForPeers];

    NSLog(@"Browser: start %@ (peerName=%@)", serviceType, peerName);
}

-(id)stop:(id)args
{
    if (_advertiser) {
        [_advertiser stopAdvertisingPeer];
        NSLog(@"Advertiser: stop %@", serviceType);
    }
    if (_browser) {
        [_browser stopBrowsingForPeers];
        NSLog(@"Browser: stop %@", serviceType);
    }
}

-(id)sendData:(id)args
{
    NSString *message, *to;
    NSArray *peers;
    NSError *error;
    
    ENSURE_ARG_OR_NIL_AT_INDEX(message, args, 0, NSString)
    ENSURE_ARG_OR_NIL_AT_INDEX(to, args, 1, NSString)

    if (to) {
        if (!_connectedPeers[to]) {
            NSLog(@"[WARN] invalid peerName");
            return NUMBOOL(NO);
        }
        peers = [NSArray arrayWithObject:_connectedPeers[to]];
    } else {
        peers = _session.connectedPeers;
        to = @"all";
    }

    NSLog(@"SendData: %@ (to %@)", message, to);

    [_session sendData:[message dataUsingEncoding:NSUTF8StringEncoding]
               toPeers:peers
              withMode:MCSessionSendDataReliable
                 error:&error];
    return NUMBOOL(!error);
}

#pragma mark Private

-(void)initSession:(NSDictionary *)args
{
    if (!_session) {
        if (args[@"peerName"]) {
            peerName = args[@"peerName"];
        } else {
            peerName = [UIDevice currentDevice].identifierForVendor.UUIDString;
        }
        _peer = [[MCPeerID alloc] initWithDisplayName:peerName];
        _session = [[MCSession alloc] initWithPeer:_peer];
        _session.delegate = self;
    } else if (args[@"peerName"] && args[@"peerName"] != peerName) {
        NSLog(@"[WARN] peerName should be equals to the one called before");
    }
    
    if (args[@"serviceType"]) {
        serviceType = args[@"serviceType"];
    } else {
        serviceType = @"ti-multipeer";
    }
}

-(NSString *)stringForSessionState:(MCSessionState)state
{
    switch (state) {
        case MCSessionStateConnected:
            return @"Connected";
        case MCSessionStateConnecting:
            return @"Connecting";
        case MCSessionStateNotConnected:
            return @"Not Connected";
    }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error
{
    NSLog(@"AdvertiserAssistant: didNotStartAdvertisingPeer");
}

-(void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    NSLog(@"AdvertiserAssistant: didReceiveInvitationFromPeer");
    invitationHandler(YES, _session);
}

#pragma mark - MCNearbyServiceBrowserDelegate

-(void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error
{
    NSLog(@"Browser: [error] %@", [error localizedDescription]);
    if ([self _hasListeners:@"error"]) {
        NSDictionary *event = [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:@"error"];
        [self fireEvent:@"error" withObject:event];
    }
}

-(void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    NSLog(@"Browser: found %@", peerID.displayName);
    [browser invitePeer:peerID toSession:_session withContext:nil timeout:0];
}

-(void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    NSLog(@"Browser: lost %@", peerID.displayName);
}

#pragma mark - MCSessionDelegate

-(void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error
{
    NSLog(@"Session: didFinishReceivingResourceWithName");
}

-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID
{
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"ReceiveData: %@", message);

    if ([self _hasListeners:@"receive"]) {
        NSDictionary *event = [NSDictionary dictionaryWithObject:message forKey:@"data"];
        [self fireEvent:@"receive" withObject:event];
    }
}

-(void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID
{
    // unsupported yet
    NSLog(@"Session: didReceiveStream");
}

-(void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress
{
    // unsupported yet
    NSLog(@"Session: didStartReceivingResourceWithName");
}

-(void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state
{
    NSLog(@"Session: peer [%@] changed state to %@", peerID.displayName, [self stringForSessionState:state]);
    NSString *targetPeerName = peerID.displayName;
    
    switch (state) {
        case MCSessionStateConnected:
            if (!_connectedPeers[targetPeerName]) {
                [_connectedPeers setObject:peerID forKey:targetPeerName];
                if ([self _hasListeners:@"connect"]) {
                    NSDictionary *event = [NSDictionary dictionaryWithObject:peerName forKey:@"peer"];
                    [self fireEvent:@"connect" withObject:event];
                }
            }
            break;
        case MCSessionStateConnecting:
            NSLog(@"Connecting...");
            break;
        case MCSessionStateNotConnected:
            if (_connectedPeers[targetPeerName]) {
                [_connectedPeers removeObjectForKey:targetPeerName];
                if ([self _hasListeners:@"disconnect"]) {
                    NSDictionary *event = [NSDictionary dictionaryWithObject:targetPeerName forKey:@"peer"];
                    [self fireEvent:@"disconnect" withObject:event];
                }
            }
            break;
    }
}

@end
