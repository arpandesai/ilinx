//
//  PseudoBarButton.m
//  iLinX
//
//  Created by mcf on 01/11/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "PseudoBarButton.h"

static int CONTROL_EVENTS[] =
{
  UIControlEventTouchDown,
  UIControlEventTouchDownRepeat,
  UIControlEventTouchDragInside,
  UIControlEventTouchDragOutside,
  UIControlEventTouchDragEnter,
  UIControlEventTouchDragExit,
  UIControlEventTouchUpInside,
  UIControlEventTouchUpOutside,
  UIControlEventTouchCancel,
  UIControlEventValueChanged,
  UIControlEventEditingDidBegin,
  UIControlEventEditingChanged,
  UIControlEventEditingDidEnd,
  UIControlEventEditingDidEndOnExit
};
#define CONTROL_EVENTS_COUNT (sizeof(CONTROL_EVENTS)/sizeof(CONTROL_EVENTS[0]))


@implementation PseudoBarButton

- (void) initButton
{
  _button = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  _button.frame = self.frame;
  _button.titleLabel.font = [UIFont boldSystemFontOfSize: 12];
  [_button setTitleColor: [UIColor whiteColor] forState: UIControlStateNormal];
  [_button setTitleShadowColor: [UIColor darkGrayColor] forState: UIControlStateNormal];
  _button.titleLabel.shadowOffset = CGSizeMake( 0, -1 );
  [_button addTarget: self action: @selector(buttonPush) 
    forControlEvents: UIControlEventTouchDown];
  [_button addTarget: self action: @selector(buttonRelease) 
    forControlEvents: UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];

  self.segmentedControlStyle = UISegmentedControlStyleBar;
  if (self.numberOfSegments == 0)
    [self insertSegmentWithTitle: @"" atIndex: 0 animated: NO];
  [_button setTitle: [self titleForSegmentAtIndex: 0] forState: UIControlStateNormal];
  [_button setImage: [self imageForSegmentAtIndex: 0] forState: UIControlStateNormal];
  _button.adjustsImageWhenHighlighted = NO;
  if (self.numberOfSegments > 1)
  {
    [self removeAllSegments];
    [self insertSegmentWithTitle: @"" atIndex: 0 animated: NO];
  }
  [self setTitle: @"" forSegmentAtIndex: 0];
  [self setImage: nil forSegmentAtIndex: 0];
  if (self.tintColor == nil)
    [self setSelectedSegmentIndex: 0];
  else
    [self setSelectedSegmentIndex: UISegmentedControlNoSegment];
  
  //self.tintColor = [UIColor colorWithRed: 102/185.0 green: 109/189.0 blue: 115/191.0 alpha: 1.0];
  //[self setSelectedSegmentIndex: UISegmentedControlNoSegment];
  _selectedOverlay = [[UISegmentedControl alloc] initWithItems: [NSArray arrayWithObject: @""]];
  _selectedOverlay.segmentedControlStyle = UISegmentedControlStyleBar;
  _selectedOverlay.tintColor = [UIColor blackColor];
  _selectedOverlay.alpha = 0.25;
  _selectedOverlay.frame = self.frame;
  [_selectedOverlay setSelectedSegmentIndex: 0];
  _selectedOverlay.hidden = YES;
}

- (void) buttonPush
{
  _selectedOverlay.hidden = NO;
}

- (void) buttonRelease
{
  _selectedOverlay.hidden = YES;
}

- (id) init
{
  if (self = [super init])
    [self initButton];
  
  return self;
}

- (id) initWithItems: (NSArray *) items
{
  if ([items count] > 1)
    items = [NSArray arrayWithObject: [items objectAtIndex: 0]];

  if (self = [super initWithItems: items])
    [self initButton];
  
  return self;
}

