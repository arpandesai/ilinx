//
//  StandardPalette.m
//  iLinX
//
//  Created by mcf on 28/04/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "StandardPalette.h"
#import "ConfigManager.h"
#import "ConfigProfile.h"
#import "OS4ToolbarFix.h"

static NSString * const kEnableSkinKey = @"enableSkinKey";
static StandardPalette *g_defaultPalette = nil;

@interface StandardPalette ()

- (id) initWithDictionary: (NSDictionary *) dictionary;
- (UIColor *) colourFromFloatArray: (NSArray *) floatArray;
- (UIColor *) colourFromString: (NSString *) string;

@end

@implementation StandardPalette

@synthesize
  statusBarStyle = _statusBarStyle,
  buttonColour = _buttonColour,
  buttonTitleColour = _buttonTitleColour,
  buttonTitleShadowColour = _buttonTitleShadowColour,
  highlightedButtonTitleColour = _highlightedButtonTitleColour,
  highlightedButtonTitleShadowColour = _highlightedButtonTitleShadowColour,
  standardTintColour = _standardTintColour,
  multizoneTintColour = _multizoneTintColour,
  placeholderTextColour = _placeholderTextColour,
  editableTextColour = _editableTextColour,
  tableBackgroundTintColour = _tableBackgroundTintColour,
  tableCellColour = _tableCellColour,
  selectedTableCellColour = _selectedTableCellColour,
  tableSeparatorColour = _tableSeparatorColour,
  tableTextColour = _tableTextColour,
  disabledTableTextColour = _disabledTableTextColour,
  selectedTableTextColour = _selectedTableTextColour,
  highlightedTableTextColour = _highlightedTableTextColour,
  alternativeTableTextColour = _alternativeTableTextColour,
  smallTableTextColour = _smallTableTextColour,
  tableGroupedHeaderTextColour = _tableGroupedHeaderTextColour,
  tableGroupedHeaderShadowColour = _tableGroupedHeaderShadowColour,
  tablePlainHeaderTextColour = _tablePlainHeaderTextColour,
  tablePlainHeaderShadowColour = _tablePlainHeaderShadowColour,
  tablePlainHeaderTintColour = _tablePlainHeaderTintColour,
  noItemTitleColour = _noItemTitleColour,
  customPageBackgroundColour = _customPageBackgroundColour;

