//
//  SDTimeLineTableViewController.m
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

#import "SDTimeLineTableViewController.h"

#import "SDRefresh.h"
#import <CoreText/CoreText.h>
#import "SDTimeLineTableHeaderView.h"
#import "SDTimeLineRefreshHeader.h"
#import "SDTimeLineRefreshFooter.h"
#import "SDTimeLineCell.h"
#import "SDTimeLineCellModel.h"
#import "CreateFeedViewController.h"
#import "UITableView+SDAutoTableViewCellHeight.h"
#import "MBProgressHUD.h"

#import "UIView+SDAutoLayout.h"
#import "Predefine.h"
#import <WFMomentClient/WFMomentClient.h>
#import <WFChatClient/WFCChatClient.h>
#import <WFChatUIKit/WFChatUIKit.h>
#import "MomentsMessageViewController.h"

#define kTimeLineTableViewCellId @"SDTimeLineCell"

static CGFloat textFieldH = 40;

@interface SDTimeLineTableViewController () <SDTimeLineCellDelegate, UITextFieldDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UIScrollViewDelegate, SDTimeLineTableHeaderViewDelegate, WFMomentReceiveMessageDelegate, WFCUFaceBoardDelegate, KZVideoViewControllerDelegate>

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) BOOL isReplayingComment;
@property (nonatomic, strong) NSIndexPath *currentEditingIndexthPath;
@property (nonatomic, copy) NSString *commentToUser;

@property (nonatomic, assign)BOOL isLoading;
@property (nonatomic, assign)BOOL hasNew;
@property (nonatomic, assign)BOOL hasMore;

@property (nonatomic, strong)WFCUFaceBoard *emojInputView;

@property (nonatomic, strong)UIView *inputBar;
@property (nonatomic, strong)UIButton *inputSwitchBtn;

@property (nonatomic, assign)long long selectedCommentId;
@property (nonatomic, assign)BOOL isChangeBackgroudView;
@property (nonatomic, strong)SDTimeLineTableHeaderView *headerView;
@end

@implementation SDTimeLineTableViewController

