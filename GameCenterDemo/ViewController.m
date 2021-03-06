//
//  ViewController.m
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import "ViewController.h"
#import "GCStatusViewController.h"
#import "AppDelegate.h"
#import <GameKit/GameKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <GKMatchmakerViewControllerDelegate>

@end

@implementation ViewController

-(void)viewDidAppear:(BOOL)animated {

    [super viewDidAppear:animated];
    
    //Set our audio category to ambient - this switches when voice chat starts
    NSError *myErr;
    AVAudioSession *sharedInstance = [AVAudioSession sharedInstance];
    [sharedInstance setActive:YES error:&myErr];
    [sharedInstance setCategory: AVAudioSessionCategoryAmbient error: &myErr];
    
    self.gcStatusCtrlr = [[GCStatusViewController alloc] initWithStyle:UITableViewStyleGrouped];
    _gcStatusCtrlr.mainController = self;
    _gcStatusCtrlr.title = @"Game Center Demo App";
    
    UINavigationController *navCtlr = [[UINavigationController alloc] initWithRootViewController:_gcStatusCtrlr];
    
    [self presentViewController:navCtlr animated:YES completion:nil];
    
    [self authenticateLocalPlayer];
    
    //Initialize the set holding nearby players
    self.nearbyPlayers = [NSMutableSet setWithCapacity:3];
    
    //Initialize mute state for players
    self.muteStates = [NSMutableDictionary dictionaryWithCapacity:3];
}

#pragma mark Game Center Authentication and Invitation Registration
- (void) authenticateLocalPlayer
{

    static BOOL gcAuthenticationCalled = NO;
    if (!gcAuthenticationCalled) {
        GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
        
        void (^authenticationHandler)(UIViewController*, NSError*) = ^(UIViewController *viewController, NSError *error) {
            NSLog(@"Authenticating with Game Center.");
            GKLocalPlayer *myLocalPlayer = [GKLocalPlayer localPlayer];
            if (viewController != nil)
            {
                NSLog(@"Not authenticated - storing view controller.");
                self.authenticationController = viewController;
                _gcStatusCtrlr.loginStatus.text = @"Not Logged In - Touch to Connect.";
            }
            else if ([myLocalPlayer isAuthenticated])
            {
                NSLog(@"Player is authenticated!");
                
                [localPlayer unregisterAllListeners];
                [localPlayer registerListener:self];
                
                _gcStatusCtrlr.loginStatus.text = @"Connected.  Touch here to search for players.";
                
                //Download friend information
                [[GKLocalPlayer localPlayer] loadFriendPlayersWithCompletionHandler:^(NSArray *friendPlayers, NSError *error) {
                    
                    if (error) {
                        NSLog(@"There was an error loading friends: %@", [error description]);
                    }
                    
                    self.friends = nil;
                    
                    if (friendPlayers && [friendPlayers count] > 0) {
                        
                        self.friends = [NSMutableArray arrayWithCapacity:[friendPlayers count]];
                        
                        NSLog(@"%d friends found.", (u_int32_t)[friendPlayers count]);
                        NSLog(@"Friends: %@", [friendPlayers description]);
                        for (GKPlayer *p in friendPlayers) {
                            [_friends addObject:p];
                        }
                    }
                    else {
                        
                        //This person has no friends.
                        NSLog(@"GAMECENTER: This person has no friends.");
                        self.friends = [NSMutableArray arrayWithCapacity:1];
                        //Post a notification that friends were updated
                        
                    }
                    
                    //Signal reload of table view
                    [_gcStatusCtrlr.tableView reloadData];
                }];
            }
            else
            {
                //Authentication failed.
                self.authenticationController = nil;
                if (error) {
                    NSLog([error description], nil);
                }
                _gcStatusCtrlr.loginStatus.text = @"Login Failed - cancelled by user.";
            }
            
            
        };
        
        localPlayer.authenticateHandler = authenticationHandler;
        gcAuthenticationCalled = YES;
    }
}

- (void)launchMatchMaker {
    
    GKMatchRequest *request = [[GKMatchRequest alloc] init];
    request.minPlayers = 2;
    request.maxPlayers = 2;
    _matchCtrlr = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
    _matchCtrlr.matchmakerDelegate = self;

    [_gcStatusCtrlr presentViewController:_matchCtrlr animated:YES completion:nil];

}

#pragma mark GKInviteEventListenerProtocol methods
- (void)player:(GKPlayer *)player didRequestMatchWithRecipients:(NSArray *)recipientPlayers {
    
}

- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite {
    
    [[GKMatchmaker sharedMatchmaker] matchForInvite:invite completionHandler:^(GKMatch *match, NSError *error) {
        
        if (error) {
            NSLog(@"Error creating match from invitation: %@", [error description]);
            //Tell ViewController that match connect failed.

        }
        else {
        
            [self updateWithMatch:match];
            
        }
    }];
    
}

#pragma mark GKMatchDelegate methods
- (void)match:(GKMatch *)match didFailWithError:(NSError *)error {
    
    NSLog(@"MATCH FAILED: %@", [error description]);
    
}

- (void)match:(GKMatch *)match
       player:(GKPlayer *)player
didChangeConnectionState:(GKPlayerConnectionState)state {
    
    NSLog(@"PLAYER CHANGED STATE: %@", [self nameForPlayerState:state]);
    
    if (match.players.count == 0)
        [self endMatch];
    else {
        [[GKMatchmaker sharedMatchmaker] finishMatchmakingForMatch:match];
    }
    
    [_gcStatusCtrlr updateStatus];
    
}

#pragma mark Nearby Player searching
-(void)toggleSearchingForPlayers {
    
    if (!_browsingForPlayers) {
        //Start searching for players

        NSLog(@"Browsing for nearby players...");
        [[GKMatchmaker sharedMatchmaker] startBrowsingForNearbyPlayersWithHandler:^(GKPlayer *player, BOOL reachable) {
            
            NSLog(@"Player Nearby: %@", player.playerID);
            if (reachable) {
                [_nearbyPlayers addObject:player];
            }
            else {
                [_nearbyPlayers removeObject:player];
            }
            
            [_gcStatusCtrlr updateStatus];
            
        }];
    }
    else {
        NSLog(@"No longer browsing for nearby players.");
        [[GKMatchmaker sharedMatchmaker] stopBrowsingForNearbyPlayers];
        [_nearbyPlayers removeAllObjects];
    }
    
    self.browsingForPlayers = !_browsingForPlayers;
    
    [_gcStatusCtrlr updateStatus];
}

-(void)updateWithMatch:(GKMatch*)match {
    self.match = match;
    _match.delegate = self;
}

-(void)endMatch {
    [self updateConnectedChatPlayers:FALSE];
    [_match disconnect];
    self.match = nil;
    [_gcStatusCtrlr updateStatus];
    [_muteStates removeAllObjects];
}

#pragma mark Player invitataion handling
-(void)invitePlayerToMatch:(GKPlayer*)player {

    [self invitePlayerToMatch:player randomStatus:0];
    
}

-(void)invitePlayerToMatch:(GKPlayer*)player randomStatus:(BOOL)status {
    
    void (^recipientResponseHandler)(GKPlayer*, GKInviteeResponse) =  ^( GKPlayer *player, GKInviteRecipientResponse response) {
        
        if (response == GKInviteeResponseAccepted) {
            NSLog(@"Player %@: Responded: Connecting (%d)", player.playerID, (int)response);
        }
        else if (response == GKInviteeResponseDeclined) {
            NSLog(@"Player %@: Responded: Declined (%d)", player.playerID, (int)response);
        }
        else if (response == GKInviteeResponseFailed || response == GKInviteeResponseUnableToConnect) {
            NSLog(@"Player %@: Responded: Unable to Connect (%d)", player.playerID, (int)response);
        }
        else if (response == GKInviteeResponseIncompatible) {
            NSLog(@"Player %@: Responded: Incompatible Device (%d)", player.playerID, (int)response);
        }
        else if (response == GKInviteeResponseNoAnswer) {
            NSLog(@"Player %@: Responded: Bi Answer (%d)", player.playerID, (int)response);
        }
    };
    
    //Build match request object
    GKMatchRequest *mRequest = [[GKMatchRequest alloc] init];
    mRequest.minPlayers = 2;
    mRequest.maxPlayers = 4;
    mRequest.defaultNumberOfPlayers = 4;
    mRequest.recipientResponseHandler = recipientResponseHandler;
    if (player) {
        mRequest.recipients = @[player];
    }
    else {
        //Random match
        if (status == 0) {
            //Inviter.
            mRequest.playerAttributes = 0xFFFF0000;
        }
        else {
            //Accepter.
            mRequest.playerAttributes = 0x0000FFFF;
        }
    }
    
    void (^matchCreateCompletionHandler)(GKMatch*, NSError*) = ^(GKMatch *match, NSError *error) {
        
        if (error) {
            NSLog(@"Error creating match: %@", [error description]);
            
            //This may be due to reachability - toggle it.
            if (_browsingForPlayers) {
                [self toggleSearchingForPlayers];
            }
            //Call again to turn on
            [self toggleSearchingForPlayers];
            
            [[GKMatchmaker sharedMatchmaker] cancelPendingInviteToPlayer:player];
            
        }
        else {
            
            NSLog(@"Match successfully created!");
            
            //We have a new match object.
            [self updateWithMatch:match];
            
        }
    };
    
    void (^matchAddCompletionHandler)(NSError*) = ^(NSError *error) {
        matchCreateCompletionHandler(_match, error);
    };
    
    
    //If there is no match, create one.
    if (!_match) {
//        [[GKMatchmaker sharedMatchmaker] cancel];
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[GKMatchmaker sharedMatchmaker] findMatchForRequest:mRequest withCompletionHandler:matchCreateCompletionHandler];
//        });
    }
    else {
        
        //Add the player programmatically to the existing match.
        [[GKMatchmaker sharedMatchmaker] addPlayersToMatch:_match matchRequest:mRequest completionHandler:matchAddCompletionHandler];
        
    }
    

}

