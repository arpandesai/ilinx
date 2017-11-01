//
//  AudioSettingsViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NLRenderer.h"
#import "ServiceViewControllerIPad.h"
#import "SettingsControlsIPad.h"

@interface AudioSettingsViewControllerIPad : ServiceViewControllerIPad <NLRendererDelegate>
{
@private
  NLRenderer *_renderer;
  SettingsControlsIPad *_settings;
	
  IBOutlet UIView *_settingsControlsView;	
}

@end
