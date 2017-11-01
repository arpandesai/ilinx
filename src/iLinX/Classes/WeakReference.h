//
//  WeakReference.h
//  iLinX
//
//  Created by mcf on 18/02/2011.
//  Copyright 2011 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface WeakReference : NSObject <NSCopying>
{
@private
  NSNumber *_ref;
}

+ (WeakReference *) weakReferenceForObject: (id) object;
- (id) initWithObject: (id) object;
- (id) referencedObject;

@end
