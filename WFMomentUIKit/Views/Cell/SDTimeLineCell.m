//
//  SDTimeLineCell.m
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
 * QQ交流群: 459274049
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

#import "SDTimeLineCell.h"

#import "SDTimeLineCellModel.h"
#import "UIView+SDAutoLayout.h"

#import "SDTimeLineCellCommentView.h"

#import "SDWeiXinPhotoContainerView.h"

#import "SDTimeLineCellOperationMenu.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "UIFont+YH.h"

const CGFloat contentLabelFontSize = 15;
CGFloat maxContentLabelHeight = 0; // 根据具体font而定

NSString *const kSDTimeLineCellOperationButtonClickedNotification = @"SDTimeLineCellOperationButtonClickedNotification";

@implementation SDTimeLineCell

{
    UIImageView *_iconView;
    UILabel *_nameLable;
    UILabel *_contentLabel;
    SDWeiXinPhotoContainerView *_picContainerView;
    UILabel *_timeLabel;
    
    UIButton *_groupBtn;
    UIButton *_deleteBtn;
    
    UIButton *_moreButton;
    UIButton *_operationButton;
    SDTimeLineCellCommentView *_commentView;
    SDTimeLineCellOperationMenu *_operationMenu;
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self setup];
        
        //设置主题
        [self configTheme];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)setup
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receiveOperationButtonClickedNotification:) name:kSDTimeLineCellOperationButtonClickedNotification object:nil];
    
    _iconView = [UIImageView new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(portraitClicked)];
    [_iconView addGestureRecognizer:tap];
    _iconView.userInteractionEnabled = YES;
    _iconView.layer.cornerRadius = 10;
    _iconView.layer.cornerRadius = 10;
    
    _nameLable = [UILabel new];
    _nameLable.font = [UIFont pingFangSCWithWeight:FontWeightStyleMedium size:17];
    _nameLable.textColor = [UIColor colorWithRed:91/255.0 green:110/255.0 blue:142/255.0 alpha:1.0];
    
    _contentLabel = [UILabel new];
    _contentLabel.font = [UIFont pingFangSCWithWeight:FontWeightStyleRegular size:contentLabelFontSize];
    _contentLabel.textColor = [UIColor blackColor];
    _contentLabel.numberOfLines = 0;
    if (maxContentLabelHeight == 0) {
        maxContentLabelHeight = _contentLabel.font.lineHeight * 3;
    }
    
    _moreButton = [UIButton new];
    [_moreButton setTitle:@"全文" forState:UIControlStateNormal];
    [_moreButton setTitleColor:TimeLineCellHighlightedColor forState:UIControlStateNormal];
    [_moreButton addTarget:self action:@selector(moreButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    _moreButton.titleLabel.font = [UIFont systemFontOfSize:14];
    
    _operationButton = [UIButton new];
    [_operationButton setImage:[UIImage imageNamed:@"AlbumOperateMore"] forState:UIControlStateNormal];
    _operationButton.backgroundColor = [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1.0];
    _operationButton.layer.cornerRadius = 2;
    [_operationButton addTarget:self action:@selector(operationButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    _picContainerView = [SDWeiXinPhotoContainerView new];
    
    _commentView = [SDTimeLineCellCommentView new];
    
    _timeLabel = [UILabel new];
    _timeLabel.font = [UIFont systemFontOfSize:13];
    
    _groupBtn = [[UIButton alloc] init];
    [_groupBtn setImage:[UIImage imageNamed:@"VisiableGroup"] forState:UIControlStateNormal];
    [_groupBtn addTarget:self action:@selector(onGroupBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    _deleteBtn = [[UIButton alloc] init];
    [_deleteBtn setTitle:@"删除" forState:UIControlStateNormal];
    [_deleteBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    _deleteBtn.titleLabel.font = [UIFont systemFontOfSize:12];
    [_deleteBtn addTarget:self action:@selector(onDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    _operationMenu = [SDTimeLineCellOperationMenu new];
    __weak typeof(self) weakSelf = self;
    [_operationMenu setLikeButtonClickedOperation:^{
        if ([weakSelf.delegate respondsToSelector:@selector(didClickLikeButtonInCell:)]) {
            [weakSelf.delegate didClickLikeButtonInCell:weakSelf];
        }
    }];
    [_operationMenu setCommentButtonClickedOperation:^{
        if ([weakSelf.delegate respondsToSelector:@selector(didClickCommentButtonInCell:)]) {
            [weakSelf.delegate didClickCommentButtonInCell:weakSelf];
        }
    }];
    
    
    NSArray *views = @[_iconView, _nameLable, _contentLabel, _moreButton, _picContainerView, _timeLabel, _groupBtn, _deleteBtn, _operationButton, _operationMenu, _commentView];
    
    [self.contentView sd_addSubviews:views];
    
    UIView *contentView = self.contentView;
    CGFloat margin = 10;
    
    _iconView.sd_layout
    .leftSpaceToView(contentView, margin)
    .topSpaceToView(contentView, margin + 5)
    .widthIs(42)
    .heightIs(42);
    
    _nameLable.sd_layout
    .leftSpaceToView(_iconView, margin)
    .topEqualToView(_iconView)
    .heightIs(18);
    [_nameLable setSingleLineAutoResizeWithMaxWidth:200];
    

    
    _contentLabel.sd_layout
    .leftEqualToView(_nameLable)
    .topSpaceToView(_nameLable, margin)
    .rightSpaceToView(contentView, margin)
    .autoHeightRatio(0);
    
    // morebutton的高度在setmodel里面设置
    _moreButton.sd_layout
    .leftEqualToView(_contentLabel)
    .topSpaceToView(_contentLabel, 0)
    .widthIs(30);
    
    
    _picContainerView.sd_layout
    .leftEqualToView(_contentLabel); // 已经在内部实现宽度和高度自适应所以不需要再设置宽度高度，top值是具体有无图片在setModel方法中设置
    
    _timeLabel.sd_layout
    .leftEqualToView(_contentLabel)
    .topSpaceToView(_picContainerView, margin)
    .heightIs(15);
    [_timeLabel setSingleLineAutoResizeWithMaxWidth:60];
    
    _groupBtn.sd_layout
    .leftSpaceToView(_timeLabel, margin)
    .topSpaceToView(_picContainerView, margin)
    .heightIs(15)
    .widthIs(40);
    
    _deleteBtn.sd_layout
    .leftSpaceToView(_timeLabel, 60)
    .topSpaceToView(_picContainerView, margin)
    .heightIs(15)
    .widthIs(40);
    
    _operationButton.sd_layout
    .rightSpaceToView(contentView, margin)
    .centerYEqualToView(_timeLabel)
    .heightIs(18)
    .widthIs(30);
    
    _commentView.sd_layout
    .leftEqualToView(_contentLabel)
    .rightSpaceToView(self.contentView, margin)
    .topSpaceToView(_timeLabel, margin); // 已经在内部实现高度自适应所以不需要再设置高度
    
    _operationMenu.sd_layout
    .rightSpaceToView(_operationButton, 10)
    .heightIs(36)
    .centerYEqualToView(_operationButton)
    .widthIs(0);
}
- (void)onGroupBtn:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didClickGroupButtonInCell:)]) {
        [self.delegate didClickGroupButtonInCell:self];
    }
}
- (void)onDeleteBtn:(id)sender {
    if ([self.delegate respondsToSelector:@selector(didClickDeleteButtonInCell:)]) {
        [self.delegate didClickDeleteButtonInCell:self];
    }
}
- (void)configTheme{
    self.backgroundColor = [UIColor whiteColor];
    _contentLabel.textColor = [WFCUConfigManager globalManager].textColor;
    _timeLabel.textColor = [UIColor lightGrayColor];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setModel:(SDTimeLineCellModel *)model
{
    _model = model;
    
    
//    model.commentItemsArray
    NSMutableArray<SDTimeLineCellCommentItemModel *> *commentModels = [[NSMutableArray alloc] init];
    NSMutableArray<SDTimeLineCellLikeItemModel *> *likeModels = [[NSMutableArray alloc] init];
    
    NSArray<WFMComment *> * comments = model.feed.comments;
    for (WFMComment *comment in comments) {
        if (comment.type == WFMComment_Comment_Type) {
            SDTimeLineCellCommentItemModel *commentModel = [[SDTimeLineCellCommentItemModel alloc] init];
            commentModel.commentString = comment.text;
            WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:comment.sender refresh:NO];
            commentModel.firstUserId = comment.sender;
            commentModel.firstUserName = sender.displayName;
            if (commentModel.firstUserName == nil) {
                commentModel.firstUserName = [NSString stringWithFormat:@"<%@>", comment.sender];
            }
            if (comment.replyTo.length) {
                WFCCUserInfo *reply = [[WFCCIMService sharedWFCIMService] getUserInfo:comment.replyTo refresh:NO];
                commentModel.secondUserId = comment.replyTo;
                commentModel.secondUserName = reply.displayName;
                if (commentModel.secondUserName == nil) {
                    commentModel.secondUserName = [NSString stringWithFormat:@"<%@>", comment.replyTo];
                }
            }
            commentModel.comment = comment;
            [commentModels addObject:commentModel];
        } else {
            SDTimeLineCellLikeItemModel *likeModel = [[SDTimeLineCellLikeItemModel alloc] init];
            WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:comment.sender refresh:NO];
            likeModel.userId = comment.sender;
            likeModel.userName = sender.displayName;
            likeModel.comment = comment;
            if ([comment.sender isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                self.model.liked = YES;
            }
            [likeModels addObject:likeModel];
        }
        
    }
    _model.commentItemsArray = commentModels;
    _model.likeItemsArray = likeModels;
    
    
    [_commentView setupWithLikeItemsArray:model.likeItemsArray commentItemsArray:model.commentItemsArray];
    __weak typeof(self) ws = self;
    [_commentView setDidClickCommentLabelBlock:^(long long commentId, NSString *commentUserId, CGRect rectInWindow, UIView *commetView) {
        ws.didClickCommentLabelBlock(commentId, commentUserId, rectInWindow, ws, commetView);
    }];
    
    [_iconView sd_setImageWithURL:[NSURL URLWithString:model.iconName] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    _nameLable.text = model.name;
    _contentLabel.text = model.msgContent;
    _picContainerView.picPathStringsArray = model.picNamesArray;
    _picContainerView.feed = model.feed;
    
    if (model.shouldShowMoreButton) { // 如果文字高度超过60
        _moreButton.sd_layout.heightIs(20);
        _moreButton.hidden = NO;
        if (model.isOpening) { // 如果需要展开
            _contentLabel.sd_layout.maxHeightIs(MAXFLOAT);
            [_moreButton setTitle:@"收起" forState:UIControlStateNormal];
        } else {
            _contentLabel.sd_layout.maxHeightIs(maxContentLabelHeight);
            [_moreButton setTitle:@"全文" forState:UIControlStateNormal];
        }
    } else {
        _moreButton.sd_layout.heightIs(0);
        _moreButton.hidden = YES;
    }
    
    CGFloat picContainerTopMargin = 0;
    if (model.picNamesArray.count) {
        picContainerTopMargin = 10;
    }
    _picContainerView.sd_layout.topSpaceToView(_moreButton, picContainerTopMargin);
    
    UIView *bottomView;
    
    if (!model.commentItemsArray.count && !model.likeItemsArray.count) {
        bottomView = _timeLabel;
    } else {
        bottomView = _commentView;
    }
    
    [self setupAutoHeightWithBottomView:bottomView bottomMargin:15];
    
    NSDate *datenow =[NSDate date];
    long long diff = datenow.timeIntervalSince1970*1000 - model.feed.serverTime;
    NSString *timeTxt;
    if (diff < 60 * 1000) {
        timeTxt = @"刚刚";
    } else if(diff < 60 * 60 * 1000) {
        timeTxt = [NSString stringWithFormat:@"%d分钟前", (int)(diff/(60 * 1000))];
    } else if(diff < 24 * 60 * 60 * 1000) {
        timeTxt = [NSString stringWithFormat:@"%d小时前", (int)(diff/(60 * 60 * 1000))];
    } else {
        timeTxt = [NSString stringWithFormat:@"%d天前", (int)(diff/(24 * 60 * 60 * 1000))];
    }
    _timeLabel.text = timeTxt;
    
    if ([model.feed.sender isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        _deleteBtn.hidden = NO;
        if (model.feed.toUsers.count + model.feed.excludeUsers.count) {
            _groupBtn.hidden = NO;
        } else {
            _groupBtn.hidden = YES;
        }
    } else {
        _deleteBtn.hidden = YES;
        _groupBtn.hidden = YES;
    }
    
    
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_operationMenu.isShowing) {
        _operationMenu.show = NO;
    }
}

#pragma mark - private actions

- (void)moreButtonClicked {
    if (self.moreButtonClickedBlock) {
        self.moreButtonClickedBlock(self.indexPath);
    }
}

- (void)portraitClicked {
    if (self.portraitClickedBlock) {
        self.portraitClickedBlock(self.indexPath);
    }
}

- (void)operationButtonClicked
{
    [self postOperationButtonClickedNotification];
    _operationMenu.liked = self.model.isLiked;
    _operationMenu.show = !_operationMenu.isShowing;
}

- (void)receiveOperationButtonClickedNotification:(NSNotification *)notification
{
    UIButton *btn = [notification object];
    
    if (btn != _operationButton && _operationMenu.isShowing) {
        _operationMenu.show = NO;
    }
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self postOperationButtonClickedNotification];
    if (_operationMenu.isShowing) {
        _operationMenu.show = NO;
    }
}

- (void)postOperationButtonClickedNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kSDTimeLineCellOperationButtonClickedNotification object:_operationButton];
}

@end

