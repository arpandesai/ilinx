//
//  AudioViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 08/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataSourceViewController.h"
#import "ListDataSource.h"
#import "ServiceViewControllerIPad.h"

@class AudioSubViewControllerIPad;
@class NLSourceList;

@interface AudioViewControllerIPad : ServiceViewControllerIPad <ListDataDelegate,
                                      DataSourceViewControllerDelegate, UIPopoverControllerDelegate>
{
@private
  UIPopoverController *_sourcesPopover;
  AudioSubViewControllerIPad *_sourceViewController;
  id _popoverControl;
  UIPopoverArrowDirection _arrowDirections;
  NLSourceList *_sources;
}

- (void) presentSourcesPopoverFromButton: (id) popoverButton 
                permittedArrowDirections: (UIPopoverArrowDirection) arrowDirections
                                animated: (BOOL) animated;
- (void) dismissSourcesPopoverAnimated: (BOOL) animated;

@end
