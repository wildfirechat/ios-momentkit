//
//  ConversationSettingMemberCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "MemberCell.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>


@interface MemberCell ()
@property(nonatomic, strong)UIImageView *deleteView;
@end

@implementation MemberCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    }
    return self;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.textColor = [UIColor blackColor];
        _nameLabel.textAlignment = NSTextAlignmentCenter;
        _nameLabel.backgroundColor = [UIColor clearColor];
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.hidden = YES;
        
        CGFloat nameLabelHeight = 16;

        _nameLabel.frame =
        CGRectMake(0, self.bounds.size.height - nameLabelHeight,
                   self.bounds.size.width, nameLabelHeight);
        if (nameLabelHeight > 0) {
            _nameLabel.hidden = NO;
        } else {
            _nameLabel.hidden = YES;
        }
        
        [[self contentView] addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UIImageView *)deleteView {
    if (!_deleteView) {
        _deleteView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, 12, 12)];
        _deleteView.image = [UIImage imageNamed:@"minus"];
        [self.headerImageView addSubview:_deleteView];
    }
    return _deleteView;
}

- (UIImageView *)headerImageView {
    if (!_headerImageView) {
        _headerImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _headerImageView.autoresizingMask =
        UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        _headerImageView.contentMode = UIViewContentModeScaleAspectFill;
        _headerImageView.clipsToBounds = YES;
        
        _headerImageView.layer.borderWidth = 1;
        _headerImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _headerImageView.layer.cornerRadius = 4;
        _headerImageView.layer.masksToBounds = YES;
        _headerImageView.backgroundColor = [UIColor clearColor];
        
        _headerImageView.layer.edgeAntialiasingMask =
        kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge |
        kCALayerTopEdge;
        
        
        CGFloat nameLabelHeight = 16;
        CGFloat insideMargin = 5;
        
        
        CGFloat minLength =
        MIN(self.bounds.size.width,
            self.bounds.size.height - nameLabelHeight - insideMargin);
        
        _headerImageView.frame = CGRectMake(
                                                (self.bounds.size.width - minLength) / 2, 0, minLength, minLength);

        
        [[self contentView] addSubview:_headerImageView];
    }
    return _headerImageView;
}

- (void)setUserId:(NSString *)userId {
    _userId = userId;
    
    if (userId) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId inGroup:nil refresh:NO];
        
        self.nameLabel.hidden = NO;
        self.nameLabel.text = userInfo.displayName;
        [self.headerImageView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    } else {
        self.nameLabel.hidden = YES;
    }
    
}

- (void)setDeleteMode:(BOOL)deleteMode {
    _deleteMode = deleteMode;
    if (deleteMode) {
        self.deleteView.hidden = NO;
    } else {
        self.deleteView.hidden = YES;
    }
}

- (void)resetLayout:(CGFloat)nameLabelHeight
       insideMargin:(CGFloat)insideMargin {
}
@end
