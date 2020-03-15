//
//  FeedDetailViewController.m
//  WFMomentUIKit
//
//  Created by Heavyrain Lee on 2020/3/14.
//  Copyright © 2020 Heavyrain Lee. All rights reserved.
//

#import "FeedDetailViewController.h"
#import "MomentsDetailCell.h"
#import "SDTimeLineCellOperationMenu.h"
#import "SDWeiXinPhotoContainerView.h"
#import "UIView+SDAutoLayout.h"
#import "UITableView+SDAutoTableViewCellHeight.h"
#import "SDWebImage.h"
#import "MBProgressHUD.h"


extern const CGFloat contentLabelFontSize;
extern CGFloat maxContentLabelHeight; // 根据具体font而定



@interface FeedDetailViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong)UITableView *tableView;

@property(nonatomic, strong)WFMCommentMessageContent *content;
@property(nonatomic, strong)WFMFeed *feed;

@property(nonatomic, strong)UIImageView *iconView;
@property(nonatomic, strong)UILabel *nameLable;
@property(nonatomic, strong)UILabel *contentLabel;
@property(nonatomic, strong)SDWeiXinPhotoContainerView *picContainerView;
@property(nonatomic, strong)UILabel *timeLabel;
@property(nonatomic, strong)UIButton *groupBtn;
@property(nonatomic, strong)UIButton *deleteBtn;
@property(nonatomic, strong)UIButton *operationButton;
@property(nonatomic, strong)SDTimeLineCellOperationMenu *operationMenu;



@end

@implementation FeedDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableHeaderView = [self getHeaderView];
    
    
    WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:self.content.sender refresh:NO];
    [self.iconView sd_setImageWithURL:[NSURL URLWithString:sender.portrait] placeholderImage: [UIImage imageNamed:@"PersonalChat"]];
    if (sender.friendAlias.length) {
        self.nameLable.text = sender.friendAlias;
    } else {
        self.nameLable.text = sender.displayName;
    }
//    WFMContent_Text_Type,
//    WFMContent_Image_Type,
//    WFMContent_Video_Type,
//    WFMContent_Link_Type
    if (self.content.type == WFMContent_Text_Type || self.content.type == WFMContent_Image_Type || self.content.type == WFMContent_Video_Type) {
        self.contentLabel.text = self.content.text;
    }
    self.picContainerView.picPathStringsArray = self.content.feedMedias;
    
    self.timeLabel.text = [FeedDetailViewController formatTimeDetailLabel:self.message.serverTime];
    
    self.groupBtn.hidden = YES;
    self.deleteBtn.hidden = YES;
    
    [self.tableView layoutIfNeeded];
    self.tableView.tableFooterView = self.tableView.tableFooterView;
    
    [self.tableView reloadData];
    [self.view addSubview:self.tableView];
    
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapBackground:)]];
    __weak typeof(self)ws = self;
    [[WFMomentService sharedService] getFeed:self.content.feedId success:^(WFMFeed * _Nonnull feed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            ws.feed = feed;
        });
    } error:^(int error_code) {
        
    }];
}

