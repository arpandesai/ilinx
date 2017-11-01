//
//  TunerPresetTableView.h
//  iLinX
//
//  Created by Tony Short on 07/09/2010.
//  Copyright 2010 Micropraxis Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NLSourceTuner.h"
#import "ListDataSource.h"

@class BrowseMenuInfo;

@interface TunerPresetView : UIView 
		<UITableViewDelegate, UITableViewDataSource, ListDataDelegate, UIAlertViewDelegate, UINavigationControllerDelegate>
{
	NLSourceTuner *_tuner;
	id<ListDataSource> _leafBrowseList;
	id<ListDataSource> _branchBrowseList;
	id<ListDataSource> _currentBrowseList;

	IBOutlet UITableView *_presetTableView;
	IBOutlet UIBarButtonItem *_listBarButton;
	IBOutlet UIBarButtonItem *_deleteRefreshButton;
	UIAlertView *_deletePresetsAlertView;
	UIAlertView *_refreshPresetsAlertView;
	
	UIPopoverController *_listPopover;
	UINavigationController *_listNavigationController;
}

-(void)setupOnViewWillAppear;
-(void)cleanupOnViewDidDisappear;
-(void)deselectPreset;
-(void)updateLists;
-(void)setStartingList;
-(void)reloadTableView;
-(void)rotated;
-(void)reassignBrowseList;

-(IBAction)listBarButtonPressed:(id)control;
-(IBAction)deleteRefreshButtonPressed:(id)control;

@property (nonatomic, retain) NLSourceTuner *tuner;

@end

@interface BranchTableViewController : UITableViewController
{
	id<ListDataSource> _browseList;
}

@property (nonatomic, retain) id<ListDataSource> browseList;

@end

