//
//  NLBrowseListNetStreamsRoot.h
//  iLinX
//
//  Created by mcf on 19/02/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLBrowseListNetStreams.h"

@interface NLBrowseListNetStreamsRoot : NLBrowseListNetStreams <NLBrowseListRoot>
{
@private
  NSUInteger _rootType;
  NLBrowseList *_presetsList;
  NSDictionary *_presetsItem;
}

@end
