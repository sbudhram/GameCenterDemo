//
//  ViewController.h
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@class GCStatusViewController;

@interface ViewController : UIViewController <GKMatchDelegate, GKLocalPlayerListener>

@property (nonatomic) GCStatusViewController *gcStatusCtrlr;
@property (nonatomic) UIViewController *authenticationController;
@property (nonatomic) GKMatch *match;
@property (nonatomic) GKVoiceChat *chat;
@property (nonatomic) BOOL browsingForPlayers;
@property (nonatomic) NSMutableSet *nearbyPlayers;
@property (nonatomic) NSMutableDictionary *muteStates;      //Dictionary to hold the muted state of a player, since there is apparently no way to get this from the API
@property (nonatomic) GKMatchmakerViewController *matchCtrlr;

-(void)toggleSearchingForPlayers;
-(void)invitePlayerToMatch:(GKPlayer*)player;
-(void)endMatch;
-(void)updateConnectedChatPlayers:(BOOL)on;
-(void)setPlayer:(GKPlayer*)player muted:(BOOL)muted;
-(BOOL)isPlayerMuted:(GKPlayer*)player;
-(NSString*)nameForPlayerState:(GKPlayerConnectionState)state;
-(void)launchMatchMaker;
@end

