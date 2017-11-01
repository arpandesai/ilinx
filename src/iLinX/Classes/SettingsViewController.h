//
//  SettingsViewController.h
//  iLinX
//
//  Created by mcf on 26/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NLRenderer.h"
#import "TintedTableViewController.h"

@class CustomViewController;
@class SettingsControls;

@interface SettingsViewController : TintedTableViewController <NLRendererDelegate>
{
@private
  SettingsControls *_settings;
  NLRenderer *_renderer;
  CustomViewController *_customPage;
  BOOL _inMultiRoom;
  UIBarStyle _style;
  NSTimer *_volTimer;
  BOOL _choosingZone;
}

- (id) initWithTitle: (NSString *) title renderer: (NLRenderer *) renderer barStyle: (UIBarStyle) style
          doneTarget: (id) target doneSelector: (SEL) selector;

@end
