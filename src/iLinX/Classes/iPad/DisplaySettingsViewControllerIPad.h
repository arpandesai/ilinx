//
//  VideoSettingsViewControllerIPad.h
//  iLinX
//
//  Created by Tony Short on 30/09/2010.
//

#import <UIKit/UIKit.h>

#import "NLRenderer.h"
#import "ServiceViewControllerIPad.h"
#import "SettingsControlsIPad.h"
#import "DisplayControlsViewIPad.h"

@interface DisplaySettingsViewControllerIPad : ServiceViewControllerIPad <NLRendererDelegate>
{
@private
  NLRenderer *_renderer;
  SettingsControlsIPad *_settings;
  
  IBOutlet DisplayControlsViewIPad *_displayControlsView;
}

@end