{
    SDTimeLineRefreshFooter *_refreshFooter;
    SDTimeLineRefreshHeader *_refreshHeader;
    CGFloat _lastScrollViewOffsetY;
    CGFloat _totalKeybordHeight;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    //为self.view 添加背景颜色设置
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.edgesForExtendedLayout = UIRectEdgeTop;
    __weak typeof(self) weakSelf = self;
    
    if (!self.userId) {
        [WFMomentService sharedService].receiveMessageDelegate = self;
    }
    
    // 上拉加载
    _refreshFooter = [SDTimeLineRefreshFooter refreshFooterWithRefreshingText:@"正在加载数据..."];
    __weak typeof(_refreshFooter) weakRefreshFooter = _refreshFooter;
    [_refreshFooter addToScrollView:self.tableView refreshOpration:^{
        weakSelf.isLoading = YES;
        [weakSelf loadModels:NO success:^(NSArray<WFMFeed *> *feeds) {
            if (!feeds.count) {
                weakRefreshFooter.noMoreData = YES;
                weakSelf.hasMore = NO;
            } else {
                for (WFMFeed *feed in feeds) {
                    [weakSelf.dataArray addObject:[self modelOfFeed:feed]];
                }
                [weakSelf.tableView reloadDataWithExistedHeightCache];
            }
            weakSelf.isLoading = NO;
            [weakRefreshFooter endRefreshing];
        } error:^(int error_code) {
            weakSelf.isLoading = NO;
            [weakRefreshFooter endRefreshing];
        }];
        
        /**
         [weakSelf.tableView reloadDataWithExistedHeightCache]
         作用等同于
         [weakSelf.tableView reloadData]
         只是“reloadDataWithExistedHeightCache”刷新tableView但不清空之前已经计算好的高度缓存，用于直接将新数据拼接在旧数据之后的tableView刷新
         */
    }];
    
    _headerView = [[SDTimeLineTableHeaderView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 260)];
    if (self.userId) {
        _headerView.userId = self.userId;
    } else {
        _headerView.userId = [WFCCNetworkService sharedInstance].userId;
    }
    
    self.tableView.tableHeaderView = _headerView;
    _headerView.delegate = self;
    
    //添加分隔线颜色设置
    
    self.tableView.separatorColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5f];
    [self.tableView registerClass:[SDTimeLineCell class] forCellReuseIdentifier:kTimeLineTableViewCellId];
    
    [self setupTextField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    if (!self.userId) {
        self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Camera"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemClick)];
    } else {
        if ([self.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
            self.navigationItem.rightBarButtonItem=[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AlbumComment"] style:UIBarButtonItemStylePlain target:self action:@selector(viewMyComments)];
        }
    }
    
    _refreshHeader = [SDTimeLineRefreshHeader refreshHeaderWithCenter:CGPointMake(40, 45)];
    _refreshHeader.scrollView = self.tableView;
    __weak typeof(_refreshHeader) weakHeader = _refreshHeader;
    
    [_refreshHeader setRefreshingBlock:^{
        weakSelf.isLoading = YES;
        [weakSelf loadModels:YES success:^(NSArray<WFMFeed *> *feeds) {
            [weakSelf.dataArray removeAllObjects];
            for (WFMFeed *feed in feeds) {
                [weakSelf.dataArray addObject:[self modelOfFeed:feed]];
            }
            [weakSelf.tableView reloadData];
            weakSelf.isLoading = NO;
            [weakHeader endRefreshing];
            if (!self.userId) {
                [[WFMomentService sharedService] updateLastReadTimestamp];
            }
        } error:^(int error_code) {
            weakSelf.isLoading = NO;
            [weakHeader endRefreshing];
        }];
        
    }];
    _refreshHeader.hidden = YES;
    
    
    NSMutableArray<WFMFeed *> *feeds = [[WFMomentService sharedService] restoreCache:self.userId];
    if (feeds.count) {
        [self.dataArray removeAllObjects];
        for (WFMFeed *feed in feeds) {
            [self.dataArray addObject:[self modelOfFeed:feed]];
        }
        [self.tableView reloadData];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMenuHidden:) name:UIMenuControllerDidHideMenuNotification object:nil];
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.hasMore = YES;
    [[WFMomentService sharedService] updateLastReadTimestamp];
}

- (void)setHasMore:(BOOL)hasMore {
    if (_hasMore != hasMore) {
        _hasMore = hasMore;
        if (hasMore) {
            self.tableView.tableFooterView = [[UIView alloc] init];
        } else {
            UILabel *foot = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 26)];
            foot.text = @"已经到底了";
            foot.textAlignment = NSTextAlignmentCenter;
            foot.font = [UIFont systemFontOfSize:12];
            foot.textColor = [UIColor grayColor];
            self.tableView.tableFooterView = foot;
        }
    }
}

- (WFCUFaceBoard *)emojInputView {
    if (!_emojInputView) {
        _emojInputView = [[WFCUFaceBoard alloc] init];
        _emojInputView.delegate = self;
        _emojInputView.disableSticker = YES;
    }
    return _emojInputView;
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

- (void)saveCache {
    NSMutableArray<WFMFeed *> *feeds = [[NSMutableArray alloc] init];
    for (SDTimeLineCellModel *model in self.dataArray) {
        [feeds addObject:model.feed];
    }

    [[WFMomentService sharedService] storeCache:feeds forUser:self.userId];
}

- (SDTimeLineCellModel *)modelOfFeed:(WFMFeed *)feed {
    SDTimeLineCellModel *model = [SDTimeLineCellModel new];
    WFCCUserInfo *sender = [[WFCCIMService sharedWFCIMService] getUserInfo:feed.sender refresh:NO];
    model.iconName = sender.portrait;
    model.name = sender.displayName;
    model.msgContent = feed.text;
    model.picNamesArray = feed.medias;
    model.feed = feed;
    return model;
}
- (void)rightBarButtonItemClick {
   
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:@"取消"
                  destructiveButtonTitle:@"拍照"
                       otherButtonTitles:@"相册", @"文字", nil];
    [actionSheet showInView:self.view];
}

