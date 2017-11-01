//
//  XIBViewController.m
//  iLinX
//
//  Created by mcf on 26/03/2009.
//  Copyright 2009 Micropraxis Ltd. All rights reserved.
//

#import "XIBViewController.h"
#import "DeprecationHelper.h"

@implementation XIBViewController

+ (void) parseAndSetFontForControl: (UIView *) control fromText: (NSString *) text setFontAction: (SEL) setFontAction
{
  UIFont *font;

  if (text == nil || ![text hasPrefix: @"ƒ"])
    font = nil;
  else
  {
    NSRange colon = [text rangeOfString: @":"];
    
    if (colon.length == 0)
      font = nil;
    else
    {
      NSString *prefix = [text substringWithRange: NSMakeRange( 1, colon.location - 1 )];
      NSRange sizeSpec = [prefix rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"0123456789."]];
      CGFloat fontSize = [prefix floatValue];
      NSUInteger endOfSizeSpec = NSMaxRange( sizeSpec );
      NSUInteger styleLength = [prefix length] - endOfSizeSpec;
      NSString *style;
      
      if (styleLength == 0)
        style = @"";
      else
        style = [prefix substringWithRange: NSMakeRange( endOfSizeSpec, styleLength )];
      
      text = [text substringFromIndex: colon.location + 1];
      if ([style isEqualToString: @"b"])
        font = [UIFont boldSystemFontOfSize: fontSize];
      else if ([style isEqualToString: @"i"])
        font = [UIFont italicSystemFontOfSize: fontSize];
      else
      {
        font = [UIFont fontWithName: style size: fontSize];
        if (font == nil)
          font = [UIFont systemFontOfSize: fontSize];
      }
    }
  }
  
  if (text != nil)
  {
    IMP method = [self methodForSelector: setFontAction];
    
    (*method) ( self, setFontAction, control, text, font );
  }
}

+ (id) setFontActionForButton: (UIButton *) button newText: (NSString *) newText font: (UIFont *) font
{
  [button setTitle: newText forState: UIControlStateNormal];
  [button setTitle: newText forState: UIControlStateHighlighted];
  if (font != nil)
    [button setTitleLabelFont: font];
  [button setTitleColor: [UIColor colorWithWhite: 0.4 alpha: 0.6] forState: UIControlStateNormal];
  [button setTitleShadowColor: [UIColor colorWithWhite: 0.8 alpha: 1.0] forState: UIControlStateNormal];
  [button setTitleColor: [UIColor colorWithWhite: 0.6 alpha: 0.6] forState: UIControlStateHighlighted];
  [button setTitleShadowColor: [UIColor colorWithWhite: 1.0 alpha: 1.0] forState: UIControlStateHighlighted];
  [button setTitleLabelShadowOffset: CGSizeMake( 1, 1 )];
  
  return self;
}

+ (id) setFontActionForLabel: (UILabel *) label newText: (NSString *) newText font: (UIFont *) font
{
  label.text = newText;
  if (font != nil)
    label.font = font;
  label.textColor = [UIColor colorWithWhite: 0.4 alpha: 0.6];
  label.shadowColor = [UIColor colorWithWhite: 0.8 alpha: 1.0];
  label.shadowOffset = CGSizeMake( 1, 1 );
  
  return self;
}

+ (void) setFontForButton: (UIButton *) button
{
  [self parseAndSetFontForControl: button fromText: [button titleForState: UIControlStateNormal]
                    setFontAction: @selector(setFontActionForButton:newText:font:)];
}

+ (void) setFontForLabel: (UILabel *) label
{
  [self parseAndSetFontForControl: label fromText: label.text
                    setFontAction: @selector(setFontActionForLabel:newText:font:)];
}

+ (void) setFontForControl: (UIView *) control
{
  if ([control isKindOfClass: [UIButton class]])
    [self setFontForButton: (UIButton *) control];
  else if ([control isKindOfClass: [UILabel class]])
    [self setFontForLabel: (UILabel *) control];
}

+ (void) setFontsForControlsInView: (UIView *) view
{

  NSArray *subViews = view.subviews;
  NSUInteger count = [subViews count];
  NSUInteger i;
  
  for (i = 0; i < count; ++i)
    [self setFontForControl: [subViews objectAtIndex: i]];
}

- (void) viewDidLoad
{
  [super viewDidLoad];
  [self setFontsForControls];
}

- (void) setFontsForControls
{
  [XIBViewController setFontsForControlsInView: self.view];
}

@end
