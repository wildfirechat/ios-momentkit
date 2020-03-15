//
//  ConversationSettingMemberCell.h
//  WFChat UIKit
//
//  Created by WF Chat on 2017/11/3.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MemberCell : UICollectionViewCell
@property(nonatomic, strong) UIImageView *headerImageView;
@property(nonatomic, strong) UILabel *nameLabel;
@property(nonatomic, strong) NSString *userId;
@property(nonatomic, assign) BOOL deleteMode;
@end
