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
            
            self.connectedPlayers = [[UILabel alloc] initWithFrame:CGRectMake(MARGIN,
                                                                              _loginStatus.frame.origin.y + _loginStatus.frame.size.height,
                                                                              cell.contentView.bounds.size.width - MARGIN*2,
                                                                              60)];
            _connectedPlayers.numberOfLines = 2;
            _connectedPlayers.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            [cell.contentView addSubview:_connectedPlayers];
        }
        _loginStatus.text = @"Checking Connection Status...";
        _connectedPlayers.text = @"Connected Players: None";
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
    else if (indexPath.section == SECTION_GCPLAYERS) {
        
        if (_mainController.nearbyPlayers.count > indexPath.row) {

            //Create a table view controller for this player with options
            self.pViewCtrlr = [[PlayerTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            _pViewCtrlr.player = _mainController.nearbyPlayers.allObjects[indexPath.row];
            _pViewCtrlr.mainViewController = _mainController;
            
            //Push onto the current navigation controller.
            [self.navigationController pushViewController:_pViewCtrlr animated:YES];

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
    
    //Reload nearby players/disconnect
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(SECTION_GCPLAYERS, 2)]
                  withRowAnimation:UITableViewRowAnimationAutomatic];

    if (_mainController.browsingForPlayers) {
        _loginStatus.text = @"Game Center Connected.  Now searching for nearby players...";
    }
    else {
        _loginStatus.text = @"Game Center Connected.  Touch to search for players.";
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
    
}

@end
