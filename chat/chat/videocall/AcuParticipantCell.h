//
//  AcuParticipantCell.h
//  AcuConference
//
//  Created by aculearn on 13-8-5.
//  Copyright (c) 2013年 aculearn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AcuParticipantCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *participantName;

@property (weak, nonatomic) IBOutlet UIImageView *participantIcon1;
@property (weak, nonatomic) IBOutlet UIImageView *participantIcon2;
@property (weak, nonatomic) IBOutlet UIImageView *participantIcon3;
@property (weak, nonatomic) IBOutlet UIImageView *participantIcon4;
@property (weak, nonatomic) IBOutlet UIImageView *participantIcon5;

@end
