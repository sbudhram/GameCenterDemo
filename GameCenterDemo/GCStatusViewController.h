//
//  GCStatusViewController.h
//  GameCenterDemo
//
//  Created by Shaun Budhram on 10/6/14.
//  Copyright (c) 2014 Shaun Budhram. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlayerTableViewController;

typedef enum {
    SECTION_GCSTATUS,
    SECTION_GCPLAYERS,
    SECTION_RANDOM,
    SECTION_FRIENDS,
    SECTION_DISCONNECT,
    SECTION_COUNT,
} TableSection;

typedef enum {
    OPTIONROW_CHAT,
    OPTIONROW_DISCONNECT,
    OPTIONROW_COUNT,
} OptionRow;

@class ViewController;

@interface GCStatusViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) ViewController *mainController;
@property (nonatomic) PlayerTableViewController *pViewCtrlr;

@property (nonatomic) UILabel *loginStatus;
@property (nonatomic) UILabel *connectedPlayers;
@property (nonatomic) UILabel *chatLabel;

-(void)updateStatus;

@end
