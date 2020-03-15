//
//  MomentSettingsTableViewController.m
//  WFMomentUIKit
//
//  Created by heavyrain lee on 2019/7/16.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import "MomentSettingsTableViewController.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import <WFMomentClient/WFMomentClient.h>
#import "MomentBlockListViewController.h"


@interface MomentSettingsTableViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)WFMomentProfiles *profile;
@end


@implementation MomentSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"朋友圈设置";
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    __weak typeof(self)ws = self;
    [[WFMomentService sharedService] getUserProfile:[WFCCNetworkService sharedInstance].userId success:^(WFMomentProfiles * _Nonnull profile) {
        ws.profile = profile;
    } error:^(int error_code) {
        [ws.view makeToast:@"网络错误"];
    }];
}
- (void)setProfile:(WFMomentProfiles *)profile {
    _profile = profile;
    [self.tableView reloadData];
}
- (void)selectVisiableScope {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"朋友圈展示范围" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Create cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *noLimitAction = [UIAlertAction actionWithTitle:@"不限制" style:self.profile.visiableScope == WFMVisiableScope_NoLimit ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self updateVisiableScope:WFMVisiableScope_NoLimit];
    }];
    [alertController addAction:noLimitAction];
    
    UIAlertAction *limit3DayAction = [UIAlertAction actionWithTitle:@"三天之内" style:self.profile.visiableScope == WFMVisiableScope_3Days ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self updateVisiableScope:WFMVisiableScope_3Days];
    }];
    [alertController addAction:limit3DayAction];
    
    UIAlertAction *limit1MonthAction = [UIAlertAction actionWithTitle:@"一个月" style:self.profile.visiableScope == WFMVisiableScope_1Month ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self updateVisiableScope:WFMVisiableScope_1Month];
    }];
    [alertController addAction:limit1MonthAction];
    
    UIAlertAction *limit6MonthAction = [UIAlertAction actionWithTitle:@"六个月" style:self.profile.visiableScope == WFMVisiableScope_6Months ? UIAlertActionStyleDestructive : UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self updateVisiableScope:WFMVisiableScope_6Months];
    }];
    [alertController addAction:limit6MonthAction];
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)updateVisiableScope:(WFMVisiableScope)scope {
    if (self.profile.visiableScope != scope) {
        [[WFMomentService sharedService] updateUserProfile:WFMUpdateUserProfileType_VisiableScope strValue:nil intValue:scope success:^{
            self.profile.visiableScope = scope;
            [self.tableView reloadData];
        } error:^(int error_code) {
            [self.view makeToast:@"网络错误"];
        }];
    }
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (indexPath.row == 2 || indexPath.row == 4) {
        WFCUGeneralSwitchTableViewCell *switchCell = [[WFCUGeneralSwitchTableViewCell alloc] init];
        if (indexPath.row == 2) {
            switchCell.textLabel.text = @"允许陌生人查看10条朋友圈";
            if (self.profile.strangerVisiableCount) {
                switchCell.on = YES;
            } else {
                switchCell.on = NO;
            }
            __weak typeof(self)ws = self;
            [switchCell setOnSwitch:^(BOOL value, void (^result)(BOOL success)) {
                [[WFMomentService sharedService] updateUserProfile:WFMUpdateUserProfileType_StrangerVisiableCount strValue:nil intValue:value ? 10 : 0 success:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        result(YES);
                    });
                } error:^(int error_code) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [ws.view makeToast:@"网络错误"];
                        result(NO);
                    });
                }];
            }];
        } else {
            switchCell.textLabel.text = @"朋友圈更新提醒";
        }
        return switchCell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.detailTextLabel.text = nil;
            if (indexPath.row == 0) {
                cell.textLabel.text = @"不让他（她）看";
            } else if(indexPath.row == 1) {
                cell.textLabel.text = @"不看他（她）";
            } else if(indexPath.row == 3) {
                cell.textLabel.text = @"允许朋友查看朋友圈的范围";
                cell.detailTextLabel.text = @"最近三天";
                switch (self.profile.visiableScope) {
                    case WFMVisiableScope_NoLimit:
                        cell.detailTextLabel.text = @"不限制";
                        break;
                    case WFMVisiableScope_3Days:
                        cell.detailTextLabel.text = @"最近三天";
                        break;
                    case WFMVisiableScope_1Month:
                        cell.detailTextLabel.text = @"最近一个月";
                        break;
                    case WFMVisiableScope_6Months:
                        cell.detailTextLabel.text = @"最近六个月";
                        break;
                    default:
                        break;
                }
            }
        return cell;
    }
    
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
        case 1:
        {
            MomentBlockListViewController *blockVC = [[MomentBlockListViewController alloc] init];
            blockVC.block = indexPath.row == 1;
            blockVC.profile = self.profile;
            [self.navigationController pushViewController:blockVC animated:YES];
            break;
        }
        case 3:
        {
            [self selectVisiableScope];
            break;
        }
        default:
            break;
    }
}

@end
