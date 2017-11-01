//
//  NoItemsView.m
//  iLinX
//
//  Created by mcf on 19/05/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "NoItemsView.h"
#import "Icons.h"
#import "StandardPalette.h"

@implementation NoItemsView


- (id) initWithItemType: (NSString *) itemType isLoading: (BOOL) isLoading pendingMessage: (NSString *) pendingMessage
{
  if (self = [super initWithFrame: CGRectMake( 0, 0, 320, 325 )])
  {
    NSString *numberPrefix;

    if (itemType == nil)
      itemType = @"Unknown";
    if (isLoading)
      numberPrefix = @"1003";
    else
      numberPrefix = @"1002";

    if ([itemType hasPrefix: @"All "])
      itemType = [itemType substringFromIndex: 4];

    NSString *resourceName = [NSString stringWithFormat: @"%@%@", numberPrefix, itemType];
    NSString *localisedMessage = pendingMessage;
    UIImage *itemImage = [Icons largeBrowseIconForItemName: itemType];

    if (localisedMessage == nil)
      localisedMessage = NSLocalizedString( resourceName, @"Message indicating that there are no items of a given type" );
    if (localisedMessage == nil || [localisedMessage isEqualToString: resourceName])
    {
      if (isLoading)
        localisedMessage = NSLocalizedString( @"1003Unknown", @"Message indicating that items are loading where the item type is unknown" );
      else
        localisedMessage = NSLocalizedString( @"1002Unknown", @"Message indicating that there are no items where the item type is unknown" );
    }

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    self.autoresizesSubviews = YES;
    
    _itemTypeImage = [[UIImageView alloc] initWithFrame: CGRectMake( 40, 20, 240, 240 )];
    _itemTypeImage.image = itemImage;
    _itemTypeImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|
    UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview: _itemTypeImage];
    
    _noItemsMessage = [[UILabel alloc] initWithFrame: CGRectMake( 0, 242, 320, 80 )];
    _noItemsMessage.text = localisedMessage;
    _noItemsMessage.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
    _noItemsMessage.textAlignment = UITextAlignmentCenter;
    _noItemsMessage.textColor = [StandardPalette noItemTitleColour];
    _noItemsMessage.backgroundColor = [UIColor clearColor];
    _noItemsMessage.lineBreakMode = UILineBreakModeWordWrap;
    _noItemsMessage.numberOfLines = 0;
    [_noItemsMessage sizeToFit];
    _noItemsMessage.frame = CGRectOffset( _noItemsMessage.frame, (NSUInteger) ((320 - _noItemsMessage.frame.size.width) / 2),
                                         (NSUInteger) ((80 - _noItemsMessage.frame.size.height) / 2) );
    //_noItemsMessage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|
    //UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    [self addSubview: _noItemsMessage];
  }
  
  return self;
}

- (void) layoutSubviews
{
  [super layoutSubviews];
  _noItemsMessage.frame = CGRectMake( (NSUInteger) ((self.frame.size.width - _noItemsMessage.frame.size.width) / 2),
                                     (NSUInteger) (_itemTypeImage.frame.origin.y + _itemTypeImage.frame.size.height + 20 +
                                                   (_noItemsMessage.frame.size.height / 2)),
                                     _noItemsMessage.frame.size.width, _noItemsMessage.frame.size.height );
}

- (void) dealloc
{
  [_itemTypeImage release];
  [_noItemsMessage release];
  [super dealloc];
}


@end