- (void)setFeed:(WFMFeed *)feed {
    _feed = feed;
    if ([self.feed.sender isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
        self.deleteBtn.hidden = NO;
        if (self.feed.toUsers.count) {
            self.groupBtn.hidden = NO;
        } else {
            self.groupBtn.hidden = YES;
        }
    } else {
        self.groupBtn.hidden = YES;
        self.deleteBtn.hidden = YES;
    }
    [self.tableView reloadData];
}

-(UIView *)getHeaderView {

    _iconView = [UIImageView new];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(portraitClicked)];
    [_iconView addGestureRecognizer:tap];
    _iconView.userInteractionEnabled = YES;


    _nameLable = [UILabel new];
    _nameLable.font = [UIFont systemFontOfSize:14];
    _nameLable.textColor = [UIColor colorWithRed:(54 / 255.0) green:(71 / 255.0) blue:(121 / 255.0) alpha:0.9];

    _contentLabel = [UILabel new];
    _contentLabel.font = [UIFont systemFontOfSize:contentLabelFontSize];
    _contentLabel.numberOfLines = 0;
    if (maxContentLabelHeight == 0) {
       maxContentLabelHeight = _contentLabel.font.lineHeight * 3;
    }

    _operationButton = [UIButton new];
    [_operationButton setImage:[UIImage imageNamed:@"AlbumOperateMore"] forState:UIControlStateNormal];
    [_operationButton addTarget:self action:@selector(operationButtonClicked) forControlEvents:UIControlEventTouchUpInside];

    _picContainerView = [SDWeiXinPhotoContainerView new];


    _timeLabel = [UILabel new];
    _timeLabel.font = [UIFont systemFontOfSize:12];

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
       
    }];
    [_operationMenu setCommentButtonClickedOperation:^{
       
    }];

    UIView *contentView = [[UIView alloc] init];
    NSArray *views = @[_iconView, _nameLable, _contentLabel, _picContainerView, _timeLabel, _groupBtn, _deleteBtn, _operationButton, _operationMenu];

    [contentView sd_addSubviews:views];

    CGFloat margin = 10;

    _iconView.sd_layout
    .leftSpaceToView(contentView, margin)
    .topSpaceToView(contentView, margin)
    .widthIs(40)
    .heightIs(40);

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


    _picContainerView.sd_layout
    .leftEqualToView(_contentLabel)
    .topSpaceToView(_contentLabel, margin);

    _timeLabel.sd_layout
    .leftEqualToView(_contentLabel)
    .topSpaceToView(_picContainerView, margin)
    .heightIs(12);
    [_timeLabel setSingleLineAutoResizeWithMaxWidth:80];

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
    .heightIs(25)
    .widthIs(25);


    _operationMenu.sd_layout
    .rightSpaceToView(_operationButton, 0)
    .heightIs(36)
    .centerYEqualToView(_operationButton)
    .widthIs(0);
    
    [contentView setupAutoHeightWithBottomView:self.timeLabel bottomMargin:10];
    
    return contentView;
}

- (void)portraitClicked {
    
}

- (void)operationButtonClicked {
    BOOL isLiked = NO;
    for (WFMComment *comment in self.feed.comments) {
        if (comment.type == WFMComment_Thumbup_Type && [comment.sender isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            isLiked = YES;
            break;
        }
    }
    _operationMenu.liked = isLiked;
    _operationMenu.show = !_operationMenu.isShowing;
}

- (void)onGroupBtn:(id)sender {
    
}

- (void)onDeleteBtn:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.label.text = @"处理中...";
    [hud showAnimated:YES];
    
    __weak typeof(self)ws = self;
    [[WFMomentService sharedService] deleteFeed:self.feed.feedUid success:^{
        [hud hideAnimated:YES];
        [ws.navigationController popViewControllerAnimated:YES];
    } error:^(int error_code) {
        [hud hideAnimated:YES];
    }];
}

- (void)onTapBackground:(id)sender {
    if (_operationMenu.isShowing) {
        _operationMenu.show = NO;
    }
}

- (WFMCommentMessageContent *)content {
    return (WFMCommentMessageContent *)self.message.content;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MomentsDetailCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MomentsDetailCell"];
    if (cell == nil) {
        cell = [[MomentsDetailCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MomentsDetailCell"];
    }
    cell.comment = [self.feed.comments objectAtIndex:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.feed.comments.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    // >>>>>>>>>>>>>>>>>>>>> * cell自适应 * >>>>>>>>>>>>>>>>>>>>>>>>
    id model = [self.feed.comments objectAtIndex:indexPath.row];
    return [self.tableView cellHeightForIndexPath:indexPath model:model keyPath:@"comment" cellClass:[MomentsDetailCell class] contentViewWidth:[self cellContentViewWith]];
}

- (CGFloat)cellContentViewWith
{
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    
    // 适配ios7横屏
    if ([UIApplication sharedApplication].statusBarOrientation != UIInterfaceOrientationPortrait && [[UIDevice currentDevice].systemVersion floatValue] < 8) {
        width = [UIScreen mainScreen].bounds.size.height;
    }
    return width;
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
            return [NSString stringWithFormat:@"%@ %@", [FeedDetailViewController formatWeek:weekDays], time];
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