- (void)viewMyComments {
    MomentsMessageViewController *vc = [[MomentsMessageViewController alloc] init];
    vc.isNew = NO;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
//        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
//        picker.delegate = self;
//        if ([UIImagePickerController
//             isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
//            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
//        } else {
//            NSLog(@"无法连接相机");
//            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
//        }
//        [self presentViewController:picker animated:YES completion:nil];
        
#if TARGET_IPHONE_SIMULATOR
        [self.view makeToast:@"模拟器不支持相机" duration:1 position:CSToastPositionCenter];
#else
        KZVideoViewController *videoVC = [[KZVideoViewController alloc] init];
        videoVC.delegate = self;
        [videoVC startAnimationWithType:KZVideoViewShowTypeSingle selectExist:NO];
#endif
    } else if (buttonIndex == 1) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.isChangeBackgroudView = NO;
        [self presentViewController:picker animated:YES completion:nil];
    } else if (buttonIndex == 2) {
        CreateFeedViewController *createFeedVC = [[CreateFeedViewController alloc] init];
        createFeedVC.type = WFMContent_Text_Type;
        createFeedVC.onPostFeed = ^(WFMFeed * _Nonnull feed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataArray insertObject:[self modelOfFeed:feed] atIndex:0];
                [self.tableView reloadData];
                [self saveCache];
            });
        };
        [self.navigationController pushViewController:createFeedVC animated:YES];
    }
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_refreshHeader.superview) {
        [self.tableView.superview addSubview:_refreshHeader];
        _refreshHeader.refreshState = SDWXRefreshViewStateWillRefresh;
        _refreshHeader.refreshState = SDWXRefreshViewStateRefreshing;
    } else {
        [self.tableView.superview bringSubviewToFront:_refreshHeader];
    }
    
    [[WFMomentService sharedService] updateLastReadTimestamp];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.userId) {
        [_headerView updateNewMessageStatus];
    }
    
    [[UIApplication sharedApplication].keyWindow addSubview:self.inputBar];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_textField resignFirstResponder];
    
    [self.inputBar removeFromSuperview];
}

