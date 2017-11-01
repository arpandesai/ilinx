//
//  NLSourceLocal.m
//  iLinX
//
//  Created by mcf on 25/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLSourceLocal.h"
#import "NLBrowseListNetStreams.h"

// How often, in seconds, to send the report registration request to ensure
// that it does not expire
#define REGISTRATION_RENEWAL_INTERVAL 30

@interface NLSourceLocal ()

- (void) registerForNetStreams;
- (void) deregisterFromNetStreams;

@end

@implementation NLSourceLocal

@synthesize
  currentPreset = _currentPreset;

- (id) initWithSourceData: (NSDictionary *) sourceData comms: (NetStreamsComms *) comms
{
  if ((self = [super initWithSourceData: sourceData comms: comms]) != nil)
  {
    _sourceDelegates = [NSMutableSet new];
    _presets = [[NLBrowseListNetStreams alloc] initWithSource: self title: @"Presets" path: @"presets"
                                          listCount: NSUIntegerMax addAllSongs: ADD_ALL_SONGS_NO comms: comms];
  }

  return self;
}

- (BOOL) isNaimAmp
{
  return [[self controlType] isEqualToString: @"MUX"];
}

- (id<ListDataSource>) presets
{
  return _presets;
}

- (void) addDelegate: (id<NLSourceLocalDelegate>) delegate
{
  [_sourceDelegates addObject: delegate];
}

- (void) removeDelegate: (id<NLSourceLocalDelegate>) delegate
{
  [_sourceDelegates removeObject: delegate];
}

- (void) setIsCurrentSource: (BOOL) isCurrentSource
{
  if (isCurrentSource)
  {
    if (!_isCurrentSource)
      [self registerForNetStreams];
  }
  else
  {
    if (_isCurrentSource)
      [self deregisterFromNetStreams];
  }
  
  [super setIsCurrentSource: isCurrentSource];
}

- (void) registerForNetStreams
{
  //NSLog( @"Register" );
  _statusRspHandle = [_comms registerDelegate: self forMessage: @"REPORT" from: self.serviceName];
  _registerMsgHandle = [_comms send: [NSString stringWithFormat: @"REGISTER ON,{{%@}}", self.serviceName]
                                 to: nil every: REGISTRATION_RENEWAL_INTERVAL];
}

- (void) deregisterFromNetStreams
{
  //NSLog( @"Deregister" );
  if (_statusRspHandle != nil)
  {
    [_comms deregisterDelegate: _statusRspHandle];
    _statusRspHandle = nil;
  }
  //NSLog( @"Cancel send every" );
  if (_registerMsgHandle != nil)
  {
    [_comms cancelSendEvery: _registerMsgHandle];
    [_comms send: [NSString stringWithFormat: @"REGISTER OFF,{{%@}}", self.serviceName] to: nil];
    _registerMsgHandle = nil;
  }
}

- (void) received: (NetStreamsComms *) comms messageType: (NSString *) messageType 
             from: (NSString *) source to: (NSString *) destination data: (NSDictionary *) data
{
  if ([[data objectForKey: @"type"] isEqualToString: @"source"])
  {
    NSString *mux = [data objectForKey: @"mux"];
    
    if (mux != nil)
    {
      NSString *selectCommand = [NSString stringWithFormat: @"#MENU_SEL media>%@", mux];
      NSUInteger count = [_presets countOfList];
      NSUInteger i;
      
      if (count != NSUIntegerMax && count != 0)
      {
        for (i = 0; i < count; ++i)
        {
          NSDictionary *item = [_presets itemAtIndex: i];
          NSString *presetCommand = [item objectForKey: @"command"];
        
          if (presetCommand != nil && 
              [presetCommand compare: selectCommand options: NSCaseInsensitiveSearch] == NSOrderedSame)
            break;
        }
        
        if (i != _currentPreset)
        {
          NSSet *delegates = [NSSet setWithSet: _sourceDelegates];
          NSEnumerator *enumerator = [delegates objectEnumerator];
          id<NLSourceLocalDelegate> delegate;
          
          if (i >= count)
          {
            // NNPs can power up with an invalid (disabled) input selected.  In this case its mux id
            // won't match up with any of the availble presets.  Detect this and select the first
            // available preset if it happens.
            NSString *presetCommand = [[_presets itemAtIndex: 0] objectForKey: @"command"];
            
            if ([presetCommand hasPrefix: @"#"])
              presetCommand = [presetCommand substringFromIndex: 1];
            [_comms send: presetCommand to: self.serviceName];
            i = 0;
          }

          _currentPreset = i;
          while ((delegate = [enumerator nextObject]))
            [delegate source: self stateChanged: SOURCE_LOCAL_PRESET_CHANGED];
        }
      }
    }
  }
}

- (void) dealloc
{
  [self deregisterFromNetStreams];
  [_sourceDelegates release];
  [_presets release];
  [super dealloc];
}

@end
