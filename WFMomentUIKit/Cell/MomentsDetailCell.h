//
//  MomentsDetailCell.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/23.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFMomentClient/WFMomentClient.h>
#define MomentsDetailCellHeight 48

NS_ASSUME_NONNULL_BEGIN

@interface MomentsDetailCell : UITableViewCell
@property(nonatomic, strong)WFMComment *comment;
@end

NS_ASSUME_NONNULL_END
