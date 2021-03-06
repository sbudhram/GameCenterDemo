//
//  GCStatusViewController.m
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import "GCStatusViewController.h"
#import "AppDelegate.h"
#import "ViewController.h"
#import "PlayerTableViewController.h"
#import <GameKit/GameKit.h>

#define MARGIN 30

@interface GCStatusViewController ()

@end

@implementation GCStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
}

#pragma mark TableView Datasource methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (section == SECTION_GCSTATUS) {
        return 1;
    }
    else if (section == SECTION_GCPLAYERS) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated] && _mainController.browsingForPlayers)
            return MAX(1, [self playerCount]);
    }
    else if (section == SECTION_RANDOM) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated])
            return 2;
    }
    else if (section == SECTION_FRIENDS) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated] && _mainController.friends != nil)
            return MAX(1, _mainController.friends.count);
    }
    else if (section == SECTION_DISCONNECT) {
        return (_mainController.match.players.count > 0 ? OPTIONROW_COUNT : 0);
    }
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {

    return SECTION_COUNT;

}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (indexPath.section == SECTION_GCSTATUS) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"StatusCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StatusCell"];
            
            self.loginStatus = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN,
                                                                         MARGIN,
                                                                         cell.contentView.bounds.size.width - MARGIN*2,
                                                                         60)];
            _loginStatus.numberOfLines = 2;
            _loginStatus.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:_loginStatus];
            
            UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
            [btn setTitle:@"Use GKMatchMakerViewController" forState:UIControlStateNormal];
            [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            btn.frame = CGRectMake(MARGIN,
                                   _loginStatus.frame.origin.y + _loginStatus.frame.size.height + MARGIN,
                                   cell.contentView.bounds.size.width - MARGIN*2,
                                   _loginStatus.bounds.size.height);
            btn.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            btn.layer.borderWidth=1.0f;
            btn.layer.borderColor=[[UIColor blackColor] CGColor];
            [btn addTarget:_mainController action:@selector(launchMatchMaker) forControlEvents:UIControlEventTouchUpInside];
            [cell.contentView addSubview:btn];
            
            self.connectedPlayers = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN,
                                                                              btn.frame.origin.y + btn.frame.size.height,
                                                                              cell.contentView.bounds.size.width - MARGIN*2,
                                                                              60)];
            _connectedPlayers.numberOfLines = 2;
            _connectedPlayers.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:_connectedPlayers];
        
        
        }
        
        
        
        _loginStatus.text = @"Checking Connection Status...";
        _connectedPlayers.text = @"Connected Players: None";
    }
    else if (indexPath.section == SECTION_RANDOM) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Random"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Random"];
        }
        if (indexPath.row == 0)
            cell.textLabel.text = @"Invite Random";
        else
            cell.textLabel.text = @"Accept Random";
    }
    else if (indexPath.section == SECTION_GCPLAYERS) {
        //Player cell
        if ([self playerCount] == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"NoPlayers"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoPlayers"];
            }
            cell.textLabel.text = @"No Players Detected";
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerCell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlayerCell"];
            }
            GKPlayer *player = _mainController.nearbyPlayers.allObjects[indexPath.row];
            cell.textLabel.text = player.displayName;
        }
    }
    else if (indexPath.section == SECTION_FRIENDS) {
        //Player cell
        if (_mainController.friends.count == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"NoFriends"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoFriends"];
            }
            cell.textLabel.text = @"No Friends";
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerCell"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlayerCell"];
            }
            GKPlayer *player = _mainController.friends[indexPath.row];
            cell.textLabel.text = player.displayName;
        }
    }
    else if (indexPath.section == SECTION_DISCONNECT) {
        if (indexPath.row == OPTIONROW_DISCONNECT) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Disconnect"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Disconnect"];
            }
            cell.textLabel.text = @"Disconnect";
        }
        else if (indexPath.row == OPTIONROW_CHAT) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"ChatToggle"];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ChatToggle"];
            }
            self.chatLabel = cell.textLabel;
        }
    }
    return cell;
}

