//
//  AVViewController.h
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ServiceViewController.h"
#import "AVControlViewProtocol.h"
#import "ListDataSource.h"
#import "NLRenderer.h"

@interface AVViewController : ServiceViewController <AVControlViewProtocol, ListDataDelegate, NLRendererDelegate>
{
@protected
  NLSource *_source;
}

- (void) selectSource: (id) button;

@end