+ (void) initialise
{
  // Other alternatives that have been used:
  // [UIColor colorWithRed: 0x33/255.0 green: 0x66/255.0 blue: 0x99/255.0 alpha: 1.0]
  // [UIColor colorWithRed: 41.0/255.0 green: 74.0/255.0 blue: 112.0/255.0 alpha: 1.0]
  NSArray *darkBlueGreyColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 50.0/255.0], 
                                 [NSNumber numberWithFloat: 79.0/255.0], [NSNumber numberWithFloat: 133.0/255.0], nil];
  NSArray *midBlueGreyColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 79.0/255.0], 
                                [NSNumber numberWithFloat: 90.0/255.0], [NSNumber numberWithFloat: 108.0/255.0], nil];
  //NSArray *lightBlueGreyColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 202.0/255.0], 
  //                                [NSNumber numberWithFloat: 185.0/255.0], [NSNumber numberWithFloat: 133.0/255.0], nil];
  NSArray *buttonTitleColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.9], 
                                [NSNumber numberWithFloat: 0.9], [NSNumber numberWithFloat: 0.9], nil];
  //NSArray *standardTintColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 129.0/255.0], 
  //                               [NSNumber numberWithFloat: 149.0/255.0], [NSNumber numberWithFloat: 175.0/255.0], nil];
  NSArray *multizoneTintColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.5], 
                                  [NSNumber numberWithFloat: 0.3], [NSNumber numberWithFloat: 0], nil];
  NSArray *placeholderTextColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.7], 
                                    [NSNumber numberWithFloat: 0.7], [NSNumber numberWithFloat: 0.7], nil];
  //NSArray *selectedTableCellColour = [NSArray arrayWithObjects: [NSNumber numberWithFloat: 0.0/255.0], 
  //                                    [NSNumber numberWithFloat: 100.0/255.0], [NSNumber numberWithFloat: 255.0/255.0], nil];
  NSMutableDictionary *defaultDictionary = [NSMutableDictionary
                                            dictionaryWithObjectsAndKeys:
                                            @"UIStatusBarStyleDefault", @"StatusBarStyle",
                                            darkBlueGreyColour, @"Button",
                                            buttonTitleColour, @"ButtonTitle",
                                            @"darkGray", @"ButtonTitleShadow",
                                            @"white", @"HighlightedButtonTitle",
                                            @"darkGray", @"HighlightedButtonTitleShadow",
                                            //standardTintColour, @"StandardTint",
                                            multizoneTintColour, @"MultizoneTint",
                                            darkBlueGreyColour, @"EditableText",
                                            placeholderTextColour, @"PlaceholderText",
                                            //lightBlueGreyColour, @"TableBackgroundTint",
                                            @"white", @"TableCell",
                                            //selectedTableCellColour, @"SelectedTableCell",
                                            @"lightGray", @"TableSeparator",
                                            @"black", @"TableText",
                                            @"lightGray", @"DisabledTableText",
                                            @"white", @"SelectedTableText",
                                            darkBlueGreyColour, @"HighlightedTableText",
                                            midBlueGreyColour, @"AlternativeTableText",
                                            @"gray", @"SmallTableText",
                                            //darkBlueGreyColour, @"TableGroupedHeaderText",
                                            //@"white", @"TableGroupedHeaderShadow",
                                            //@"white", @"TablePlainHeaderText",
                                            //@"darkGray", @"TablePlainHeaderShadow",
                                            //darkBlueGreyColour, @"TablePlainHeaderTint",
                                            @"darkGray", @"NoItemTitle",
                                            nil];
  NSURL *skinURL = [ConfigManager currentProfileData].resolvedSkinURL;
  NSDictionary *customDictionary;

  [g_defaultPalette release];

  // Do we have a skin URL?
  if (skinURL == nil || ![[NSUserDefaults standardUserDefaults] boolForKey: kEnableSkinKey]) 
  {
    // No, so fall through to use default palette
    customDictionary = nil;
  } 
  else
  {
    // Yes, but are we using a local unpacked zipfile?
    NSString *sSkinURL = [skinURL absoluteString];
    
    if ([sSkinURL characterAtIndex:[sSkinURL length] - 1] == '/')
    {
      // No, so fetch palette from remote plist
      NSLog( @"Fetching palette from webserver" );
      customDictionary = [NSDictionary dictionaryWithContentsOfURL: 
                          [NSURL URLWithString: @"palette.plist" relativeToURL: skinURL]];
    }
    else
    {
      // Yes, so fetch palette from local file
      NSLog( @"Fetching palette from local file" );
      NSArray *paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
      NSString *documentsDirectory = [paths objectAtIndex: 0];
      NSString *filename = [documentsDirectory stringByAppendingFormat: @"/unpacked/palette.plist"];
      
      customDictionary = [NSDictionary dictionaryWithContentsOfFile: filename];
    }
  }
  
  if (customDictionary != nil)
    [defaultDictionary addEntriesFromDictionary: customDictionary];
  
  g_defaultPalette = [[StandardPalette alloc] initWithDictionary: defaultDictionary];
}

- (id) initWithDictionary: (NSDictionary *) dictionary
{
  if (self = [super init])
  {
    _statusBarStyle = UIStatusBarStyleDefault;
    
    for (NSString *key in [dictionary allKeys])
    {
      id value = [dictionary objectForKey: key];
      
      if ([key isEqualToString: @"StatusBarStyle"])
      {
        if ([value isEqualToString: @"UIStatusBarStyleBlackOpaque"])
          self.statusBarStyle = UIStatusBarStyleBlackOpaque;
        else if ([value isEqualToString: @"UIStatusBarStyleBlackTranslucent"])
          self.statusBarStyle = UIStatusBarStyleBlackTranslucent;
      }
      else
      {
        SEL colourSelector = NSSelectorFromString( [NSString stringWithFormat: @"set%@Colour:", key] );
        
        if ([self respondsToSelector: colourSelector])
        {
          UIColor *colour;
          
          if ([value isKindOfClass: [NSString class]])
            colour = [self colourFromString: value];
          else if ([value isKindOfClass: [NSArray class]])
            colour = [self colourFromFloatArray: value];
          else
            colour = nil;
          
          if (colour != nil)
            [self performSelector: colourSelector withObject: colour];
        }
      }
    }
  }
  
  return self;
}

