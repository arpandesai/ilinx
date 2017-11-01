//
//  NLListDataSource.m
//  iLinX
//
//  Created by mcf on 26/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NLListDataSource.h"


@implementation NLListDataSource

- (id) init
{
  if (self = [super init])
    _listDataDelegates = [NSMutableSet new];
  
  return self;
}

- (void) dealloc
{
  [_listDataDelegates release];
  [super dealloc];
}

- (NSString *) listTitle
{
  return @"";
}

- (NSUInteger) countOfList
{
  return 0;
}

- (BOOL) canBeRefreshed
{
  return NO;
}

- (void) refresh
{
}

- (BOOL) refreshIsComplete
{
  return YES;
}

- (id) itemAtIndex: (NSUInteger) index
{
  return nil;
}

- (NSString *) titleForItemAtIndex: (NSUInteger) index
{
  NSDictionary *item = [self itemAtIndex: index];
  
  return [item objectForKey: @"display"];
}

- (BOOL) itemIsSelectedAtIndex: (NSUInteger) index
{
  return index == _currentIndex;
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index
{
  return [self selectItemAtIndex: index executeAction: YES];
}

- (id<ListDataSource>) selectItemAtIndex: (NSUInteger) index executeAction: (BOOL) executeAction
{
  // No child list, so return nil
  return nil;
}

- (BOOL) itemIsSelectableAtIndex: (NSUInteger) index
{
  return NO;
}

- (id) listDataCurrentItem
{
  return [self itemAtIndex: _currentIndex];
}

- (NSUInteger) listDataCurrentItemIndex
{
  return _currentIndex;
}

- (NSIndexPath *) listDataCurrentItemIndexPath
{
  if ([self countOfList] == NSUIntegerMax)
    return nil;
  else
    return [self indexPathFromIndex: _currentIndex];
}

- (NSUInteger) countOfSections
{
  return 1;
}

- (NSString *) titleForSection: (NSUInteger) section
{
  return @"";
}

- (NSUInteger) sectionForPrefix: (NSString *) prefix
{
  return 0;
}

- (NSUInteger) countOfListInSection: (NSUInteger) section
{
  if (section == 0)
    return [self countOfList];
  else
    return 0;
}

- (NSUInteger) convertFromOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  if (section == 0)
    return index;
  else
    return [self countOfList];
}

- (NSIndexPath *) indexPathFromIndex: (NSUInteger) index
{
  if (index >= [self countOfList])
    return nil;
  else
    return [NSIndexPath indexPathForRow: index inSection: 0];
}

- (id) itemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (NSString *) titleForItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self titleForItemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (BOOL) itemIsSelectedAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemIsSelectedAtIndex: [self convertFromOffset: index inSection: section]];
}

- (id<ListDataSource>) selectItemAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self selectItemAtIndex: [self convertFromOffset: index inSection: section]];
}

- (BOOL) itemIsSelectableAtOffset: (NSUInteger) index inSection: (NSUInteger) section
{
  return [self itemIsSelectableAtIndex: [self convertFromOffset: index inSection: section]];
}

- (void) addDelegate: (id<ListDataDelegate>) delegate
{
  [_listDataDelegates addObject: delegate];
}

- (void) removeDelegate: (id<ListDataDelegate>) delegate
{
  [_listDataDelegates removeObject: delegate];
}

@end
