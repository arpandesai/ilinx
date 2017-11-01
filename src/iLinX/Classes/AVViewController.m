//
//  AVViewController.m
//  iLinX
//
//  Created by mcf on 19/01/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "AVViewController.h"
#import "ChangeSelectionHelper.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLService.h"
#import "NLSource.h"
#import "NLSourceList.h"
#import "OS4ToolbarFix.h"
#import "RootViewController.h"
#import "StandardPalette.h"

#import "BrowseViewController.h"
#ifdef DEBUG
#import "DebugTracing.h"
#define LOG_RETAIN 0
#endif

@implementation AVViewController

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service source: (NLSource *) source
{
  if ((self = [super initWithRoomList: roomList service: service]) != nil)
    _source = [source retain];
  
#if LOG_RETAIN
  NSLog( @"%@ init (%@)\n%@", self, source, [self stackTraceToDepth: 10] );
#endif
  return self;
}

#if LOG_RETAIN
- (id) retain
{
  NSLog( @"%@ retain (%@)\n%@", self, _source, [self stackTraceToDepth: 10] );
  return [super retain];
}

- (void) release
{
  NSLog( @"%@ release (%@)\n%@", self, _source, [self stackTraceToDepth: 10] );
  [super release];
}
#endif

- initWithRoomList: (NLRoomList *) roomList service: (NLService *) service
{
  NLSource *source;
  
  if (roomList.currentRoom.sources == nil)
    source = [NLSource noSourceObject];
  else
    source = roomList.currentRoom.sources.currentSource;

  return [self initWithRoomList: roomList service: service source: source];
}

- (void) addToolbar
{
  // Tool bar
  _toolBar = [[ChangeSelectionHelper
               addToolbarToView: self.view
               withTitle: _roomList.currentRoom.displayName target: self selector: @selector(selectLocation:)
               title:  _roomList.currentRoom.sources.currentSource.displayName target: self
               selector: @selector(selectSource:)] retain];
  
  [_toolBar fixedSetStyle: UIBarStyleBlackOpaque tint: nil];
}

- (BOOL) isBrowseable
{
  return NO;
}

- (id<ControlViewProtocol>) allocBrowseViewController
{
  return nil;
}

- (void) viewWillAppear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [BrowseViewController class]])
  //**/  NSLog( @"AVViewController viewWillAppear: %@ [%08X]", _source.displayName, (NSUInteger) self );
  [super viewWillAppear: animated];
  [_roomList.currentRoom.sources addSourceOnlyDelegate: self];
  [self renderer: _roomList.currentRoom.renderer stateChanged: NLRENDERER_AUDIO_SESSION_CHANGED];
  [_roomList.currentRoom.renderer addDelegate: self];
}

- (void) viewWillDisappear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [BrowseViewController class]])
  //**/  NSLog( @"AVViewController viewWillDisappear: %@ [%08X]", _source.displayName, (NSUInteger) self );
  [_roomList.currentRoom.renderer removeDelegate: self];
  [_roomList.currentRoom.sources removeSourceOnlyDelegate: self];
  [super viewWillDisappear: animated];
}

- (void) viewDidDisappear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [BrowseViewController class]])
  //**/  NSLog( @"AVViewController viewDidDisappear: %@ [%08X]", _source.displayName, (NSUInteger) self );
  [super viewDidDisappear: animated];
}

- (void) viewDidAppear: (BOOL) animated
{
  //**/if (![self isKindOfClass: [BrowseViewController class]])
  //**/  NSLog( @"AVViewController viewDidAppear: %@ [%08X]", _source.displayName, (NSUInteger) self );
  [super viewDidAppear: animated];
  
  // If new source now selected, change view.  If _location is nil, it means
  // that the location has been changed, so no point in checking the source

  NLSource *source;
  
  if (_roomList.currentRoom.sources == nil)
    source = [NLSource noSourceObject];
  else
    source = _roomList.currentRoom.sources.currentSource;
  
  if (_location != nil && _source != source && _isCurrentView)
  {
    [(RootViewController *) [[[self navigationController] viewControllers] objectAtIndex: 0]
     selectService: _service animated: NO];
    [_source release];
    _source = nil;
  }
}