- (UIColor *) colourFromFloatArray: (NSArray *) floatArray
{
  UIColor *colour;
  
  if ([floatArray count] != 3)
    colour = nil;
  else
  {
    NSNumber *red = [floatArray objectAtIndex: 0];
    NSNumber *green = [floatArray objectAtIndex: 1];
    NSNumber *blue = [floatArray objectAtIndex: 2];
    
    if ([red isKindOfClass: [NSNumber class]] && [green isKindOfClass: [NSNumber class]] &&
      [blue isKindOfClass: [NSNumber class]])
      colour = [UIColor colorWithRed: [red floatValue] green: [green floatValue] blue: [blue floatValue] alpha: 1.0];
    else
      colour = nil;
  }

  return colour;
}

- (UIColor *) colourFromString: (NSString *) string
{
  SEL colourSelector;
  UIColor *colour;

  string = [string stringByReplacingOccurrencesOfString: @"grey" withString: @"gray"];
  string = [string stringByReplacingOccurrencesOfString: @"Grey" withString: @"Gray"];
  colourSelector = NSSelectorFromString( [string stringByAppendingString: @"Color"] );
  
  if ([UIColor respondsToSelector: colourSelector])
    colour = [UIColor performSelector: colourSelector];
  else
    colour = nil;

  return colour;
}

- (void) dealloc
{
  [_buttonColour release];
  [_buttonTitleColour release];
  [_buttonTitleShadowColour release];
  [_highlightedButtonTitleColour release];
  [_highlightedButtonTitleShadowColour release];
  [_standardTintColour release];
  [_multizoneTintColour release];
  [_placeholderTextColour release];
  [_editableTextColour release];
  [_tableBackgroundTintColour release];
  [_tableCellColour release];
  [_selectedTableCellColour release];
  [_tableSeparatorColour release];
  [_tableTextColour release];
  [_disabledTableTextColour release];
  [_selectedTableTextColour release];
  [_highlightedTableTextColour release];
  [_alternativeTableTextColour release];
  [_smallTableTextColour release];
  [_tableGroupedHeaderTextColour release];
  [_tableGroupedHeaderShadowColour release];
  [_tablePlainHeaderTextColour release];
  [_tablePlainHeaderShadowColour release];
  [_tablePlainHeaderTintColour release];
  [_noItemTitleColour release];
  [super dealloc];
}

+ (void) setTintForNavigationBar: (UINavigationBar *) navigationBar
{
  UIColor *standardTintColour = [self standardTintColour];

  if (standardTintColour == [UIColor blackColor])
  {
    navigationBar.barStyle = UIBarStyleBlackOpaque;
    navigationBar.tintColor = nil;
  }
  else
  {
    navigationBar.barStyle = UIBarStyleDefault;
    navigationBar.tintColor = standardTintColour;
  }

  [[UIApplication sharedApplication] setStatusBarStyle: [StandardPalette statusBarStyle] animated: YES];
}

+ (void) setTintForToolbar: (UIToolbar *) toolbar
{
  UIColor *standardTintColour = [self standardTintColour];
  
  if (standardTintColour == [UIColor blackColor])
    [toolbar fixedSetStyle: UIBarStyleBlackOpaque tint: nil];
  else
    [toolbar fixedSetStyle: UIBarStyleDefault tint: standardTintColour];
}

