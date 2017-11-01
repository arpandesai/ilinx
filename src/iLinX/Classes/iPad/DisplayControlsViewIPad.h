//
//  VideoControlsViewIPad.h
//  iLinX
//
//  Created by Tony Short on 27/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NLRenderer.h"

#define BUTTONS_PER_ROW 3

@interface DisplayControlsViewIPad : UIView 
{
  NLRenderer *_renderer;
}

- (void) addNoControlsToView;
- (void) addControlsToViewWithRenderer: (NLRenderer *) renderer;

@end
