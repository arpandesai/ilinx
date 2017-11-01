//
//  Icons.m
//  iLinX
//
//  Created by mcf on 22/05/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "Icons.h"


@implementation Icons

+ (NSString *) alternativeNameForName: (NSString *) name
{
  if ([name isEqualToString: @"generic-serial"])
    name = @"generic-ir";
  else if ([name isEqualToString: @"hvac2"])
    name = @"hvac";
  else if ([name isEqualToString: @"security2"])
    name = @"security";
  else if ([name isEqualToString: @"CD Collection"])
    name = @"Servers";
  else if ([name isEqualToString: @"Network Music"])
    name = @"Shares";
  else if ([name isEqualToString: @"USB Music"])
    name = @"Devices";
  else if ([name isEqualToString: @"Books"])
    name = @"Audiobooks";
  else if ([name isEqualToString: @"Audio Book"])
    name = @"Audiobooks";
  else if ([name isEqualToString: @"iTunes\u00a0U"])
    name = @"iTunes U";
  else if ([name isEqualToString: @"Media"])
    name = @"Albums";
  else if ([name hasPrefix: @"All "])
    name = [name substringFromIndex: 4];
  
  return name;
}

+ (UIImage *) browseIconForItemName: (NSString *) itemName
{
  NSString *title = [self alternativeNameForName: itemName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", title]];
  
  if (image == nil)
  {
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s.png", title]];

    if (image == nil)
    {
      image = [UIImage imageNamed: @"Unknown.png"];
      //NSLog( [NSString stringWithFormat: @"\"%@\" -> Unknown.png", itemName] );
    }
    else
    {
      //NSLog( [NSString stringWithFormat: @"\"%@\" -> %@s.png", itemName, title] );
    }
  }
  else
  {
    //NSLog( [NSString stringWithFormat: @"\"%@\" -> %@.png", itemName, title] );
  }

  return image;  
}

+ (UIImage *) selectedBrowseIconForItemName: (NSString *) itemName
{
  NSString *title = [self alternativeNameForName: itemName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"%@-selected.png", title]];
  
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s-selected.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: @"Unknown-selected.png"];
  
  return image;
}

+ (UIImage *) tabBarBrowseIconForItemName: (NSString *) itemName
{
  NSString *title = [self alternativeNameForName: itemName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"%@-tabbar.png", title]];
  
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s-tabbar.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: @"Unknown-tabbar.png"];

  return image;
}

+ (UIImage *) largeBrowseIconForItemName: (NSString *) itemName
{
  NSString *title = [self alternativeNameForName: itemName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"%@-large.png", title]];
  
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s-large.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"%@s.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: @"Unknown-large.png"];
  
  return image;
}

+ (UIImage *) homeIconForServiceName: (NSString *) serviceName
{
  NSString *title = [self alternativeNameForName: serviceName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@.png", title]];
  
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@s.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: @"Unknown.png"];
  
  return image;  
}

+ (UIImage *) selectedHomeIconForServiceName: (NSString *) serviceName
{
  NSString *title = [self alternativeNameForName: serviceName];
  UIImage *image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@-selected.png", title]];
  
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@s-selected.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: [NSString stringWithFormat: @"Home%@s.png", title]];
  if (image == nil)
    image = [UIImage imageNamed: @"Unknown-selected.png"];
  
  return image;
}

@end