- (void) renderer: (NLRenderer *) renderer stateChanged: (NSUInteger) flags
{
  if ((flags & NLRENDERER_AUDIO_SESSION_CHANGED) != 0)
  {
    if (renderer.audioSessionActive)
    {
      [_toolBar fixedSetTint: [StandardPalette multizoneTintColour]];
      ((UIBarButtonItem *) [_toolBar.items objectAtIndex: 0]).title =
      [[renderer.audioSessionDisplayName stringByReplacingOccurrencesOfString:
        NSLocalizedString( @"MultiRoom", @"Name used for multi-room audio sessions" ) withString: @""]
       stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    else
    {
      if (_toolBar.barStyle == UIBarStyleDefault)
        [_toolBar fixedSetTint: [StandardPalette standardTintColour]];
      else
        [_toolBar fixedSetTint: nil];
      ((UIBarButtonItem *) [_toolBar.items objectAtIndex: 0]).title = _roomList.currentRoom.displayName;
    }
  }
}

- (void) selectLocation: (id) button
{
  UIView *header;
  
  if (!_roomList.currentRoom.renderer.audioSessionActive)
    header = nil;
  else
  {
    UILabel *label = [UILabel new];
    label.text = [NSString stringWithFormat:
                   NSLocalizedString( @"%@ is currently in the %@.",
                                     @"String used to explain that a room is currently part of a multi-room group" ), 
                   _roomList.currentRoom.displayName, _roomList.currentRoom.renderer.audioSessionDisplayName];
    label.font = [UIFont boldSystemFontOfSize: [UIFont smallSystemFontSize]];
    label.textAlignment = UITextAlignmentLeft;
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    label.textColor = [UIColor whiteColor];
    label.backgroundColor = [StandardPalette multizoneTintColour];
    
    CGSize constraintArea = CGSizeMake( [[UIScreen mainScreen] applicationFrame].size.width - 10, 
                                       [[UIScreen mainScreen] applicationFrame].size.height - 10 );
    CGSize actualTextArea = [label.text sizeWithFont: label.font constrainedToSize: constraintArea
                             lineBreakMode: UILineBreakModeWordWrap];
    label.frame = CGRectMake( 5, 5, actualTextArea.width, actualTextArea.height );
    header = [[UIView alloc] initWithFrame: CGRectMake( 0, 0, constraintArea.width + 10, actualTextArea.height + 10 )];
    header.backgroundColor = label.backgroundColor;
    [header addSubview: label];
    [label release];
  }

  [ChangeSelectionHelper showDialogOver: [self navigationController]
                           withListData: _roomList headerView: header];
  [header release];
}

- (void) selectSource: (id) button
{
  [ChangeSelectionHelper showDialogOver: [self navigationController]
                           withListData: _roomList.currentRoom.sources];
}

- (void) currentItemForListData: (id<ListDataSource>) listDataSource
                    changedFrom: (id) old to: (id) new at: (NSUInteger) index
{
  if (listDataSource == _roomList.currentRoom.sources && _source != new && _isCurrentView)
  {
    //**/NSLog( @"AVViewController %@ [%08X] source changed from: %@ to: %@",
    //**/      _source.name, (NSUInteger) self, ((NLSource *) old).name, ((NLSource *) new).name );
    [(RootViewController *) [[[self navigationController] viewControllers] objectAtIndex: 0]
     selectService: _service animated: NO];
  }
}

- (void) dealloc
{
#if LOG_RETAIN
  NSLog( @"%@ dealloc (%@)\n%@", self, _source, [self stackTraceToDepth: 10] );
#endif
  [_source release];
  [super dealloc];
}

@end
