//
//  MomentsDetailCell.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/23.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "MomentsDetailCell.h"
#import <WFMomentClient/WFMomentClient.h>
#import <SDWebImage/SDWebImage.h>
#import <WFChatClient/WFCChatClient.h>
#import "UIView+SDAutoLayout.h"

@interface MomentsDetailCell()
@property(nonatomic, strong)UIImageView *portraitView;
@property(nonatomic, strong)UILabel *nameLabel;
@property(nonatomic, strong)UILabel *digestLabel;
@property(nonatomic, strong)UIImageView *likeView;
@property(nonatomic, strong)UILabel *timeLabel;
@end

@implementation MomentsDetailCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setLaylout];
    }
    return self;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setLaylout];
    }
    return self;
}

- (void)setLaylout {
    CGFloat margin = 10.f;
       self.portraitView.sd_layout
       .leftSpaceToView(self.contentView, margin)
       .topSpaceToView(self.contentView, margin)
       .widthIs(40)
       .heightIs(40);
       
       self.nameLabel.sd_layout
       .leftSpaceToView(self.portraitView, margin)
       .topEqualToView(self.portraitView)
       .heightIs(18);
       [self.nameLabel setSingleLineAutoResizeWithMaxWidth:200];
       
    self.timeLabel.sd_layout
    .rightSpaceToView(self.contentView, margin)
    .topEqualToView(self.portraitView)
    .heightIs(10);
    [self.timeLabel setSingleLineAutoResizeWithMaxWidth:80];
       
       self.digestLabel.sd_layout
       .leftEqualToView(self.nameLabel)
       .topSpaceToView(self.nameLabel, 5)
       .rightSpaceToView(self.contentView, margin)
       .autoHeightRatio(0);
    
        self.likeView.sd_layout
        .leftEqualToView(self.nameLabel)
        .topSpaceToView(self.nameLabel, 5)
        .widthIs(15)
        .heightIs(15);
 
    [self setupAutoHeightWithBottomViewsArray:@[self.digestLabel,  self.likeView, self.portraitView] bottomMargin:10];
}

- (UIImageView *)portraitView {
    if (!_portraitView) {
        _portraitView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _portraitView.layer.cornerRadius = 4;
        _portraitView.clipsToBounds = YES;
        [self.contentView addSubview:_portraitView];
    }
    return _portraitView;
}

- (UILabel *)nameLabel {
    if (!_nameLabel) {
        _nameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _nameLabel.textAlignment = NSTextAlignmentLeft;
        _nameLabel.font = [UIFont systemFontOfSize:14];
        _nameLabel.textColor = [UIColor blueColor];
        [self.contentView addSubview:_nameLabel];
    }
    return _nameLabel;
}


- (UILabel *)digestLabel {
    if (!_digestLabel) {
        _digestLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _digestLabel.textAlignment = NSTextAlignmentLeft;
        _digestLabel.font = [UIFont systemFontOfSize:15];
        [self.contentView addSubview:_digestLabel];
    }
    return _digestLabel;
}

- (UIImageView *)likeView {
    if (!_likeView) {
        _likeView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _likeView.image = [UIImage imageNamed:@"Like"];
        [self.contentView addSubview:_likeView];
    }
    return _likeView;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _timeLabel.textAlignment = NSTextAlignmentLeft;
        _timeLabel.font = [UIFont systemFontOfSize:10];
        _timeLabel.textColor = [UIColor grayColor];
        [self.contentView addSubview:_timeLabel];
    }
    return _timeLabel;
}
- (void)setComment:(WFMComment *)comment {
    _comment = comment;
    [self updateCell];
}

- (void)updateCell {
    if (self.comment) {
        WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.comment.sender refresh:NO];
        [self.portraitView sd_setImageWithURL:[NSURL URLWithString:userInfo.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
        self.nameLabel.text = userInfo.displayName;
        if (self.comment.type == WFMComment_Thumbup_Type) {
            self.digestLabel.hidden = YES;
            self.digestLabel.text = @"";
            self.likeView.hidden = NO;
            self.likeView.sd_layout.heightIs(15);
        } else {
            self.digestLabel.hidden = NO;
            self.likeView.hidden = YES;
            self.likeView.sd_layout.heightIs(0);
            self.digestLabel.text = self.comment.text;
        }
        self.timeLabel.text = [MomentsDetailCell formatTimeDetailLabel:self.comment.serverTime];
    }
}

+ (NSString *)formatTimeDetailLabel:(int64_t)timestamp {
    if (timestamp == 0) {
        return @" ";
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
            return [NSString stringWithFormat:@"%@ %@", [MomentsDetailCell formatWeek:weekDays], time];
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
