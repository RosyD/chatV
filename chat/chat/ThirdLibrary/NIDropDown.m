//
//  NIDropDown.m
//  NIDropDown
//
//  Created by Bijesh N on 12/28/12.
//  Copyright (c) 2012 Nitor Infotech. All rights reserved.
//

#import "NIDropDown.h"
#import "QuartzCore/QuartzCore.h"
#import "ACEntity.h"
#import "UIView+Additions.h"

@interface NIDropDown ()
@property(nonatomic, strong) UITableView *table;
@property(nonatomic, strong) UIButton *btnSender;
@property(nonatomic, retain) NSArray *list;
@end

@implementation NIDropDown
@synthesize table;
@synthesize btnSender;
@synthesize list;
@synthesize delegate;

- (id)showDropDown:(UIButton *)b:(CGFloat *)height:(NSArray *)arr {
    btnSender = b;
    self = [super init];
    if (self) {
        // Initialization code
        CGRect btn = b.frame;
        
        self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
        self.list = [NSArray arrayWithArray:arr];
        self.layer.masksToBounds = NO;
        self.layer.cornerRadius = 8;
        self.layer.shadowOffset = CGSizeMake(-5, 5);
        self.layer.shadowRadius = 5;
        self.layer.shadowOpacity = 0.5;
        
        table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, btn.size.width, 0)];
        table.delegate = self;
        table.dataSource = self;
        table.layer.cornerRadius = 5;
        table.backgroundColor = [UIColor colorWithRed:0.939 green:0.939 blue:0.939 alpha:1];
        table.separatorStyle = UITableViewCellSeparatorStyleNone;
        table.separatorColor = [UIColor grayColor];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5];
        self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, *height);
        table.frame = CGRectMake(0, 0, btn.size.width, *height);
        [UIView commitAnimations];
        
        [b.superview addSubview:self];
        [self addSubview:table];
    }
    return self;
}

-(void)hideDropDown:(UIButton *)b {
    CGRect btn = b.frame;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.5];
    self.frame = CGRectMake(btn.origin.x, btn.origin.y+btn.size.height, btn.size.width, 0);
    table.frame = CGRectMake(0, 0, btn.size.width, 0);
    [UIView commitAnimations];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.list count];
}   


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
        cell.textLabel.font = [UIFont systemFontOfSize:15];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.size.height-1, cell.size.width, 1)];
        [lineView setBackgroundColor:[UIColor colorWithRed:0.739 green:0.739 blue:0.739 alpha:1]];
        [cell addSubview:lineView];
        [lineView release];
        
        UIView * v = [[UIView alloc] init];
        v.backgroundColor = [UIColor colorWithRed:0.739 green:0.739 blue:0.739 alpha:1];
        cell.selectedBackgroundView = v;
        cell.backgroundView = nil;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.textColor = [UIColor blackColor];
        [v release];
    }
    ACCategory *category = [list objectAtIndex:indexPath.row];
    cell.textLabel.text = category.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self hideDropDown:btnSender];
    UITableViewCell *c = [tableView cellForRowAtIndexPath:indexPath];
    [btnSender setTitle:c.textLabel.text forState:UIControlStateNormal];
    [self.delegate niDropDownDelegateMethod:self index:(int)indexPath.row];
}

-(void)dealloc {
    [super dealloc];
    [table release];
    [self release];
}

@end
