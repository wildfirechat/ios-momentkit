//
//  MomentsMessageCell.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/23.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "MomentsMessageCell.h"
#import <WFMomentClient/WFMomentClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import <SDWebImage/SDWebImage.h>


@interface MomentsMessageCell()
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *digestLabel;
@property(nonatomic, strong)UIImageView *likeView;
@property(nonatomic, strong)UILabel *timeLabel;
@property(nonatomic, strong)UIImageView *mediaView;
@property(nonatomic, strong)UILabel *feedTextLabel;

@property(nonatomic, strong)WFMFeedMessageContent *feedContent;
@property(nonatomic, strong)WFMCommentMessageContent *commentContent;
@end

@implementation MomentsMessageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectMake(8, 8, 56, 56)];
        _portraitView.layer.cornerRadius = 8;
        _portraitView.clipsToBounds = YES;
        [self addSubview:_portraitView];
    }
    return _portraitView;
}

- (UIImageView *)mediaView {
    if (!_mediaView) {
        _mediaView = [[UIImageView alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 72, 8, 64, 64)];
        [self addSubview:_mediaView];
    }
    return _mediaView;
}
- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 10, [UIScreen mainScreen].bounds.size.width - 152, 20)];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.font = [UIFont systemFontOfSize:15];
        _nameLabel.textColor = [UIColor blueColor];
        [self addSubview:_nameLabel];
    }
    return _nameLabel;
}

- (UILabel *)feedTextLabel {
    if (!_feedTextLabel) {
        _feedTextLabel = [[UILabel alloc] initWithFrame:self.mediaView.bounds];
        _feedTextLabel.textAlignment = NSTextAlignmentLeft;
        _feedTextLabel.font = [UIFont systemFontOfSize:15];
        _feedTextLabel.textColor = [UIColor grayColor];
        _feedTextLabel.hidden = YES;
        _feedTextLabel.numberOfLines = 0;
        _feedTextLabel.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
        [self.mediaView addSubview:_feedTextLabel];
    }
    return _feedTextLabel;
}

- (UILabel *)digestLabel {
    if (!_digestLabel) {
        _digestLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 32, [UIScreen mainScreen].bounds.size.width - 152, 20)];
        _digestLabel.textAlignment = NSTextAlignmentLeft;
        _digestLabel.font = [UIFont systemFontOfSize:15];
        [self addSubview:_digestLabel];
    }
    return _digestLabel;
}

- (UIImageView *)likeView {
    if (!_likeView) {
        _likeView = [[UIImageView alloc] initWithFrame:CGRectMake(72, 32, 20, 20)];
        _likeView.image = [UIImage imageNamed:@"Like"];
        [self addSubview:_likeView];
    }
    return _likeView;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 54, [UIScreen mainScreen].bounds.size.width - 152, 20)];
        _timeLabel.textAlignment = NSTextAlignmentLeft;
        _timeLabel.font = [UIFont systemFontOfSize:12];
        _timeLabel.textColor = [UIColor grayColor];
        [self addSubview:_timeLabel];
    }
    return _timeLabel;
}

- (void)setObject:(WFCCMessage *)object {
    _object = object;
    if ([object.content isKindOfClass:[WFMCommentMessageContent class]]) {
        self.commentContent = (WFMCommentMessageContent *)object.content;
        self.feedContent = nil;
        [self updateCell];
    } else if ([object.content isKindOfClass:[WFMFeedMessageContent class]]) {
        self.feedContent = (WFMFeedMessageContent *)object.content;
        self.commentContent = nil;
        [self updateCell];
    }
}