- (void)dealloc
{
    [_refreshHeader removeFromSuperview];
    [_refreshFooter removeFromSuperview];
    
    [_textField removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)loadModels:(BOOL)reload success:(void (^)(NSArray<WFMFeed *> *feeds))successBlock error:(void(^)(int error_code))errorBlock {
    NSUInteger fromIndex = 0;
    
    if (!reload && self.dataArray.count) {
        fromIndex = ((SDTimeLineCellModel *)self.dataArray.lastObject).feed.feedUid;
    }
    [[WFMomentService sharedService] getFeeds:fromIndex count:10 fromUser:self.userId success:^(NSArray<WFMFeed *> * _Nonnull feeds) {
        successBlock(feeds);
    } error:^(int error_code) {
        errorBlock(error_code);
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SDTimeLineCell *cell = [tableView dequeueReusableCellWithIdentifier:kTimeLineTableViewCellId];
    cell.indexPath = indexPath;
    __weak typeof(self) weakSelf = self;
    if (!cell.moreButtonClickedBlock) {
        [cell setMoreButtonClickedBlock:^(NSIndexPath *indexPath) {
            SDTimeLineCellModel *model = weakSelf.dataArray[indexPath.row];
            model.isOpening = !model.isOpening;
            [weakSelf.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
        __weak typeof(self) ws = self;
        [cell setDidClickCommentLabelBlock:^(long long commentId, NSString *commentUserId, CGRect rectInWindow, UITableViewCell *cell, UIView *commetView) {
            if ([commentUserId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                [ws displayMenu:commentId inView:commetView];
            } else {
                WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:commentUserId refresh:NO];
                NSIndexPath *indexPath = [ws.tableView indexPathForCell:cell];
                weakSelf.textField.placeholder = [NSString stringWithFormat:@"  回复：%@", userInfo.displayName];
                weakSelf.currentEditingIndexthPath = indexPath;
                [weakSelf.textField becomeFirstResponder];
                weakSelf.isReplayingComment = YES;
                weakSelf.commentToUser = commentUserId;
                [weakSelf adjustTableViewToFitKeyboardWithRect:rectInWindow];
            }
        }];
        
        [cell setPortraitClickedBlock:^(NSIndexPath *indexPath) {
            if (!weakSelf.userId) {
                SDTimeLineCellModel *model = weakSelf.dataArray[indexPath.row];
                SDTimeLineTableViewController *stltvc = [[SDTimeLineTableViewController alloc] init];
                stltvc.userId = model.feed.sender;
                [weakSelf.navigationController pushViewController:stltvc animated:YES];
            }
        }];
        
        cell.delegate = self;
    }
    
    ////// 此步设置用于实现cell的frame缓存，可以让tableview滑动更加流畅 //////
    
    [cell useCellFrameCacheWithIndexPath:indexPath tableView:tableView];
    
    ///////////////////////////////////////////////////////////////////////
    
    cell.model = self.dataArray[indexPath.row];
    return cell;
}


- (void)displayMenu:(long long)commentId inView:(UIView *)commentView {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    UIMenuItem *deleteItem = [[UIMenuItem alloc]initWithTitle:@"删除" action:@selector(performDelete:)];
    UIMenuItem *copyItem = [[UIMenuItem alloc]initWithTitle:@"复制" action:@selector(performCopy:)];
    
    NSMutableArray *items = [[NSMutableArray alloc] init];
    [items addObject:deleteItem];
    [items addObject:copyItem];
    
    
    CGRect menuPos;
        menuPos = commentView.frame;
    
    
    [menu setTargetRect:menuPos inView:commentView.superview];
    
    [menu setMenuItems:items];
    self.selectedCommentId = commentId;
    
    [menu setMenuVisible:YES];
}

-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)onMenuHidden:(id)sender {
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuItems:nil];
    __weak typeof(self)ws = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ws.selectedCommentId = 0;
    });
    
}
-(void)performDelete:(UIMenuController *)sender {
    long long feedId = 0;
    for (SDTimeLineCellModel *model in self.dataArray) {
        for (WFMComment *comment in model.feed.comments) {
            if (comment.commentUid == self.selectedCommentId) {
                feedId = comment.feedUid;
                break;
            }
        }
        if (feedId != 0) {
            break;
        }
    }
    if (!feedId) {
        return;
    }
    __weak typeof(self) ws = self;
    [[WFMomentService sharedService] deleteComments:self.selectedCommentId feedId:feedId success:^{
        for (int i = 0; i < ws.dataArray.count; i++) {
            SDTimeLineCellModel *model = [ws.dataArray objectAtIndex:i];
            if (model.feed.feedUid == feedId) {
                for (WFMComment *comment in model.feed.comments) {
                    if (comment.commentUid == self.selectedCommentId) {
                        [model.feed.comments removeObject:comment];
                        [ws.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
                        return;
                    }
                }
            }
        }
    } error:^(int error_code) {
        
    }];
}

-(void)performCopy:(UIMenuItem *)sender {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    for (SDTimeLineCellModel *model in self.dataArray) {
        for (WFMComment *comment in model.feed.comments) {
            if (comment.commentUid == self.selectedCommentId) {
                pasteboard.string = comment.text;
                break;
            }
        }
    }
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (self.selectedCommentId) {
        if (action == @selector(performDelete:) || action == @selector(performCopy:) || action == @selector(performForward:) || action == @selector(performRecall:) || action == @selector(performComplain:)) {
            return YES; //显示自定义的菜单项
        } else {
            return NO;
        }
    } else {
        return [super canPerformAction:action withSender:sender];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // >>>>>>>>>>>>>>>>>>>>> * cell自适应 * >>>>>>>>>>>>>>>>>>>>>>>>
    id model = self.dataArray[indexPath.row];
    return [self.tableView cellHeightForIndexPath:indexPath model:model keyPath:@"model" cellClass:[SDTimeLineCell class] contentViewWidth:[self cellContentViewWith]];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_textField resignFirstResponder];
    _textField.placeholder = nil;
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!self.isLoading) {
        [_refreshHeader endRefreshing];
    }
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


#pragma mark - SDTimeLineCellDelegate

- (void)didClickCommentButtonInCell:(UITableViewCell *)cell
{
    [_textField becomeFirstResponder];
    _currentEditingIndexthPath = [self.tableView indexPathForCell:cell];
    
    [self adjustTableViewToFitKeyboard];
    
}

- (void)didClickLikeButtonInCell:(UITableViewCell *)cell
{
    _currentEditingIndexthPath = [self.tableView indexPathForCell:cell];
    NSIndexPath *index = [self.tableView indexPathForCell:cell];
    SDTimeLineCellModel *model = self.dataArray[index.row];
    NSMutableArray *temp = [NSMutableArray arrayWithArray:model.likeItemsArray];
    __weak typeof(self)weakSelf = self;
    if (!model.isLiked) {
        __block WFMComment *comment = [[WFMomentService sharedService] postComment:WFMComment_Thumbup_Type feedId:model.feed.feedUid text:nil replyTo:nil extra:nil success:^(long long commentId, long long timestamp) {
            if (!model.feed.comments) {
                model.feed.comments = [[NSMutableArray alloc] init];
            }
            [model.feed.comments insertObject:comment atIndex:0];
            [weakSelf.tableView reloadRowsAtIndexPaths:@[_currentEditingIndexthPath] withRowAnimation:UITableViewRowAnimationFade];
            [weakSelf saveCache];
        } error:^(int error_code) {
            
        }];
        [self.tableView reloadRowsAtIndexPaths:@[_currentEditingIndexthPath] withRowAnimation:UITableViewRowAnimationNone];
        model.liked = YES;
    } else {
        SDTimeLineCellLikeItemModel *tempLikeModel = nil;
        for (SDTimeLineCellLikeItemModel *likeModel in model.likeItemsArray) {
            if ([likeModel.userId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                tempLikeModel = likeModel;
                break;
            }
        }
        
        [temp removeObject:tempLikeModel];
        model.liked = NO;
        [[WFMomentService sharedService] deleteComments:tempLikeModel.comment.commentUid feedId:tempLikeModel.comment.feedUid success:^() {
            for (WFMComment *comment in model.feed.comments) {
                if (comment.commentUid == tempLikeModel.comment.commentUid) {
                    [model.feed.comments removeObject:comment];
                    break;
                }
            }

            [weakSelf.tableView reloadRowsAtIndexPaths:@[_currentEditingIndexthPath] withRowAnimation:UITableViewRowAnimationFade];
            [weakSelf saveCache];
        } error:^(int error_code) {
            
        }];
    }
    model.likeItemsArray = [temp copy];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[index] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)didClickGroupButtonInCell:(UITableViewCell *)cell {
    
}

- (void)didClickDeleteButtonInCell:(UITableViewCell *)cell {
    SDTimeLineCell *timelineCell = (SDTimeLineCell *)cell;
    __weak typeof(self) ws = self;
    [[WFMomentService sharedService] deleteFeed:timelineCell.model.feed.feedUid success:^{
        NSIndexPath *indexPath = [ws.tableView indexPathForCell:cell];
        [ws.dataArray removeObject:timelineCell.model];
        [ws.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationBottom];
    } error:^(int error_code) {
        [ws.view makeToast:@"删除失败!"];
    }];
}

- (void)adjustTableViewToFitKeyboard
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_currentEditingIndexthPath];
    CGRect rect = [cell.superview convertRect:cell.frame toView:window];
    [self adjustTableViewToFitKeyboardWithRect:rect];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __weak typeof(self) weakSelf = self;
    if (textField.text.length) {
        [_textField resignFirstResponder];
        SDTimeLineCellModel *model = self.dataArray[_currentEditingIndexthPath.row];
        __block WFMComment *comment = [[WFMomentService sharedService] postComment:WFMContent_Text_Type feedId:model.feed.feedUid text:textField.text  replyTo:self.isReplayingComment?self.commentToUser:nil extra:nil success:^(long long commentId, long long timestamp) {
            if (!model.feed.comments) {
                model.feed.comments = [[NSMutableArray alloc] init];
            }
            [model.feed.comments insertObject:comment atIndex:0];
            [weakSelf.tableView reloadData];
            [weakSelf saveCache];
        } error:^(int error_code) {
            
        }];

        [self.tableView reloadRowsAtIndexPaths:@[_currentEditingIndexthPath] withRowAnimation:UITableViewRowAnimationNone];
        
        _textField.text = @"";
        _textField.placeholder = nil;
        
        return YES;
    }
    return NO;
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

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [UIApplication sharedApplication].statusBarHidden = NO;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    UIImage *originImage;
    if ([mediaType isEqual:@"public.image"]) {
        originImage = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!originImage) {
            originImage =
            [info objectForKey:UIImagePickerControllerOriginalImage];
        }
    } 
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (!originImage) {
        return;
    }
    
    if (self.isChangeBackgroudView) {
        NSData *portraitData = UIImageJPEGRepresentation(originImage, 0.70);
        __weak typeof(self) ws = self;
        __block MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.label.text = @"上传中...";
        [hud showAnimated:YES];
        
        [[WFCCIMService sharedWFCIMService] uploadMedia:nil mediaData:portraitData mediaType:Media_Type_FAVORITE success:^(NSString *remoteUrl) {
            [[WFMomentService sharedService] updateUserProfile:WFMUpdateUserProfileType_BackgroudUrl strValue:remoteUrl intValue:0 success:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:NO];
                    if (ws.userId) {
                        ws.headerView.userId = ws.userId;
                    } else {
                        ws.headerView.userId = [WFCCNetworkService sharedInstance].userId;
                    }
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:NO];
                hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = @"设置失败";
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
                });
            }];
            
        }
                                               progress:^(long uploaded, long total) {
                                                   
                                               }
                                                  error:^(int error_code) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:NO];
                hud = [MBProgressHUD showHUDAddedTo:ws.view animated:YES];
                hud.mode = MBProgressHUDModeText;
                hud.label.text = @"UploadFailure";
                hud.offset = CGPointMake(0.f, MBProgressMaxOffset);
                [hud hideAnimated:YES afterDelay:1.f];
            });
        }];
    } else {
        CreateFeedViewController *createFeedVC = [[CreateFeedViewController alloc] init];
        createFeedVC.firstImage = originImage;
        createFeedVC.type = WFMContent_Image_Type;
        createFeedVC.onPostFeed = ^(WFMFeed * _Nonnull feed) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.dataArray insertObject:[self modelOfFeed:feed] atIndex:0];
                [self.tableView reloadData];
                [self saveCache];
            });
        };
        [self.navigationController pushViewController:createFeedVC animated:YES];
    }
    
}

