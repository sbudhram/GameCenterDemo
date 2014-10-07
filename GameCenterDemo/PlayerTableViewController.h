//
//  PlayerTableViewController.h
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@class ViewController;

typedef enum {
    PLAYERROW_STATUS,
    PLAYERROW_MUTE,
    PLAYERROW_COUNT,
} PlayerTableRow;

@interface PlayerTableViewController : UITableViewController  <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) ViewController *mainViewController;
@property (nonatomic) GKPlayer *player;
@property (nonatomic) UILabel *statusLabel;
@property (nonatomic) UILabel *muteLabel;

-(void)updatePlayerLabels;

@end
