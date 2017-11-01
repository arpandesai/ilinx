//
//  PlaceholderViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 07/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewControllerIPad.h"

@interface PlaceholderViewControllerIPad : ServiceViewControllerIPad
{
@protected
  IBOutlet UILabel *_serviceTitle;
  IBOutlet UIView *_unsupportedMessage;
}

@end