+ (UIColor *) backdropTint
{
  UIColor *tint = [self standardTintColour];
  
  if (tint == nil)
    tint = [UIColor colorWithRed: 50.0/255.0 green: 79.0/255.0 blue: 133.0/255.0 alpha: 1.0];
  
  return tint;
}

+ (UIColor *) timerBarTint
{
  UIColor *tint = [self standardTintColour];
  
  if (tint == nil)
    tint = [UIColor colorWithRed: 50.0/255.0 green: 79.0/255.0 blue: 133.0/255.0 alpha: 1.0];
  
  return tint;
}

+ (UIStatusBarStyle) statusBarStyle
{
  return [g_defaultPalette statusBarStyle];
}

+ (UIColor *) buttonColour
{
  return [g_defaultPalette buttonColour];
}

+ (UIColor *) buttonTitleColour
{
  return [g_defaultPalette buttonTitleColour];
}

+ (UIColor *) buttonTitleShadowColour
{
  return [g_defaultPalette buttonTitleShadowColour];
}

+ (UIColor *) highlightedButtonTitleColour
{
  return [g_defaultPalette highlightedButtonTitleColour];
}

+ (UIColor *) highlightedButtonTitleShadowColour
{
  return [g_defaultPalette highlightedButtonTitleShadowColour];
}

+ (UIColor *) standardTintColour
{
  return [g_defaultPalette standardTintColour];
}

+ (UIColor *) standardTintColourWithAlpha: (CGFloat) alpha
{
  return [[g_defaultPalette standardTintColour] colorWithAlphaComponent: alpha];
}

+ (UIColor *) multizoneTintColour
{
  return [g_defaultPalette multizoneTintColour];
}

+ (UIColor *) multizoneTintColourWithAlpha: (CGFloat) alpha
{
  return [[g_defaultPalette multizoneTintColour] colorWithAlphaComponent: alpha];
}

+ (UIColor *) editableTextColour
{
  return [g_defaultPalette editableTextColour];
}

+ (UIColor *) placeholderTextColour
{
  return [g_defaultPalette placeholderTextColour];
}

+ (UIColor *) tableBackgroundTintColour
{
  return [g_defaultPalette tableBackgroundTintColour];
}

+ (UIColor *) tableCellColour
{
  return [g_defaultPalette tableCellColour];
}

+ (UIColor *) selectedTableCellColour
{
  return [g_defaultPalette selectedTableCellColour];
}

+ (UIColor *) tableSeparatorColour
{
  return [g_defaultPalette tableSeparatorColour];
}

+ (UIColor *) tableTextColour
{
  return [g_defaultPalette tableTextColour];
}

+ (UIColor *) disabledTableTextColour
{
  return [g_defaultPalette disabledTableTextColour];
}

+ (UIColor *) selectedTableTextColour
{
  return [g_defaultPalette selectedTableTextColour];
}

+ (UIColor *) highlightedTableTextColour
{
  return [g_defaultPalette highlightedTableTextColour];
}

+ (UIColor *) alternativeTableTextColour
{
  return [g_defaultPalette alternativeTableTextColour];
}

+ (UIColor *) smallTableTextColour
{
  return [g_defaultPalette smallTableTextColour];
}

+ (UIColor *) tableGroupedHeaderTextColour
{
  return [g_defaultPalette tableGroupedHeaderTextColour];
}

+ (UIColor *) tableGroupedHeaderShadowColour
{
  return [g_defaultPalette tableGroupedHeaderShadowColour];
}

+ (UIColor *) tablePlainHeaderTextColour
{
  return [g_defaultPalette tablePlainHeaderTextColour];
}

+ (UIColor *) tablePlainHeaderShadowColour
{
  return [g_defaultPalette tablePlainHeaderShadowColour];
}

+ (UIColor *) tablePlainHeaderTintColour
{
  return [g_defaultPalette tablePlainHeaderTintColour];
}

+ (UIColor *) noItemTitleColour
{
  return [g_defaultPalette noItemTitleColour];
}

+ (UIColor *) customPageBackgroundColour
{
  return [g_defaultPalette customPageBackgroundColour];
}

@end
