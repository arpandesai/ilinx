//
//  MultiRoomViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NLRenderer.h"
#import "ServiceViewControllerIPad.h"
#import "MultiRoomViewIPad.h"

@interface MultiRoomViewControllerIPad : ServiceViewControllerIPad <NLRendererDelegate>
{
@private
  NLRenderer *_renderer;
  IBOutlet MultiRoomViewIPad *_multiRoomView;
  BOOL _inMultiRoom;
  BOOL _choosingZone;	
}

@end
