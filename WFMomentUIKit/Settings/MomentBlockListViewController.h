//
//  MomentBlockListViewController.h
//  WFMomentUIKit
//
//  Created by heavyrain lee on 2019/7/16.
//  Copyright © 2019 Heavyrain Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFMomentClient/WFMomentClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface MomentBlockListViewController : UIViewController
@property(nonatomic, assign)BOOL block;
@property(nonatomic, strong)WFMomentProfiles *profile;
@end

NS_ASSUME_NONNULL_END
