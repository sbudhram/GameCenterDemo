//
//  PlayerTableViewController.m
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import "PlayerTableViewController.h"
#import "ViewController.h"

@interface PlayerTableViewController ()

@end

@implementation PlayerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Player Status";
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return PLAYERROW_COUNT;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    if (indexPath.row == PLAYERROW_STATUS) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerStatus"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlayerStatus"];
        }
        self.statusLabel = cell.textLabel;
    }
    else if (indexPath.row == PLAYERROW_MUTE) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"PlayerMute"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PlayerMute"];
        }
        self.muteLabel = cell.textLabel;
    }
    
    [self updatePlayerLabels];
    
    return cell;
}

#pragma mark TableView Delegate methods
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    
    return _player.displayName;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    return 70;

}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == PLAYERROW_STATUS) {
        
        if (![_mainViewController.match.players containsObject:_player]) {
            //Send an invitation.
            _statusLabel.text = @"Inviting...";
            [_mainViewController invitePlayerToMatch:_player];
        }
    }
    else if (indexPath.row == PLAYERROW_MUTE) {

        BOOL muted = [_mainViewController isPlayerMuted:_player];
        [_mainViewController setPlayer:_player muted:!muted];
    
    }
}


-(void)updatePlayerLabels {
    
    if ([_mainViewController.match.players containsObject:_player]) {
        //Connected.  Touch will disconnect.
        _statusLabel.text = @"Connected.";
    }
    else {
        //We're inviting
        _statusLabel.text = @"Not connected.  Touch to invite.";
    }
    
    BOOL muted = [_mainViewController isPlayerMuted:_player];
    _muteLabel.text = [NSString stringWithFormat:@"Muted: %@", (muted ? @"Yes" : @"No")];
    
}


@end
