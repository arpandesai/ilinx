//
//  UncodableObjectArchiver.h
//  iLinX
//
//  Created by mcf on 16/06/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UncodableObjectArchiver : NSKeyedArchiver
{
@private
  NSMutableDictionary *_dictionary;
}

@property (readonly) NSDictionary *dictionary;

+ (NSDictionary *) dictionaryEncodingWithRootObject: (id) rootObject;

@end

@interface UncodableObjectUnarchiver: NSKeyedUnarchiver
{
@private
  NSDictionary *_dictionary;
}

+ (id) unarchiveObjectWithDictionary: (NSDictionary *) dictionary;

@end
