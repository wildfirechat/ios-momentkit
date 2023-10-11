//
//  SDTimeLineTableHeaderView.m
//  GSD_WeiXin(wechat)
//
//  Created by gsd on 16/2/25.
//  Copyright © 2016年 GSD. All rights reserved.
//

/*
 
 *********************************************************************************
 *
 * GSD_WeiXin
 *
 * QQ交流群: 362419100(2群) 459274049（1群已满）
 * Email : gsdios@126.com
 * GitHub: https://github.com/gsdios/GSD_WeiXin
 * 新浪微博:GSD_iOS
 *
 * 此“高仿微信”用到了很高效方便的自动布局库SDAutoLayout（一行代码搞定自动布局）
 * SDAutoLayout地址：https://github.com/gsdios/SDAutoLayout
 * SDAutoLayout视频教程：http://www.letv.com/ptv/vplay/24038772.html
 * SDAutoLayout用法示例：https://github.com/gsdios/SDAutoLayout/blob/master/README.md
 *
 *********************************************************************************
 
 */

#import "SDTimeLineTableHeaderView.h"
#import <WFChatClient/WFCChatClient.h>
#import "UIView+SDAutoLayout.h"
#import <SDWebImage/SDWebImage.h>
#import <WFMomentClient/WFMomentClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "UIColor+YH.h"
#import "UIFont+YH.h"
@interface SDTimeLineTableHeaderView ()
@property(nonatomic, strong)UIImageView *backgroundImageView;
@property(nonatomic, strong)UILabel *backgroundTipLabel;

@end

@implementation SDTimeLineTableHeaderView

{
    UIImageView *_iconView;
    UILabel *_nameLabel;
    UIView *_newMsgContainer;
    UIImageView *_newMsgIconView;
    UILabel *_newMsgLabelView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:NO];
    _backgroundImageView = [UIImageView new];
    _backgroundImageView.image = [UIImage imageNamed:@"AlbumBg"];
    [self addSubview:_backgroundImageView];
    
    _backgroundTipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 20)];
    _backgroundTipLabel.text = @"点击更换背景";
    _backgroundTipLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundTipLabel.textColor = [UIColor grayColor];
    _backgroundTipLabel.font = [UIFont systemFontOfSize:14];
    [_backgroundImageView addSubview:_backgroundTipLabel];
    
    _iconView = [UIImageView new];
    _iconView.backgroundColor = [UIColor clearColor];
    [_iconView sd_setImageWithURL:[NSURL URLWithString:me.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    _iconView.layer.borderColor = [UIColor whiteColor].CGColor;
    _iconView.layer.borderWidth = 2;
    _iconView.layer.masksToBounds = YES;
    [self addSubview:_iconView];
    
    _nameLabel = [UILabel new];
    _nameLabel.text = me.displayName;
    _nameLabel.textColor = [WFCUConfigManager globalManager].backgroudColor;
    _nameLabel.textAlignment = NSTextAlignmentRight;
    _nameLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:20];
    [self addSubview:_nameLabel];
    
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    //-60, 0, 40, 0
    _backgroundImageView.frame = CGRectMake(0, -60, screenWidth, self.bounds.size.height + 20);
    _backgroundTipLabel.frame = CGRectMake((screenWidth-120)/2, self.bounds.size.height/2, 120, 20);
    
    _iconView.frame = CGRectMake(screenWidth-15-70, self.bounds.size.height-70 - 20, 70, 70);
    _iconView.layer.cornerRadius = 10;
    
    _nameLabel.tag = 1000;
//    [_nameLabel setSingleLineAutoResizeWithMaxWidth:200];
    _nameLabel.frame = CGRectMake(screenWidth-15-70-150-4, self.bounds.size.height-70, 150, 20);
    
    _newMsgContainer = [[UIView alloc] initWithFrame:CGRectMake((screenWidth - 120)/2, self.bounds.size.height - 32, 120, 36)];
    [_newMsgContainer setBackgroundColor:[UIColor grayColor]];
    _newMsgContainer.layer.masksToBounds = YES;
    _newMsgContainer.layer.cornerRadius = 4.0;
    [self addSubview:_newMsgContainer];
    
    _newMsgIconView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 24, 24)];;
    [_newMsgContainer addSubview:_newMsgIconView];
    
    _newMsgLabelView = [[UILabel alloc] initWithFrame:CGRectMake(36, 0, 84, 36)];
    _newMsgLabelView.textColor = [WFCUConfigManager globalManager].backgroudColor;
    _newMsgLabelView.textAlignment = NSTextAlignmentLeft;
    _newMsgLabelView.font = [UIFont boldSystemFontOfSize:15];
    [_newMsgContainer addSubview:_newMsgLabelView];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newMessageClicked:)];

    [_newMsgContainer addGestureRecognizer:singleTap];
    _newMsgContainer.hidden = YES;
}

- (void)setUserId:(NSString *)userId {
    BOOL firstSet = !_userId;
    BOOL refresh = firstSet && ![userId isEqualToString:[WFCCNetworkService sharedInstance].userId];
    
    _userId = userId;
    WFCCUserInfo *me = [[WFCCIMService sharedWFCIMService] getUserInfo:self.userId refresh:refresh];
    _nameLabel.text = me.displayName;
    [_iconView sd_setImageWithURL:[NSURL URLWithString:me.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onUserInfoUpdated:) name:kUserInfoUpdated object:userId];
    
    if ([userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        self.backgroundTipLabel.hidden = NO;
        if (firstSet) {
            UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBackgroundView:)];
            [self addGestureRecognizer:tap];
        }
    } else {
        self.backgroundTipLabel.hidden = YES;
    }
    __weak typeof(self)ws = self;
    
    [[WFMomentService sharedService] getUserProfile:userId success:^(WFMomentProfiles * _Nonnull profile) {
        if (profile.backgroupUrl.length) {
            [ws.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:profile.backgroupUrl] placeholderImage:[UIImage imageNamed:@"AlbumBg"]];
            ws.backgroundTipLabel.hidden = YES;
        } else {
            ws.backgroundTipLabel.hidden = NO;
        }
        
    } error:^(int error_code) {
        
    }];
}

- (void)onTapBackgroundView:(id)sender {
    [self.delegate onChangeBackground];
}

- (void)onUserInfoUpdated:(NSNotification *)notification {
    WFCCUserInfo *userInfo = notification.userInfo[@"userInfo"];
    if ([self.userId isEqualToString:userInfo.userId]) {
        _nameLabel.text = userInfo.displayName;
        [_iconView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
    }
}

- (void)newMessageClicked:(id)sender {
    [self.delegate onClickedNewMessageBtn];
}

- (void)updateNewMessageStatus {
    NSArray<WFCCMessage *> *newMessages = [[WFMomentService sharedService] getMessages:YES];
    if (newMessages.count == 0) {
        _newMsgContainer.hidden = YES;
    } else {
        _newMsgContainer.hidden = NO;
        _newMsgLabelView.text = [NSString stringWithFormat:@"%ld条新消息", newMessages.count];
        

        WFCCMessageContent *lastContent = newMessages[0].content;
        if ([lastContent isKindOfClass:[WFMFeedMessageContent class]]) {
            WFMFeedMessageContent *feedContent = (WFMFeedMessageContent *)lastContent;
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:feedContent.sender refresh:NO];
            [_newMsgIconView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        } else if ([lastContent isKindOfClass:[WFMCommentMessageContent class] ]) {
            WFMCommentMessageContent *commentContent = (WFMCommentMessageContent *)lastContent;
            WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:commentContent.sender refresh:NO];
            [_newMsgIconView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        }
        

    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
