//
//  HVACControlButtonPanelIPad.m
//  iLinX
//
//  Created by Tony Short on 15/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import "HVACControlButtonPanelIPad.h"
#import "UncodableObjectArchiver.h"

@interface HVACControlButtonPanelIPad ()

- (void) initialiseTemplates;

@end

@implementation HVACControlButtonPanelIPad

@synthesize hvacService = _hvacService;

- (void) dealloc
{
  [_pageControl release];
  [_onTemplate release];
  [_offTemplate release];
  [_hvacService release];
  [_buttonArray release];
  [_archivedOnTemplate release];
  [_archivedOffTemplate release];
  [super dealloc];
}

- (void) layoutSubviews
{
  CGFloat marginWidth = _buttonRect.origin.x;
  CGFloat marginHeight = _buttonRect.origin.y;
  CGFloat availableSpaceWidth = self.frame.size.width - (2 * marginWidth);
  CGFloat availableSpaceHeight = self.frame.size.height - (2 * marginHeight);  
  CGFloat buttonHeight = _buttonRect.size.height;
  CGFloat buttonWidth = _buttonRect.size.width;
  NSInteger minimumSpacing = buttonWidth / 2;
  NSInteger count = [_buttonArray count];
  CGFloat availableSpaceBetweenWidth;
  CGFloat availableSpaceBetweenHeight;
  NSInteger buttonsPerRow;
  NSInteger buttonRows;
  
  if (minimumSpacing > (NSInteger) (buttonHeight / 2))
    minimumSpacing = (NSInteger) (buttonHeight / 2);
  buttonsPerRow = (NSInteger) ((availableSpaceWidth + minimumSpacing) / (buttonWidth + minimumSpacing));
  buttonRows = (NSInteger) ((availableSpaceHeight + minimumSpacing) / (buttonHeight + minimumSpacing));
  
  if (buttonsPerRow < 2)
    availableSpaceBetweenWidth = 0;
  else
    availableSpaceBetweenWidth = (availableSpaceWidth - (buttonsPerRow * buttonWidth)) / (buttonsPerRow - 1);
  
  if (buttonRows < 2)
    availableSpaceBetweenHeight = 0;
  else
    availableSpaceBetweenHeight = (availableSpaceHeight - (buttonRows * buttonHeight))/(buttonRows - 1);
  
  if (buttonsPerRow < 1)
    buttonsPerRow = 1;
  if (buttonRows < 1)
    buttonRows = 1;

  if (count == 0)
    _pageControl.numberOfPages = 0;
  else
  {
    _pageControl.numberOfPages = ((count - 1) / (buttonRows * buttonsPerRow)) + 1;
    _pageControl.currentPage = 0;
    self.contentSize = CGSizeMake( self.frame.size.width * _pageControl.numberOfPages, self.frame.size.height );
    
    NSInteger numCols = (count < buttonsPerRow) ? count : buttonsPerRow;
    NSInteger row = 0, col = 0, page = 0;
    
    for (NSArray *buttons in _buttonArray)
    {
      for (UIButton *button in buttons)
      {
        button.frame = CGRectMake( marginWidth + ((availableSpaceBetweenWidth + buttonWidth) * col) + (page * self.frame.size.width),
                                  marginHeight + ((availableSpaceBetweenHeight + buttonHeight) * row), 
                                  buttonWidth, buttonHeight );
      }
      col++;
      if (col == numCols)
      {
        row++;
        col = 0;
      }
      if (row == buttonRows)
      {
        row = 0;
        col = 0;
        page++;
      }
    }
  }

  [super layoutSubviews];
}

- (void) controlButtonPressed: (id) sender
{
  [_hvacService pushButton: ((UIButton *) sender).tag inControlMode: _controlMode];
}

- (IBAction) pageControlChanged
{
  self.contentOffset = CGPointMake( _pageControl.currentPage * self.frame.size.width, 0 );
}

- (void) scrollViewDidEndDecelerating: (UIScrollView *) scrollView
{
  _pageControl.currentPage = self.contentOffset.x / (self.frame.size.width);
}

- (void) updateButtonStates
{
  NSArray *states = [_hvacService.controlModeStates objectAtIndex: _controlMode];
  int i = 0;
  
  for (NSArray *buttons in _buttonArray)
  {
    if (i == states.count)
      break;
    
    NSString *stateString = [states objectAtIndex: i];
    BOOL hasIndicator = (stateString.length > 0);
    BOOL selected = ![stateString isEqualToString: @"0"];

    for (int j = 0; j < 3; ++j)
    {
      UIButton *button = [buttons objectAtIndex: j];
      
      if (j == 0)
        button.hidden = !hasIndicator || selected;
      else if (j == 1)
        button.hidden = !(hasIndicator && selected);
      else
        button.hidden = hasIndicator;
    }
    i++;
  }
}

- (void) updateWithControlModeID: (NSInteger) controlMode
{
  [self initialiseTemplates];

  _controlMode = controlMode;
  self.delegate = self;
  
  NSArray *array = [_hvacService.controlModeTitles objectAtIndex: controlMode];
  
  for (NSArray *buttons in _buttonArray)
  {
    for (UIView *button in buttons)
      [button removeFromSuperview];
  }
  [_buttonArray removeAllObjects];

  int i = 0;

  for (NSString *buttonTitle in array)
  {
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity: 3];

    for (int b = 0; b < 3; ++b)
    {
      UIButton *button;
      
      if (b == 0)
        button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: _archivedOffTemplate];
      else if (b == 1)
        button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: _archivedOnTemplate];
      else
        button = [UncodableObjectUnarchiver unarchiveObjectWithDictionary: _archivedNoIndicatorTemplate];
      
      [button setTitle: buttonTitle forState: UIControlStateNormal];
      button.tag = i;		
      [button addTarget: self action: @selector(controlButtonPressed:) forControlEvents: UIControlEventTouchUpInside];
      [self addSubview: button];
      [buttons addObject: button];
    }
    [_buttonArray addObject: buttons];
    i++;
  }

  [self updateButtonStates];
  [self setNeedsLayout];
}

- (void) initialiseTemplates
{
  if (_archivedOnTemplate == nil)
  {
    _archivedOffTemplate = [[UncodableObjectArchiver dictionaryEncodingWithRootObject: _offTemplate] retain];
    _archivedOnTemplate = [[UncodableObjectArchiver dictionaryEncodingWithRootObject: _onTemplate] retain];
    _archivedNoIndicatorTemplate = [[UncodableObjectArchiver dictionaryEncodingWithRootObject: _noIndicatorTemplate] retain];
    _buttonRect = _offTemplate.frame;
    _buttonArray = [NSMutableArray new];

    // Hide the templates once they're no longer needed
    _offTemplate.hidden = YES;
    _onTemplate.hidden = YES;
    _noIndicatorTemplate.hidden = YES;
  }
}

@end