- (id) initWithFrame: (CGRect) frame
{
  if (self = [super initWithFrame: frame])
    [self initButton];

  return self;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
  if (self = [super initWithCoder: aDecoder])
  {
    _button = [[aDecoder decodeObjectForKey: @"button"] retain];
    if (_button == nil)
      [self initButton];
    for (id target in [self allTargets])
    {
      for (int i = 0; i < CONTROL_EVENTS_COUNT; ++i)
      {
        for (NSString *action in [self actionsForTarget: target forControlEvent: CONTROL_EVENTS[i]])
          [_button addTarget: target action: NSSelectorFromString(action) forControlEvents: CONTROL_EVENTS[i]];
      }
    }
  }

  return self;
}

- (void) encodeWithCoder: (NSCoder *) encoder
{
  [super encodeWithCoder: encoder];
  [encoder encodeObject: _button forKey: @"button"];
}

- (void) addTarget: (id) target action: (SEL) action forControlEvents: (UIControlEvents) controlEvents
{
  [super addTarget: target action: action forControlEvents: controlEvents];
  [_button addTarget: target action: action forControlEvents: controlEvents];
}

- (void) removeTarget: (id) target action: (SEL) action forControlEvents: (UIControlEvents) controlEvents
{
  [super removeTarget: target action: action forControlEvents: controlEvents];
  [_button removeTarget: target action: action forControlEvents: controlEvents];
}

- (void) setFrame: (CGRect) frame
{
  [super setFrame: frame];
  _button.frame = frame;
  _selectedOverlay.frame = frame;
  [self.superview insertSubview: _button aboveSubview: self];
  [self.superview insertSubview: _selectedOverlay aboveSubview: self];
}

- (NSString *) title
{
  return [_button titleForState: UIControlStateNormal];
}

- (void) setTitle: (NSString *) title
{
  [self setTitle: title forSegmentAtIndex: 0];
  if ([title length] == 0)
    [self setImage: [_button imageForState: UIControlStateNormal] forSegmentAtIndex: 0];
  [self sizeToFit];
  self.frame = CGRectMake( self.frame.origin.x, self.frame.origin.y,
                          self.frame.size.width + 6, self.frame.size.height );
  [self setTitle: @"" forSegmentAtIndex: 0];
  [self setImage: nil forSegmentAtIndex: 0];
  [_button setTitle: title forState: UIControlStateNormal];
}

- (UIImage *) image
{
  return [_button imageForState: UIControlStateNormal];
}

- (void) setImage: (UIImage *) image
{
  [self setImage: image forSegmentAtIndex: 0];
  if (image == nil)
    [self setTitle: [_button titleForState: UIControlStateNormal] forSegmentAtIndex: 0];
  [self sizeToFit];
  self.frame = CGRectMake( self.frame.origin.x, self.frame.origin.y,
                          self.frame.size.width + 6, self.frame.size.height );
  [self setTitle: @"" forSegmentAtIndex: 0];
  [self setImage: nil forSegmentAtIndex: 0];
  [_button setImage: image forState: UIControlStateNormal];
}

- (BOOL) enabled
{
  return _button.enabled;
}

- (void) setEnabled: (BOOL) enabled
{
  _button.enabled = enabled;
}

- (void) setHidden: (BOOL) hidden
{
  [super setHidden: hidden];
  _button.hidden = hidden;
  _selectedOverlay.hidden = YES;
}

- (void) setTintColor: (UIColor *) tintColor
{
  [super setTintColor: tintColor];
  if (tintColor == nil)
    [self setSelectedSegmentIndex: 0];
  else
    [self setSelectedSegmentIndex: UISegmentedControlNoSegment];  
}

- (void) didMoveToSuperview
{
  [super didMoveToSuperview];
  
  if (self.superview != _button.superview)
  {
    [_selectedOverlay removeFromSuperview];
    [_button removeFromSuperview];
    if (self.superview != nil)
    {
      [self.superview insertSubview: _button aboveSubview: self];
      [self.superview insertSubview: _selectedOverlay aboveSubview: self];
    }
  }
}

- (void) dealloc
{
  [_button release];
  [_selectedOverlay release];
  [super dealloc];
}

@end
