//
//  ConversationSettingMemberCell.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import "MomentMediaCell.h"
#import "SDWebImage.h"
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>


@interface MomentMediaCell ()

@end

@implementation MomentMediaCell
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    }
    return self;
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
        
        
        CGFloat insideMargin = 5;
        
        
        CGFloat minLength =
        MIN(self.bounds.size.width,
            self.bounds.size.height - insideMargin);
        
        _headerImageView.frame = CGRectMake(
                                                (self.bounds.size.width - minLength) / 2, 0, minLength, minLength);

        
        [[self contentView] addSubview:_headerImageView];
    }
    return _headerImageView;
}

@end