- (void)videoViewController:(KZVideoViewController *)videoController didCaptureImage:(UIImage *)image {
    CreateFeedViewController *createFeedVC = [[CreateFeedViewController alloc] init];
    createFeedVC.firstImage = image;
    createFeedVC.type = WFMContent_Image_Type;
    createFeedVC.onPostFeed = ^(WFMFeed * _Nonnull feed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataArray insertObject:[self modelOfFeed:feed] atIndex:0];
            [self.tableView reloadData];
            [self saveCache];
        });
    };
    [self.navigationController pushViewController:createFeedVC animated:YES];
}

- (void)videoViewController:(KZVideoViewController *)videoController didRecordVideo:(KZVideoModel *)videoModel {
    CreateFeedViewController *createFeedVC = [[CreateFeedViewController alloc] init];
    createFeedVC.videoPath = videoModel.videoAbsolutePath;
    createFeedVC.type = WFMContent_Video_Type;
    createFeedVC.videoThumb = [UIImage imageWithContentsOfFile:videoModel.thumAbsolutePath];
    createFeedVC.onPostFeed = ^(WFMFeed * _Nonnull feed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.dataArray insertObject:[self modelOfFeed:feed] atIndex:0];
            [self.tableView reloadData];
            [self saveCache];
        });
    };
    [self.navigationController pushViewController:createFeedVC animated:YES];
}


