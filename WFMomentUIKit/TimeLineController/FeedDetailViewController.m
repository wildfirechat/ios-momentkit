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
#import <WFChatUIKit/WFChatUIKit.h>

extern const CGFloat contentLabelFontSize;
extern CGFloat maxContentLabelHeight; // 根据具体font而定

static CGFloat textFieldH = 40;

@interface FeedDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, WFCUFaceBoardDelegate>
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

@property (nonatomic, strong)WFCUFaceBoard *emojInputView;
@property (nonatomic, strong)UIView *inputBar;
@property (nonatomic, strong)UIButton *inputSwitchBtn;
@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong)NSString *commentToUser;
@property (nonatomic, assign)BOOL isReplayingComment;
@property (nonatomic, assign)CGFloat totalKeybordHeight;
@property (nonatomic, assign)long long selectedCommentId;
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
    [self setupTextField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuHidden:) name:UIMenuControllerDidHideMenuNotification object:nil];
}

- (void)onMenuHidden:(id)sender {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:nil];
    __weak typeof(self)ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ws.selectedCommentId = 0;
    });
    
}

- (UIButton *)inputSwitchBtn {
    if (!_inputSwitchBtn) {
        _inputSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.width_sd - textFieldH, 0, textFieldH, textFieldH)];
        
        [_inputSwitchBtn setImage:[UIImage imageNamed:@"chat_input_bar_emoj"] forState:UIControlStateNormal];
        [_inputSwitchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [_inputSwitchBtn addTarget:self action:@selector(onSwitchBtn:) forControlEvents:UIControlEventTouchDown];
        
        _inputSwitchBtn.layer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8].CGColor;
        _inputSwitchBtn.layer.borderWidth = 1;
    }
    return _inputSwitchBtn;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication].keyWindow addSubview:self.inputBar];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_textField resignFirstResponder];
    
    [self.inputBar removeFromSuperview];
}

- (WFCUFaceBoard *)emojInputView {
    if (!_emojInputView) {
        _emojInputView = [[WFCUFaceBoard alloc] init];
        _emojInputView.delegate = self;
        _emojInputView.disableSticker = YES;
    }
    return _emojInputView;
}

- (void)onSwitchBtn:(id)sender {
    if (self.textField.inputView == self.emojInputView) {
        self.textField.inputView = nil;
        [self.inputSwitchBtn setImage:[UIImage imageNamed:@"chat_input_bar_emoj"] forState:UIControlStateNormal];
    } else {
        self.textField.inputView = self.emojInputView;
        [self.inputSwitchBtn setImage:[UIImage imageNamed:@"chat_input_bar_keyboard"] forState:UIControlStateNormal];
    }
    [self.textField reloadInputViews];
}

- (UIView *)inputBar {
    if (!_inputBar) {
        _inputBar = [[UIView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.width_sd, textFieldH)];
        [_inputBar addSubview:self.textField];
        [_inputBar addSubview:self.inputSwitchBtn];
        _inputBar.layer.borderColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.8].CGColor;
        _inputBar.layer.borderWidth = 1;
    }
    return _inputBar;
}

- (void)setupTextField
{
    _textField = [UITextField new];
    _textField.returnKeyType = UIReturnKeyDone;
    _textField.delegate = self;
    
    //为textfield添加背景颜色 字体颜色的设置 还有block设置 , 在block中改变它的键盘样式 (当然背景颜色和字体颜色也可以直接在block中写)
    
    _textField.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    _textField.textColor = [WFCUConfigManager globalManager].textColor;

    _textField.frame = CGRectMake(0, 0, self.view.width_sd - textFieldH, textFieldH);
    
    [_textField becomeFirstResponder];
    [_textField resignFirstResponder];
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
        [weakSelf didClickLikeButtonInCell];
    }];
    [_operationMenu setCommentButtonClickedOperation:^{
       [weakSelf didClickCommentButtonInCell];
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


- (void)didClickCommentButtonInCell {
    [_textField becomeFirstResponder];
    [self adjustTableViewToFitKeyboard];
    
}

- (void)didClickLikeButtonInCell {
    
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

- (void)adjustTableViewToFitKeyboard
{
//    UIWindow *window = [UIApplication sharedApplication].keyWindow;
//    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_currentEditingIndexthPath];
//    CGRect rect = [cell.superview convertRect:cell.frame toView:window];
//    [self adjustTableViewToFitKeyboardWithRect:rect];
}

- (void)adjustTableViewToFitKeyboardWithRect:(CGRect)rect
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGFloat delta = CGRectGetMaxY(rect) - (window.bounds.size.height - _totalKeybordHeight);
    
    CGPoint offset = self.tableView.contentOffset;
    offset.y += delta;
    if (offset.y < 0) {
        offset.y = 0;
    }
    
    [self.tableView setContentOffset:offset animated:YES];
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_textField resignFirstResponder];
    _textField.placeholder = nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __weak typeof(self) weakSelf = self;
    if (textField.text.length) {
        [_textField resignFirstResponder];
        
        __block WFMComment *comment = [[WFMomentService sharedService] postComment:WFMContent_Text_Type feedId:self.feed.feedUid text:textField.text  replyTo:self.isReplayingComment?self.commentToUser:nil extra:nil success:^(long long commentId, long long timestamp) {
            comment.commentUid = commentId;
            comment.serverTime = timestamp;
            [self.feed.comments addObject:comment];
            [weakSelf.tableView reloadData];
        } error:^(int error_code) {
            
        }];

        _textField.text = @"";
        _textField.placeholder = nil;
        
        return YES;
    }
    return NO;
}

#pragma mark - WFCUFaceBoardDelegate <NSObject>
- (void)didTouchEmoj:(NSString *)emojString {
    [self.textField insertText:emojString];
}

- (void)didTouchBackEmoj {
    [self.textField deleteBackward];
}

- (void)didTouchSendEmoj {
    [self textFieldShouldReturn:self.textField];
}


- (void)keyboardNotification:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    CGRect rect = [dict[@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    
    
    
    CGRect textFieldRect = CGRectMake(0, rect.origin.y - textFieldH, rect.size.width, textFieldH);
    if (rect.origin.y == [UIScreen mainScreen].bounds.size.height) {
        textFieldRect = rect;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.inputBar.frame = textFieldRect;
    }];
    
    CGFloat h = rect.size.height + textFieldH;
    if (_totalKeybordHeight != h) {
        _totalKeybordHeight = h;
        [self adjustTableViewToFitKeyboard];
    }
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
-(void)dealloc {
    [_textField removeFromSuperview];
}
@end
