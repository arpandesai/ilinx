//
//  NLSourceIROnly.m
//  iLinX
//
//  Created by mcf on 24/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSourceIROnly.h"
#import "NetStreamsComms.h"
#import "NLBrowseListNetStreams.h"

#define _pcomms NETSTREAMSCOMMS_PRODUCTION_ONLY(_comms)

static NSArray *KEY_MAP = nil;

@implementation NLSourceIROnly

@synthesize
  redText = _redText,
  yellowText = _yellowText,
  blueText = _blueText,
  greenText = _greenText;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  if (self = [super initWithSourceData: sourceData comms: comms])
  {
    _sourceDelegates = [NSMutableSet new];
    _redText = [[sourceData objectForKey: @"redText"] retain];
    _yellowText = [[sourceData objectForKey: @"yellowText"] retain];
    _blueText = [[sourceData objectForKey: @"blueText"] retain];
    _greenText = [[sourceData objectForKey: @"greenText"] retain];
    
    if (KEY_MAP == nil)
    {
      KEY_MAP = [[NSArray arrayWithObjects:
        @"",
        @"STOP",
        @"PLAY",
        @"PAUSE",
        @"PLAY_PAUSE",
        @"PREV",
        @"NEXT",
        @"REV",
        @"FWD",
        @"DISC PREV",
        @"DISC NEXT",
        @"REPEAT TOGGLE",
        @"RANDOM",
        @"KEY F1",
        @"KEY F2",
        @"KEY 1",
        @"KEY 2",
        @"KEY 3",
        @"KEY 4",
        @"KEY 5",
        @"KEY 6",
        @"KEY 7",
        @"KEY 8",
        @"KEY 9",
        @"KEY 0",
        @"TEN_PLUS",
        @"HUNDRED_PLUS",
        @"CLEAR",
        @"ENTER",
        @"MENU",
        @"TOPMENU",
        @"NAV UP",
        @"NAV DN",
        @"NAV LT",
        @"NAV RT",
        @"SELECT",
        @"RETURN",
        @"SETUP",
        @"MODE",
        @"DISPLAY",
        @"EJECT",
        @"DVDAUDIO",
        @"ANGLE",
        @"SUBTITLE",
        @"ZOOM",
        @"LANG",
        @"GUIDE",
        @"INFO",
        @"LIST",
        @"GO_BACK",
        @"RECORD",
        @"CHANNEL UP",
        @"CHANNEL DN",
        @"KEY RED",
        @"KEY GREEN",
        @"KEY YELLOW",
        @"KEY BLUE",
        nil] retain];
    }
  }
  
  return self;
}

- (NLBrowseList *) presets
{
  if (_gotFirstPreset)
    return _presets;
  else
    return nil;
}

- (void) setIsCurrentSource: (BOOL) isCurrentSource
{
  if (isCurrentSource && _presets == nil)
  {
    _presets = [[NLBrowseListNetStreams alloc]
                initWithSource: self title: NSLocalizedString( @"Presets", @"Name of DVR presets list" )
                path: @"presets" listCount: NSUIntegerMax addAllSongs: ADD_ALL_SONGS_NO comms: _comms];
    _gotFirstPreset = ([_presets titleForItemAtIndex: 0] != nil);
    if (!_gotFirstPreset)
      [_presets addDelegate: self];
  }
  
  [super setIsCurrentSource: isCurrentSource];
}

- (void) sendKey: (NSUInteger) keyId
{
  if (keyId < [KEY_MAP count])
    [_pcomms send: [KEY_MAP objectAtIndex: keyId] to: self.serviceName];
}

- (void) ifNoFeedbackSetCaption: (NSString *) caption
{
  [_pcomms send: [NSString stringWithFormat: @"SET CAPTION {{%@}}", caption] to: self.serviceName];
}

- (void) addDelegate: (id<NLSourceIROnlyDelegate>) delegate
{
  [_sourceDelegates addObject: delegate];
}

- (void) removeDelegate: (id<NLSourceIROnlyDelegate>) delegate
{
  [_sourceDelegates removeObject: delegate];
}

- (void) itemsChangedInListData: (id<ListDataSource>) listDataSource range: (NSRange) range
{
  NSSet *delegates = [NSSet setWithSet: _sourceDelegates];
  NSEnumerator *enumerator = [delegates objectEnumerator];
  id<NLSourceIROnlyDelegate> delegate;
  
  if ([_presets countOfList] > 0 && !_gotFirstPreset)
  {
    _gotFirstPreset = YES;
    while ((delegate = [enumerator nextObject]))
      [delegate irOnlySource: self changed: SOURCE_IRONLY_PRESETS_CHANGED];
  }
}

- (void) dealloc
{
  [_presets removeDelegate: self];
  [_redText release];
  [_yellowText release];
  [_blueText release];
  [_greenText release];
  [_presets release];
  [_sourceDelegates release];
  [super dealloc];
}

@end
