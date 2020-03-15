//
//  FeedDetailViewController.h
//  WFMomentUIKit
//
//  Created by Heavyrain Lee on 2020/3/14.
//  Copyright © 2020 Heavyrain Lee. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFMomentClient/WFMomentClient.h>
NS_ASSUME_NONNULL_BEGIN

@interface FeedDetailViewController : UIViewController
@property(nonatomic, strong)WFCCMessage *message;
@end

NS_ASSUME_NONNULL_END
