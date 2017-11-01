//
//  LocalSourceViewController.m
//  iLinX
//
//  Created by mcf on 17/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "LocalSourceViewControllerIPad.h"
#import "AudioViewControllerIPad.h"
#import "DeprecationHelper.h"
#import "ListDataSource.h"
#import "MainNavigationController.h"
#import "XIBViewController.h"

#define BUTTON_NUMBER_MASK 0x07

@interface LocalSourceViewControllerIPad ()

- (void) configurePresets;

@end

@interface ChangeHandlerIpad : NSObject <ListDataDelegate>
{
@private
  LocalSourceViewControllerIPad *_controller;
}
  
- (id)   initWithController: (LocalSourceViewControllerIPad *) controller;
- (void) registerWithList:   (id<ListDataSource>) list;
- (void) deregisterFromList: (id<ListDataSource>) list;

@end


@implementation ChangeHandlerIpad

- (id) initWithController: (LocalSourceViewControllerIPad *) controller
{
  if (self = [super init])
    _controller = controller;
  
  return self;
} 

- (void) registerWithList: (id<ListDataSource>) list
{
  [list addDelegate: self];
}

- (void) deregisterFromList: (id<ListDataSource>) list
{
  [list removeDelegate: self];
}

- (void) itemsInsertedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) itemsRemovedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  [_controller configurePresets];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  [_controller configurePresets];
}

@end


@implementation LocalSourceViewControllerIPad

- (id) initWithOwner: (AudioViewControllerIPad *) owner service: (NLService *) service source: (NLSource *) source;
{

  if ((self = [super initWithOwner: owner service: service source: source
		      nibName: @"LocalSourceViewIPad" bundle: nil]) != nil)
  {
    //Cast here as a convenience to avoid having to cast every time its used
    _localSource = (NLSourceLocal *) source;
    _changeHandler = [[ChangeHandlerIpad alloc] initWithController: self];
  }

  return self;
}

- (void) viewDidLoad 
{
  [super viewDidLoad];
  _presetButtons = [[NSArray arrayWithObjects: 
		     [NSArray arrayWithObjects: _button1Off, _button1On, nil],
		     [NSArray arrayWithObjects: _button2Off, _button2On, nil],
		     [NSArray arrayWithObjects: _button3Off, _button3On, nil],
		     [NSArray arrayWithObjects: _button4Off, _button4On, nil],
		     [NSArray arrayWithObjects: _button5Off, _button5On, nil],
		     [NSArray arrayWithObjects: _button6Off, _button6On, nil], 
		     nil] retain];
  _sourceTitle.text = _localSource.displayName;
}

- (void) viewDidUnload 
{
  [_presetButtons release];
  _presetButtons = nil;
  [super viewDidUnload];
}

- (void) viewDidAppear: (BOOL) animated
{
  [super viewDidAppear: animated];

  [self configurePresets];
  [_changeHandler registerWithList: _localSource.presets];
  [_localSource addDelegate: self];
  if (_localSource.isNaimAmp)
  {
    _viewBackGroundNaim.hidden = NO;  
    _viewBackGroundLocal.hidden = YES;
  }
  else 
  {
    _viewBackGroundLocal.hidden = NO;
    _viewBackGroundNaim.hidden = YES;
  }
}

- (void) viewDidDisappear: (BOOL) animated
{
  [_localSource removeDelegate: self];
  [_changeHandler deregisterFromList: _localSource.presets];
  [super viewDidDisappear: animated];
}

- (void) source: (NLSourceLocal *) source stateChanged: (NSUInteger) flags
{
  [self configurePresets];
}

- (void) configurePresets
{
  NSUInteger count = [_localSource.presets countOfList];
  NSUInteger currentItem = _localSource.currentPreset;
  
  if (count < NSUIntegerMax)
  {
    if (count > [_presetButtons count])
      count = [_presetButtons count];
    
    for (NSUInteger i = 0; i < count; ++i)
    {
      NSArray *buttons = [_presetButtons objectAtIndex: i];
      
      for (NSUInteger j = 0; j < 2; ++j)
      {
	UIButton *button = [buttons objectAtIndex: j];

      	[button setTitle: [_localSource.presets titleForItemAtIndex: i] forState: UIControlStateNormal];
        button.hidden = ((j == 0 && i == currentItem) || (j == 1 && i != currentItem));
      }      
    }
  }
}

- (IBAction) buttonPushed: (UIButton *) button
{
  [_localSource.presets selectItemAtIndex: button.tag & BUTTON_NUMBER_MASK];
}


- (void) dealloc
{
  [_viewBackGroundNaim release];
  [_viewBackGroundLocal release];
  [_button1Off release];
  [_button1On release];
  [_button2Off release];
  [_button2On release];
  [_button3Off release];
  [_button3On release];
  [_button4Off release];
  [_button4On release];
  [_button5Off release];
  [_button5On release];
  [_button6Off release];
  [_button6On release];
  [_sourceTitle release];
  [_presetButtons release];
  [_changeHandler release];
  [super dealloc];
}

@end