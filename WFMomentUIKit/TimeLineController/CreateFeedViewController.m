//
//  CreateFeedViewController.m
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/9.
//  Copyright © 2019 WildFireChat. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CreateFeedMediaCollectionViewLayout.h"
#import "MomentMediaCell.h"
#import "CreateFeedViewController.h"
#import "MBProgressHUD.h"
#import <WFMomentClient/WFMomentClient.h>
#import <WFChatUIKit/WFChatUIKit.h>


@interface CreateFeedViewController ()<UITableViewDataSource, UITableViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate>
@property (nonatomic, strong)UICollectionView *memberCollectionView;
@property (nonatomic, strong)CreateFeedMediaCollectionViewLayout *memberCollectionViewLayout;
@property (nonatomic, strong)UITableView *tableView;
@property (nonatomic, strong)NSMutableArray<UIImage *> *imageList;

@property (nonatomic, strong)UITextView *textView;
@end


#define Group_Member_Cell_Reuese_ID @"Group_Member_Cell_Reuese_ID"
#define Feed_Placeholder @"这一刻您的想法..."
@implementation CreateFeedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.imageList = [[NSMutableArray alloc] init];
    if (self.firstImage) {
        [self.imageList addObject:self.firstImage];
    }
    
    self.memberCollectionViewLayout = [[CreateFeedMediaCollectionViewLayout alloc] initWithItemMargin:3];
    int memberCollectionCount = 9;
    if (self.type == WFMContent_Text_Type) {
        memberCollectionCount = 0;
    } else if(self.type == WFMContent_Video_Type || self.type == WFMContent_Link_Type) {
        memberCollectionCount = 1;
    }
    
    self.memberCollectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, [self.memberCollectionViewLayout getHeigthOfItemCount:memberCollectionCount]) collectionViewLayout:self.memberCollectionViewLayout];
    self.memberCollectionView.delegate = self;
    self.memberCollectionView.dataSource = self;
    
    self.memberCollectionView.backgroundColor = [WFCUConfigManager globalManager].backgroudColor;
    
    [self.memberCollectionView registerClass:[MomentMediaCell class] forCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID];
    
    self.tableView.tableHeaderView = self.memberCollectionView;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.tableView];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送" style:UIBarButtonItemStyleDone target:self action:@selector(onRightBtn:)];
}

- (void)onRightBtn:(id)sender {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeAnnularDeterminate;
    hud.label.text = @"发布中...";
    [self.textView resignFirstResponder];
    NSCondition *condition = [[NSCondition alloc] init];
    
    NSString *text = self.textView.text;
    if ([text isEqualToString:Feed_Placeholder]) {
        text = nil;
    }
    __block BOOL success = NO;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<WFMFeedEntry *> *entryUrls = [[NSMutableArray alloc] init];
        if (self.type == WFMContent_Image_Type) {
            for (int i = 0; i < self.imageList.count; i++) {
                WFMFeedEntry *entry = [[WFMFeedEntry alloc] init];
                entry.mediaWidth = self.imageList[i].size.width;
                entry.mediaHeight = self.imageList[i].size.height;
                
                success = [[WFCCIMService sharedWFCIMService] syncUploadMedia:nil mediaData:UIImageJPEGRepresentation(self.imageList[i], 0.8) mediaType:Media_Type_MOMENTS success:^(NSString *remoteUrl) {
                    entry.mediaUrl = remoteUrl;
                } progress:^(long uploaded, long total) {
                    hud.progress = uploaded * 1.f / (total * self.imageList.count) + i * 1.f/self.imageList.count;
                } error:^(int error_code) {
                    
                }];
                
                if (!success) {
                    break;
                }
                
                UIImage *thumbnail = [WFCCUtilities generateThumbnail:self.imageList[i] withWidth:120 withHeight:120];
                success = [[WFCCIMService sharedWFCIMService] syncUploadMedia:nil mediaData:UIImageJPEGRepresentation(thumbnail, 0.5) mediaType:Media_Type_MOMENTS success:^(NSString *remoteUrl) {
                    entry.thumbUrl = remoteUrl;
                } progress:^(long uploaded, long total) {
                    
                } error:^(int error_code) {
                    
                }];
                
                [entryUrls addObject:entry];
            }
        } else if (self.type == WFMContent_Video_Type) {
            WFMFeedEntry *entry = [[WFMFeedEntry alloc] init];
            entry.mediaWidth = self.videoThumb.size.width;
            entry.mediaHeight = self.videoThumb.size.height;
            
            [entryUrls addObject:entry];
            
            success = [[WFCCIMService sharedWFCIMService] syncUploadMedia:nil mediaData:UIImageJPEGRepresentation(self.videoThumb, 0.8) mediaType:Media_Type_MOMENTS success:^(NSString *remoteUrl) {
                entry.thumbUrl = remoteUrl;
            } progress:^(long uploaded, long total) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    hud.progress = 0.1;
                });
            } error:^(int error_code) {
                
            }];
            
            if (success) {
                NSData *videoData = [NSData dataWithContentsOfFile:self.videoPath];
                success = [[WFCCIMService sharedWFCIMService] syncUploadMedia:nil mediaData:videoData mediaType:Media_Type_MOMENTS success:^(NSString *remoteUrl) {
                    entry.mediaUrl = remoteUrl;
                } progress:^(long uploaded, long total) {
                    hud.progress = uploaded * 0.9f / videoData.length + 0.1f;
                } error:^(int error_code) {
                    
                }];
            }
        } else if(self.type == WFMContent_Text_Type) {
            success = YES;
        }
        if (!success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [hud hideAnimated:YES];
            });
        } else {
            __block WFMFeed *feed = [[WFMomentService sharedService] postFeeds:self.type text:text medias:entryUrls toUsers:nil excludeUsers:nil mentionedUsers:nil extra:nil success:^(long long feedId, long long timestamp) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                    self.onPostFeed(feed);
                    [self.navigationController popViewControllerAnimated:YES];
                });
            } error:^(int error_code) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [hud hideAnimated:YES];
                });
            }];
        }
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)addMoreMedia {
    UIActionSheet *actionSheet =
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self
                       cancelButtonTitle:@"取消"
                  destructiveButtonTitle:@"拍照"
                       otherButtonTitles:@"相册", nil];
    [actionSheet showInView:self.view];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.memberCollectionView reloadData];
    [self.tableView reloadData];
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 120)];
        _textView.text=Feed_Placeholder;
        _textView.textColor= [UIColor lightGrayColor];
        _textView.delegate = self;
        _textView.font = [UIFont systemFontOfSize:16];
    }
    return _textView;
}
- (void)textViewDidBeginEditing:(UITextView*)textView {
    if([textView.text isEqualToString:Feed_Placeholder]) {
        textView.text=@"";
        textView.textColor= [UIColor blackColor];
    }
}
- (void)textViewDidEndEditing:(UITextView*)textView {
    if(textView.text.length<1) {
        textView.text=Feed_Placeholder;
        textView.textColor= [UIColor lightGrayColor];
    }
}


