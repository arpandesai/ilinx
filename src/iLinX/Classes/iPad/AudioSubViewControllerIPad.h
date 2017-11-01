//
//  AudioSubViewControllerIPad.h
//  iLinX
//
//  Created by mcf on 09/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AudioViewControllerIPad;
@class NLRoomList;
@class NLService;
@class NLSource;
@class PseudoBarButton;

@protocol AudioSubViewControllerIPad <NSObject>

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source;
- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source
             nibName: (NSString *) nibName bundle: (NSBundle *) bundle;
- (NLService *) service;
- (NLSource *) source;

@end

@interface AudioSubViewControllerIPad : UIViewController <AudioSubViewControllerIPad>
{
@protected
  IBOutlet PseudoBarButton *_sourcesButton;

  AudioViewControllerIPad *_owner;
  NLService *_service;
  NLSource *_source;
}

- (IBAction) sourcesPressed: (UIControl *) button;

@end
