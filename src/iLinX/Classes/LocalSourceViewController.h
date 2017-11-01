//
//  LocalSourceViewController.h
//  iLinX
//
//  Created by mcf on 17/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVViewController.h"
#import "NLSourceLocal.h"

@interface LocalSourceViewController : AVViewController <NLSourceLocalDelegate>
{
@private
  NLSourceLocal *_localSource;
  NSMutableArray *_presetButtons;
  id _changeHandler;
}

@end
