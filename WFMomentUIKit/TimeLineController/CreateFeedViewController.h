//
//  CreateFeedViewController.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/9.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class WFMFeed;
@interface CreateFeedViewController : UIViewController
@property(nonatomic, assign)/*WFMContentType*/int type;

@property(nonatomic, strong)UIImage *firstImage;

@property(nonatomic, strong)NSString *videoPath;
@property(nonatomic, strong)UIImage *videoThumb;
@property(nonatomic, strong)void (^onPostFeed)(WFMFeed *feed);
@end

NS_ASSUME_NONNULL_END