#pragma mark -  UIActionSheetDelegate <NSObject>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        if ([UIImagePickerController
             isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        } else {
            NSLog(@"无法连接相机");
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        [self presentViewController:picker animated:YES completion:nil];
        
    } else if (buttonIndex == 1) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    }
}


#pragma mark - UITableViewDataSource<NSObject>


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return 120;
    }
    return 48;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath  {
    if (indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textCell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"textCell"];
            for (UIView *subView in cell.subviews) {
                [subView removeFromSuperview];
            }
            if (@available(iOS 14, *)) {
                [cell.contentView addSubview:self.textView];
            } else {
                [cell addSubview:self.textView];
            }
        }
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"style1Cell"];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"style1Cell"];
        }
        if (indexPath.row == 1) {
            cell.textLabel.text = @"位置";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == 2) {
            cell.textLabel.text = @"可见范围";
            cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
        } else if (indexPath.row == 3) {
            cell.textLabel.text = @"提醒谁看";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        
        return cell;
    }
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.type == WFMContent_Video_Type) {
        return 1;
    }
    
    if (self.type == WFMContent_Text_Type) {
        return 0;
    }
    int memberCollectionCount = (int)self.imageList.count + 1;
    if (memberCollectionCount == 10) {
        memberCollectionCount = 9;
    }
    return memberCollectionCount;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MomentMediaCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:Group_Member_Cell_Reuese_ID forIndexPath:indexPath];
    if (self.type == WFMContent_Image_Type) {
        if (indexPath.row < self.imageList.count) {
            UIImage *image = self.imageList[indexPath.row];
            cell.headerImageView.image = image;
        } else {
            if (indexPath.row == self.imageList.count) {
                [cell.headerImageView setImage:[UIImage imageNamed:@"addmember"]];
            } else {
                [cell.headerImageView setImage:[UIImage imageNamed:@"removemember"]];
            }
        }
    } else if(self.type == WFMContent_Video_Type) {
        cell.headerImageView.image = self.videoThumb;
    }
    return cell;
}

#pragma mark - UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.imageList.count) {
        [self addMoreMedia];
    } else {
        //todo view image
    }
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [UIApplication sharedApplication].statusBarHidden = NO;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    UIImage *originImage;
    if ([mediaType isEqual:@"public.image"]) {
        originImage =
        [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (originImage) {
        [self.imageList addObject:originImage];
        [self.memberCollectionView reloadData];
    }
}


@end

