//
//  ExecutingMacroAlert.m
//  iLinX
//
//  Created by mcf on 28/08/2009.
//  Copyright 2009 Micropraxis Ltd.. All rights reserved.
//

#import "ExecutingMacroAlert.h"
#import "RootViewController.h"

@interface ExecutingMacroAlert ()

- (void) executingMacroTimeoutExpired: (NSTimer *) timer;
- (void) selectNewService: (NLService *) newService animated: (BOOL) animated;

@end

@implementation ExecutingMacroAlert

- (void) loadViewUnderView: (UIView *) view atIndex: (NSInteger) index inBounds: (CGRect) mainViewBounds
  withNavigationController: (UINavigationController *) navigationController 
{
  _navigationController = [navigationController retain];
  _disableInput = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  _disableInput.backgroundColor = [UIColor colorWithWhite: 0.1 alpha: 0.2];
  [_disableInput setFrame: mainViewBounds];
  [view insertSubview: _disableInput atIndex: index];
  
  _executingMacroBanner = [[UIButton buttonWithType: UIButtonTypeCustom] retain];
  [_executingMacroBanner setImage: [UIImage imageNamed: @"AlertBox.png"] forState: UIControlStateNormal];
  [_executingMacroBanner sizeToFit];
  [_executingMacroBanner setFrame: 
   CGRectOffset( _executingMacroBanner.frame,
                (NSUInteger) (mainViewBounds.size.width - _executingMacroBanner.frame.size.width) / 2,
                (NSUInteger) (mainViewBounds.size.height - _executingMacroBanner.frame.size.height) / 2 )];
  [view insertSubview: _executingMacroBanner atIndex: index + 1];
  
  _executingMacroTitle = [[UILabel new] initWithFrame:
                          CGRectMake( _executingMacroBanner.frame.origin.x,
                                     _executingMacroBanner.frame.origin.y + 20,
                                     _executingMacroBanner.frame.size.width, 21 )];
  _executingMacroTitle.text = NSLocalizedString( @"Running macro...", 
                                                @"Message shown when waiting for a macro to complete execution" );
  _executingMacroTitle.textAlignment = UITextAlignmentCenter;
  _executingMacroTitle.font = [UIFont boldSystemFontOfSize: [UIFont labelFontSize]];
  _executingMacroTitle.backgroundColor = [UIColor clearColor];
  _executingMacroTitle.textColor = [UIColor whiteColor];
  _executingMacroTitle.shadowColor = [UIColor blackColor];
  _executingMacroTitle.shadowOffset = CGSizeMake( 0, -1 );
  [view insertSubview: _executingMacroTitle atIndex: index + 2];
  
  _executingMacroActivity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
  [_executingMacroActivity setFrame: 
   CGRectMake( (NSUInteger) (_executingMacroBanner.frame.origin.x + 
                             ((_executingMacroBanner.frame.size.width - _executingMacroActivity.frame.size.width) / 2)),
              CGRectGetMaxY( _executingMacroBanner.frame ) - (_executingMacroActivity.frame.size.height + 20),
              _executingMacroActivity.frame.size.width, _executingMacroActivity.frame.size.height )];
  [view insertSubview: _executingMacroActivity atIndex: index + 3];
  
  [self showExecutingMacroBanner: NO];
}

- (void) selectNewService: (NLService *) newService afterDelay: (NSTimeInterval) delay animated: (BOOL) animated
{
  if (newService != nil)
  {
    if (delay == 0)
      [self selectNewService: newService animated: animated];
    else
    {
      // Show modal "waiting for execution" overlay
      [self showExecutingMacroBanner: YES];
      
      // and wait for the specified delay
      [self cancelExecutingMacroTimer];
      _animated = animated;
      _executingMacroTimer = 
      [NSTimer scheduledTimerWithTimeInterval: delay
                                       target: self selector: @selector(executingMacroTimeoutExpired:)
                                     userInfo: newService repeats: NO];
    }
  }
}

- (void) cancelExecutingMacroTimer
{
  if (_executingMacroTimer != nil)
  {
    [_executingMacroTimer invalidate];
    _executingMacroTimer = nil;
  }
}

- (void) executingMacroTimeoutExpired: (NSTimer *) timer
{
  NLService *newService = (NLService *) [timer userInfo];
  
  _executingMacroTimer = nil;
  [self showExecutingMacroBanner: NO];
  [self selectNewService: newService animated: _animated];
}

- (void) selectNewService: (NLService *) newService animated: (BOOL) animated
{
  [(RootViewController *) [[_navigationController viewControllers] objectAtIndex: 0]
   selectService: newService animated: animated];
}

- (void) showExecutingMacroBanner: (BOOL) show
{
  _disableInput.hidden = !show;
  _executingMacroTitle.hidden = !show;
  _executingMacroBanner.hidden = !show;
  _executingMacroActivity.hidden = !show;
  if (show)
    [_executingMacroActivity startAnimating];
  else
    [_executingMacroActivity stopAnimating];
}

- (void) dealloc
{
  [_navigationController release];
  [_disableInput release];
  [_executingMacroTitle release];
  [_executingMacroBanner release];
  [_executingMacroActivity release];
  [super dealloc];
}

@end
