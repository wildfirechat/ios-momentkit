//
//  MomentsMessageViewController.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/23.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "MomentsMessageViewController.h"
#import <WFMomentClient/WFMomentClient.h>
#import "MomentsMessageCell.h"
#import "FeedDetailViewController.h"

@interface MomentsMessageViewController () <UITableViewDataSource, UITableViewDelegate>
@property(nonatomic, strong)UITableView *tableView;
@property(nonatomic, strong)NSArray *dataArr;
@end

@implementation MomentsMessageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dataArr = [[WFMomentService sharedService] getMessages:self.isNew];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
    [self.view addSubview:self.tableView];
    
    [[WFMomentService sharedService] clearUnreadStatus];
}

- (void)setIsNew:(BOOL)isNew {
    _isNew = isNew;
    if (self.tableView) {
        self.dataArr = [[WFMomentService sharedService] getMessages:self.isNew];
        [self.tableView reloadData];
    }
}

#pragma mark - tableView delegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataArr.count) {
        return MomentsMessageCellHeight;
    } else {
        return 40;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.dataArr.count) {
        self.isNew = NO;
    } else {
        WFCCMessage *content = [self.dataArr objectAtIndex:indexPath.row];
        FeedDetailViewController *vc = [[FeedDetailViewController alloc] init];
        vc.message = content;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.isNew) {
        return self.dataArr.count + 1;
    } else {
        return self.dataArr.count;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row < self.dataArr.count) {
        MomentsMessageCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MomentsMessageCell"];
        if (cell == nil) {
            cell = [[MomentsMessageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MomentsMessageCell"];
        }
        
        cell.object = self.dataArr[indexPath.row];
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CellMoreData"];
        if (!cell) {
            cell = [[UITableViewCell alloc] init];
            for (UIView *subView in cell.subviews) {
                [subView removeFromSuperview];
            }
            UILabel *moreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 40)];
            moreLabel.textAlignment = NSTextAlignmentCenter;
            moreLabel.text = @"更多消息";
            [cell addSubview:moreLabel];
        }
        return cell;
    }
    
    return nil;
}

@end