//Voice Chat handling
-(void)updateConnectedChatPlayers:(BOOL)on {
    
    if ([GKVoiceChat isVoIPAllowed]) {

        if (on && !_chat) {
            
            //Switch our audio session to one supporting chat.
            NSError *err;
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayAndRecord error:&err];
            
            self.chat = [_match voiceChatWithName:@"myChat"];
            
            //Not using this callback - for some reason it is showing people talking that aren't talking.  It's too sensitive.
            //Initialize the audio channel and set the update handler.
            _chat.playerVoiceChatStateDidChangeHandler = ^( GKPlayer *player, GKVoiceChatPlayerState state) {
                
                NSLog(@"CHAT: Player %@ --- %@", player.displayName, [ViewController chatStatus:state]);
                
            };
            
            NSLog(@"CHAT: ****  STARTING  ****");
            
            [_chat start];
            _chat.active = YES;
            _chat.volume = 1.0;
            
        }
        
        else if (!on) {
            //Chat is inactive - kill the chat instance.
            NSLog(@"CHAT: ****  STOPPED  ****");
            _chat.active = NO;
            [_chat stop];
            self.chat = nil;
            
            //Switch back to standard audio session.
            [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryAmbient error:nil];
            
        }
    }
    
    [_gcStatusCtrlr updateStatus];
}

//Helper function to determine chat status for a player.
+(NSString*)chatStatus:(GKVoiceChatPlayerState)status {
    switch (status) {
        case GKVoiceChatPlayerConnected:                return @"GKVoiceChatPlayerConnected";                           break;
        case GKVoiceChatPlayerConnecting:               return @"GKVoiceChatPlayerConnecting";                          break;
        case GKVoiceChatPlayerDisconnected:             return @"GKVoiceChatPlayerDisconnected";                        break;
        case GKVoiceChatPlayerSilent:                   return @"GKVoiceChatPlayerSilent";                              break;
        case GKVoiceChatPlayerSpeaking:                 return @"GKVoiceChatPlayerSpeaking";                            break;
        default:                                        return nil;                                                     break;
    }
}
-(void)setPlayer:(GKPlayer*)player muted:(BOOL)muted {
    
    if (_chat && _chat.active) {
    
        //Update our model, then GameKit
        _muteStates[player.playerID] = @(YES);
        
        [_chat setPlayer:player muted:YES];

    }
    
    [_gcStatusCtrlr updateStatus];
    
}

-(BOOL)isPlayerMuted:(GKPlayer*)player {

    NSNumber *muteState = _muteStates[player.playerID];
    if (!muteState || [muteState boolValue] == 0) {
        return NO;
    }
    return YES;
    
}

#pragma mark Utility
-(NSString*)nameForPlayerState:(GKPlayerConnectionState)state {
    
    switch (state) {
        case GKPlayerStateConnected:
            return @"GKPlayerStateConnected";
            break;
            
        case GKPlayerStateDisconnected:
            return @"GKPlayerStateDisconnected";
            break;
            
        case GKPlayerStateUnknown:
            return @"GKPlayerStateUnknown";
            break;
            
        default:
            break;
    }
}



- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)viewController {

    NSLog(@"Cancelled.");
    [_matchCtrlr dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController
                didFailWithError:(NSError *)error
{
    NSLog(@"Failed.");
    [_matchCtrlr dismissViewControllerAnimated:YES completion:nil];
}

- (void)matchmakerViewController:(GKMatchmakerViewController *)viewController
                    didFindMatch:(GKMatch *)match

{
    NSLog(@"Match Found!");
    [_matchCtrlr dismissViewControllerAnimated:YES completion:nil];

    [self updateWithMatch:match];
    
    for (GKPlayer *player in match.players) {
        [_nearbyPlayers addObject:player];
    }

    [_gcStatusCtrlr updateStatus];

}


@end

