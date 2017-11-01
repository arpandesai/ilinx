//
//  MediaRootMenuViewController.h
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataSourceViewController.h"

@interface MediaRootMenuViewController : DataSourceViewController 
{
@private
  NSString *_initialSelectionKey;
  NSArray *_initialSelection;
  NSArray *_genericInitialSelection;
  BOOL _selectInitialSelection;
}

@end