#pragma mark TableView Delegate methods
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == SECTION_GCSTATUS) {
        return @"Game Center Connection Status";
    }
    else if (section == SECTION_GCPLAYERS) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated] && _mainController.browsingForPlayers) {
            return @"Nearby Players";
        }
    }
    else if (section == SECTION_RANDOM) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated]) {
            return @"Random Game";
        }
    }
    else if (section == SECTION_FRIENDS) {
        if ([[GKLocalPlayer localPlayer] isAuthenticated] && _mainController.friends != nil) {
            return @"GameCenter Friends";
        }
    }
    else if (section == SECTION_DISCONNECT) {
        return (_mainController.match.players.count > 0 ? @"Match Options" : nil);
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SECTION_GCSTATUS) {
        return _connectedPlayers.frame.origin.y + _connectedPlayers.frame.size.height + MARGIN;
    }
    else {
        return 70;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == SECTION_GCSTATUS) {
        if (![[GKLocalPlayer localPlayer] isAuthenticated]) {

            if (_mainController.authenticationController) {
                [self presentViewController:_mainController.authenticationController
                                   animated:YES
                                 completion:nil];
            }
            
        }
        else {
            //Toggle searching status
            [_mainController toggleSearchingForPlayers];
        }
    }
    else if (indexPath.section == SECTION_RANDOM) {
        if (indexPath.row == 0) {
            //Invite a random player
            [_mainController invitePlayerToMatch:nil randomStatus:0];
        }
        else {
            //Accept a random invitation
            [_mainController invitePlayerToMatch:nil randomStatus:1];
        }
    }
    else if (indexPath.section == SECTION_GCPLAYERS) {
        
        if (_mainController.nearbyPlayers.count > indexPath.row) {
            
            [_mainController invitePlayerToMatch:_mainController.nearbyPlayers.allObjects[indexPath.row]];
            
        }
    }
    else if (indexPath.section == SECTION_FRIENDS) {
        
        if (_mainController.friends.count > indexPath.row) {
            
            [_mainController invitePlayerToMatch:_mainController.friends[indexPath.row]];
            
        }
    }
    else if (indexPath.section == SECTION_DISCONNECT) {
        
        if (indexPath.row == OPTIONROW_CHAT) {
            //Activate/deactivate chat session
            if (_mainController.chat) {
                [_mainController updateConnectedChatPlayers:FALSE];
            }
            else {
                [_mainController updateConnectedChatPlayers:TRUE];
            }
        }
        else if (indexPath.row == OPTIONROW_DISCONNECT) {
            [_mainController endMatch];
        }
        
    }
}

-(NSInteger)playerCount {
    return _mainController.nearbyPlayers.count;
}

-(void)updateStatus {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        //Reload nearby players/disconnect
        [self.tableView reloadData];
        
        if (_mainController.browsingForPlayers) {
            _loginStatus.text = @"Connected.  Now searching for nearby players...";
        }
        else {
            _loginStatus.text = @"Connected.  Touch here to search for players.";
        }
        
        if (!_mainController.match) {
            _connectedPlayers.text = @"Connected Players: None";
        }
        else {
            NSMutableArray *playerNames = [NSMutableArray arrayWithCapacity:3];
            for (GKPlayer *p in _mainController.match.players) {
                [playerNames addObject:p.displayName];
            }
            _connectedPlayers.text = [NSString stringWithFormat:@"Connected Players: %@", [playerNames componentsJoinedByString:@", "]];
            
            //Update chat label
            if (_mainController.chat) {
                _chatLabel.text = @"Toggle Chat OFF";
            }
            else {
                _chatLabel.text = @"Toggle Chat ON";
            }
        }
        
        //Update player label for active player subview
        if (_pViewCtrlr) {
            [_pViewCtrlr updatePlayerLabels];
        }

    });
    
    
}

@end
