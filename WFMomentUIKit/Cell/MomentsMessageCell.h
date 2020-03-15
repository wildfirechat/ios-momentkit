//
//  MomentsMessageCell.h
//  WildFireChat
//
//  Created by heavyrain.lee on 2019/6/23.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WFChatClient/WFCChatClient.h>

#define MomentsMessageCellHeight 80

NS_ASSUME_NONNULL_BEGIN

@interface MomentsMessageCell : UITableViewCell
@property(nonatomic, strong)WFCCMessage *object;
@end

NS_ASSUME_NONNULL_END