#pragma mark - SDTimeLineTableHeaderViewDelegate
- (void)onClickedNewMessageBtn {
    MomentsMessageViewController *vc = [[MomentsMessageViewController alloc] init];
    vc.isNew = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onChangeBackground {
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"更换背景图片" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Create cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    [alertController addAction:cancelAction];
    
    UIAlertAction *albumAction = [UIAlertAction actionWithTitle:@"相册" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.allowsEditing = YES;
        self.isChangeBackgroudView = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }];
    [alertController addAction:albumAction];
    
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:@"拍照" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        if ([UIImagePickerController
             isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            NSLog(@"无法连接相机");
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        picker.allowsEditing = YES;
        self.isChangeBackgroudView = YES;
        [self presentViewController:picker animated:YES completion:nil];
    }];
    [alertController addAction:photoAction];
    
    
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - WFMomentReceiveMessageDelegate
- (void)onReceiveNewComment:(WFMCommentMessageContent *)commentContent {
    [_headerView updateNewMessageStatus];
    for (int i = 0; i < self.dataArray.count; i++) {
        SDTimeLineCellModel *model = [self.dataArray objectAtIndex:i];
        if (model.feed.feedUid == commentContent.feedId) {
            BOOL needAdd = YES;
            for (WFMComment *comment in model.feed.comments) {
                if (comment.commentUid == commentContent.commentId) {
                    needAdd = NO;
                    break;
                }
            }
            
            if (needAdd) {
                WFMComment *comment = [[WFMComment alloc] init];
                comment.feedUid = commentContent.feedId;
                comment.commentUid = commentContent.commentId;
                comment.sender = commentContent.sender;
                comment.type = commentContent.type;
                comment.text = commentContent.text;
                comment.replyTo = commentContent.replyTo;
                comment.serverTime = commentContent.serverTime;
                comment.extra = commentContent.extra;
                [model.feed.comments addObject:comment];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:i inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
            }
            break;
        }
    }
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

- (void)onReceiveMentionedFeed:(WFMFeedMessageContent *)feedContent {
    [_headerView updateNewMessageStatus];
}
@end
