//
//  ACRepeatDayController.m
//  chat
//
//  Created by 王方帅 on 14-8-5.
//  Copyright (c) 2014年 王方帅. All rights reserved.
//

#import "ACRepeatDayController.h"
#import "ACRepeatDayCell.h"
#import "UINavigationController+Additions.h"
#import "ACLocationSettingViewController.h"

@interface ACRepeatDayController ()

@end

@implementation ACRepeatDayController

AC_MEM_Dealloc_implementation


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.dataSourceArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:kRepeatDayList]];
    if ([_dataSourceArray count] == 0)
    {
        _dataSourceArray = [[NSMutableArray alloc] init];
        for (int i = 0; i < 7; i++)
        {
            [_dataSourceArray addObject:[NSNumber numberWithBool:YES]];
        }
        [[NSUserDefaults standardUserDefaults] setObject:_dataSourceArray forKey:kRepeatDayList];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

#pragma mark -tableViewDelegate
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_dataSourceArray count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ACRepeatDayCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ACRepeatDayCell"];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"ACRepeatDayCell" owner:nil options:nil];
        cell = [nib objectAtIndex:0];
    }
    [cell setIndex:(int)indexPath.row];
    [cell setSelect:[[_dataSourceArray objectAtIndex:indexPath.row] boolValue]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    ／return 44;
    return 70;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    BOOL selected = [[_dataSourceArray objectAtIndex:indexPath.row] boolValue];
    selected = !selected;
    [_dataSourceArray replaceObjectAtIndex:indexPath.row withObject:[NSNumber numberWithBool:selected]];
    [[NSUserDefaults standardUserDefaults] setObject:_dataSourceArray forKey:kRepeatDayList];
    [[NSUserDefaults standardUserDefaults] synchronize];
    ACRepeatDayCell *cell = (ACRepeatDayCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell setSelect:selected];
}

#pragma mark -IBAction
-(IBAction)goback:(id)sender
{
    [self.navigationController ACpopViewControllerAnimated:YES];
    [_superVC setWeekTitle:[[ACConfigs shareConfigs] getWeekTitle]];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