- (void)updateCell {
    if (self.commentContent) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.commentContent.sender refresh:NO];
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        self.nameLabel.text = userInfo.displayName;
        if (self.commentContent.type == WFMComment_Thumbup_Type) {
            self.digestLabel.hidden = YES;
            self.likeView.hidden = NO;
        } else {
            self.digestLabel.hidden = NO;
            self.likeView.hidden = YES;
            self.digestLabel.text = self.commentContent.text;
        }
        self.timeLabel.text = [MomentsMessageCell formatTimeDetailLabel:self.commentContent.serverTime];

        if (self.commentContent.feedMedias.count) {
            [self.mediaView sd_setImageWithURL:[NSURL URLWithString:self.commentContent.feedMedias[0].mediaUrl]];
            self.feedTextLabel.hidden = YES;
        } else {
            self.mediaView.image = nil;
            if (self.commentContent.feedText != nil) {
                self.feedTextLabel.hidden = NO;
                self.feedTextLabel.text = self.commentContent.feedText;
            }
        }
    } else if(self.feedContent) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.feedContent.sender refresh:NO];
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [WFCUImage imageNamed:@"PersonalChat"]];
        self.nameLabel.text = userInfo.displayName;
        self.digestLabel.text = self.feedContent.text;
        self.timeLabel.text = [MomentsMessageCell formatTimeDetailLabel:self.object.serverTime];
        if (self.feedContent.medias.count) {
            [self.mediaView sd_setImageWithURL:[NSURL URLWithString:self.feedContent.medias[0].mediaUrl]];
        } else {
            self.mediaView.image = nil;
        }
        
    }
}

+ (NSString *)formatTimeDetailLabel:(int64_t)timestamp {
    if (timestamp == 0) {
        return nil;
    }
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp/1000];
    NSDate *current = [[NSDate alloc] init];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger days = [calendar component:NSCalendarUnitDay fromDate:date];
    NSInteger curDays = [calendar component:NSCalendarUnitDay fromDate:current];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSString *time =  [formatter stringFromDate:date];
    
    if (days == curDays) {
        return time;
    } else if(days == curDays -1) {
        return [NSString stringWithFormat:@"昨天 %@", time];
    } else {
        NSInteger weeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:date];
        NSInteger curWeeks = [calendar component:NSCalendarUnitWeekOfYear fromDate:current];
        
        NSInteger weekDays = [calendar component:NSCalendarUnitWeekday fromDate:date];
        if (weeks == curWeeks) {
            return [NSString stringWithFormat:@"%@ %@", [MomentsMessageCell formatWeek:weekDays], time];
        } /*else if (weeks == curWeeks - 1) {
           if (weekDays == 1) {
           return [NSString stringWithFormat:@"%@ %@", [Utilities formatWeek:weekDays], time];
           } else {
           return [NSString stringWithFormat:@"上%@ %@", [Utilities formatWeek:weekDays], time];
           }
           }*/ else {
               NSInteger year = [calendar component:NSCalendarUnitYear fromDate:date];
               NSInteger curYear = [calendar component:NSCalendarUnitYear fromDate:current];
               
               NSInteger month = [calendar component:NSCalendarUnitMonth fromDate:date];
               NSInteger curMonth = [calendar component:NSCalendarUnitMonth fromDate:current];
               if (month == curMonth) {
                   [formatter setDateFormat:@"dd'日'HH':'mm"];
                   return [formatter stringFromDate:date];
               } else if (year == curYear) {
                   [formatter setDateFormat:@"MM'月'dd'日'HH':'mm"];
                   return [formatter stringFromDate:date];
               } else {
                   [formatter setDateFormat:@"yyyy'年'MM'月'dd'日'HH':'mm"];
                   return [formatter stringFromDate:date];
               }
           }
    }
}
+ (NSString *)formatWeek:(NSUInteger)weekDays {
    weekDays = weekDays % 7;
    switch (weekDays) {
        case 2:
            return @"周一";
        case 3:
            return @"周二";
        case 4:
            return @"周三";
        case 5:
            return @"周四";
        case 6:
            return @"周五";
        case 0:
            return @"周六";
        case 1:
            return @"周日";
            
        default:
            break;
    }
    return nil;
}
@end
