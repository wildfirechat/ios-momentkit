//
//  MomentBlockListViewController.m
//  WFMomentUIKit
//
//  Created by heavyrain lee on 2019/7/16.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import "MomentBlockListViewController.h"
#import "MementBlockListCollectionViewLayout.h"
#import "MemberCell.h"
#import <WFMomentClient/WFMomentClient.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import <SDWebImage/SDWebImage.h>
#import "Predefine.h"
#import "MBProgressHUD.h"

@interface MomentBlockListViewController ()<UICollectionViewDelegate, UICollectionViewDataSource>
@property(nonatomic, strong)UILabel *tipLabel;
@property(nonatomic, strong)UICollectionView *collectionView;
@property (nonatomic, strong)MementBlockListCollectionViewLayout *memberCollectionViewLayout;
@property(nonatomic, strong)NSMutableArray<NSString *> *userIds;
@property(nonatomic, strong)NSMutableArray<NSString *> *userIdsToAdd;
@property(nonatomic, strong)NSMutableArray<NSString *> *userIdsToRemove;

@property(nonatomic, assign)BOOL deleteMode;
@end

#define Group_Member_Cell_Reuese_ID @"Group_Member_Cell_Reuese_ID"
@implementation MomentBlockListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"确定" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
    
    self.tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, [WFCUUtilities wf_navigationFullHeight], self.view.bounds.size.width-16, 40)];
    if (self.block) {
        self.tipLabel.text = @"不看他（她）的朋友圈";
    } else {
        self.tipLabel.text = @"不让他（她）看我的朋友圈";
    }
    
    self.tipLabel.textAlignment = NSTextAlignmentLeft;
    self.tipLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    self.tipLabel.textColor = [UIColor grayColor];
    [self.view addSubview:self.tipLabel];
    
    
    self.userIds = [[NSMutableArray alloc] init];
    if (self.block) {
        [self.userIds addObjectsFromArray:self.profile.blockList];
    } else {
        [self.userIds addObjectsFromArray:self.profile.blackList];
    }
    self.userIdsToAdd = [[NSMutableArray alloc] init];
    self.userIdsToRemove = [[NSMutableArray alloc] init];
    
    self.memberCollectionViewLayout = [[MementBlockListCollectionViewLayout alloc] initWithItemMargin:3];
    int memberCollectionCount = (int)self.userIds.count + 2;
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, [WFCUUtilities wf_navigationFullHeight] + 40 + 8, self.view.frame.size.width, [self.memberCollectionViewLayout getHeigthOfItemCount:memberCollectionCount]) collectionViewLayout:self.memberCollectionViewLayout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    
    self.collectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    [self.collectionView registerClass:[MemberCell class] forCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID];
    [self.view addSubview:self.collectionView];
    
    [self.view setBackgroundColor:[WFCUConfigManager globalManager].backgroudColor];
}

- (void)onRightBtn:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"添加中...";
    [hud showAnimated:YES];
    
    __weak typeof(self)ws = self;
    [[WFMomentService sharedService] updateBlackOrBlockList:self.block addList:self.userIdsToAdd removeList:self.userIdsToRemove success:^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [ws.view makeToast:@"添加成功"
                      duration:2
                      position:CSToastPositionCenter];
            [ws.navigationController popViewControllerAnimated:YES];
        });
    } error:^(int error_code) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hideAnimated:YES];
            [ws.view makeToast:@"网络出错"
                      duration:2
                      position:CSToastPositionCenter];
        });
    }];
}

- (void)addMoreUser {
    WFCUContactListViewController *pvc = [[WFCUContactListViewController alloc] init];
    pvc.selectContact = YES;
    pvc.multiSelect = YES;
    
    __weak typeof(self)ws = self;
    pvc.selectResult = ^(NSArray<NSString *> *contacts) {
        [ws.userIds addObjectsFromArray:contacts];
        ws.collectionView.frame = CGRectMake(0, 126, ws.view.frame.size.width, [ws.memberCollectionViewLayout getHeigthOfItemCount:(int)ws.userIds.count+2]);
        [ws.collectionView reloadData];
        [self.userIdsToAdd addObjectsFromArray:contacts];
    };
    pvc.disableUsersSelected = YES;
    pvc.disableUsers = self.userIds;
    
    UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
    [self.navigationController presentViewController:navi animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.deleteMode) {
        return self.userIds.count;
    }
    
    int memberCollectionCount = (int)self.userIds.count + 2;
    if (self.userIds.count == 0) {
        memberCollectionCount = 1;
    }
    return memberCollectionCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MemberCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID forIndexPath:indexPath];
    if (indexPath.row < self.userIds.count) {
        NSString *userId = self.userIds[indexPath.row];
        cell.userId = userId;
        cell.deleteMode = self.deleteMode;
    } else {
        if (indexPath.row == self.userIds.count) {
            [cell.headerImageView setImage:[UIImage imageNamed:@"addmember"]];
        } else {
            [cell.headerImageView setImage:[UIImage imageNamed:@"removemember"]];
        }
        cell.userId = nil;
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.userIds.count) {
        [self addMoreUser];
    } else if (indexPath.row == self.userIds.count + 1) {
        self.deleteMode = YES;
        [self.collectionView reloadData];
    } else {
        if (self.deleteMode) {
            NSString *userId = [self.userIds objectAtIndex:indexPath.row];
            [self.userIds removeObjectAtIndex:indexPath.row];
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
            if ([self.userIdsToAdd containsObject:userId]) {
                [self.userIdsToAdd removeObject:userId];
            } else {
                [self.userIdsToRemove addObject:userId];
            }
        }
    }
}

@end
