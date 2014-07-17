/**
 * Appcelerator Titanium Mobile
 * Copyright (c) 2009-2014年 by Appcelerator, Inc. All Rights Reserved.
 * Licensed under the terms of the Apache Public License
 * Please see the LICENSE included with this distribution for details.
 */
#import "TiProxy.h"
#import <MultipeerConnectivity/MCNearbyServiceAdvertiser.h>
#import <MultipeerConnectivity/MCNearbyServiceBrowser.h>
#import <MultipeerConnectivity/MCPeerID.h>
#import <MultipeerConnectivity/MCSession.h>

@interface ComHoyostaTimultipeerSessionProxy : TiProxy
    <MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate, MCSessionDelegate> {
@private
    MCNearbyServiceAdvertiser *_advertiser;
    MCNearbyServiceBrowser *_browser;
    MCPeerID *_peer;
    MCSession *_session;
    NSMutableDictionary *_connectedPeers;
}

-(id)advertize:(id)args;
-(id)browse:(id)args;
-(id)stop:(id)args;
-(id)sendData:(id)args;

@property (nonatomic, readwrite, assign) NSString *peerName;
@property (nonatomic, readwrite, assign) NSString *serviceType;

@end