//
//  NoItemsView.h
//  iLinX
//
//  Created by mcf on 19/05/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NoItemsView : UIView
{
  UIImageView *_itemTypeImage;
  UILabel *_noItemsMessage;
}

- (id) initWithItemType: (NSString *) itemType isLoading: (BOOL) isLoading pendingMessage: (NSString *) pendingMessage;

@end
