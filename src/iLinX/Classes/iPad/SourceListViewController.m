//
//  SourceListViewController.m
//  iLinX
//
//  Created by mcf on 08/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "SourceListViewController.h"
#import "NLRoom.h"
#import "NLRoomList.h"
#import "NLSource.h"
#import "NLSourceList.h"

#define TYPE_NOSOURCE 1
#define TYPE_LOCALSOURCE 2
#define TYPE_LOCALSOURCE_STREAM 3
#define TYPE_TUNER 4
#define TYPE_MEDIASERVER 5
#define TYPE_XM_TUNER 6
#define TYPE_ZTUNER 7
#define TYPE_TRNSPRT 8
#define TYPE_DVD 9
#define TYPE_PVR 10
#define TYPE_VTUNER 11

@interface SourceListViewController ()

- (NSString *) iconNameForItem: (id) item;

@end


@implementation SourceListViewController

static NSDictionary *SOURCE_TYPE_MAP = nil;

- (void) viewDidLoad
{
  [super viewDidLoad];
  _dataSource = [[_delegate.roomList.currentRoom sources] retain];
  if (SOURCE_TYPE_MAP == nil)
  {
    SOURCE_TYPE_MAP = [[NSDictionary dictionaryWithObjectsAndKeys:
                        [NSNumber numberWithInt: TYPE_NOSOURCE], @"NOSOURCE",
                        [NSNumber numberWithInt: TYPE_LOCALSOURCE], @"LOCALSOURCE",
                        [NSNumber numberWithInt: TYPE_LOCALSOURCE_STREAM], @"LOCALSOURCE-STREAM",
                        [NSNumber numberWithInt: TYPE_TUNER], @"TUNER",
                        [NSNumber numberWithInt: TYPE_MEDIASERVER], @"MEDIASERVER",
                        [NSNumber numberWithInt: TYPE_VTUNER], @"VTUNER",
                        [NSNumber numberWithInt: TYPE_XM_TUNER], @"XM TUNER",
                        [NSNumber numberWithInt: TYPE_ZTUNER], @"ZTUNER",
                        [NSNumber numberWithInt: TYPE_TRNSPRT], @"TRNSPRT",
                        [NSNumber numberWithInt: TYPE_DVD], @"DVD",
                        [NSNumber numberWithInt: TYPE_PVR],@"PVR",
                        nil] retain];
  }
}

- (void) resetDataSource
{
  id newSources = [_delegate.roomList.currentRoom sources];
  
  if (newSources != _dataSource)
  {
    [_dataSource release];
    _dataSource = [newSources retain];
    [self.tableView reloadData];
  }
  
  [super resetDataSource];
}

- (UIImage *) iconForItem: (id) item
{
  return [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", [self iconNameForItem: item]]];
}

- (UIImage *) selectedIconForItem: (id) item
{
  return [UIImage imageNamed: [NSString stringWithFormat: @"%@-selected.png", [self iconNameForItem: item]]];
}

- (NSString *) iconNameForItem: (id) item
{
  NSNumber *valueObj = [SOURCE_TYPE_MAP objectForKey: [(NLSource *) item sourceControlType]];
  int value = (valueObj == nil) ? 0 : [valueObj intValue];
  NSString *iconName;
  
  switch (value)
  {
    case TYPE_NOSOURCE:
      iconName = @"HomeAudio";
      break;
    case TYPE_LOCALSOURCE:
    case TYPE_LOCALSOURCE_STREAM:
      if ([[(NLSource *) item displayName] rangeOfString: @"iPod" options: NSCaseInsensitiveSearch].length > 0)
        iconName = @"Devices";
      else
        iconName = @"Songs";
      break;
    case TYPE_TUNER:
    case TYPE_XM_TUNER:
    case TYPE_ZTUNER:
      iconName = @"Channels";
      break;
    case TYPE_MEDIASERVER:
    case TYPE_TRNSPRT:
      iconName = @"Albums";
      break;
    case TYPE_DVD:
      iconName = @"Movies";
      break;
    case TYPE_PVR:
      iconName = @"TV Shows";
      break;
    case TYPE_VTUNER:
      iconName = @"Internet Radio";
      break;
    default:
      iconName = @"Songs";
      break;
  }

  return iconName;
}

@end
