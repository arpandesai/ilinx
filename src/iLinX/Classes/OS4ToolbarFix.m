//
//  OS4ToolbarFix.m
//  iLinX
//
//  Created by mcf on 18/10/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "OS4ToolbarFix.h"


@implementation UIToolbar (OS4ToolbarFix)

- (void) fixedRefreshButtons
{
  // OS4 has screwed things up so that the buttons don't pick up the new style and tint
  // Workaround is to cause the buttons to refresh by changing their styles
  for (UIBarButtonItem *b in self.items)
  {
    UIBarButtonItemStyle style = b.style;
    
    b.style = UIBarButtonSystemItemFastForward;
    b.style = style;
  }
}

- (void) fixedSetStyle: (UIBarStyle) style
{
  self.barStyle = style;
  [self fixedRefreshButtons];
}

- (void) fixedSetTint: (UIColor *) tint
{
  self.tintColor = tint;
  [self fixedRefreshButtons];
}

- (void) fixedSetStyle: (UIBarStyle) style tint: (UIColor *) tint
{
  self.barStyle = style;
  self.tintColor = tint;
  [self fixedRefreshButtons];
}

@end
