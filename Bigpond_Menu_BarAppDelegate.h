//
//  Bigpond_Menu_BarAppDelegate.h
//  Bigpond Menu Bar
//
//  Created by Anthony on 11/02/10.
//  Copyright 2010 Anthony. All rights reserved.
//


//Frameworks: Security, Cocoa, AppKit, CoreData, Foundation

#import <Cocoa/Cocoa.h>

#import "LoginItemsAE.h"

#define JSON 0
#import "UsageMeter.h"



#define SECONDS * 1
#define MINUTES * 60 SECONDS


@interface BigpondUsageMeterDesktopAppDelegate : NSObject /*<NSApplicationDelegate>*/ {
    IBOutlet NSWindow *window;
	IBOutlet NSLevelIndicator* usedMeter;
	IBOutlet NSLevelIndicator* timeMeter;
	IBOutlet NSProgressIndicator* progressIndicator;
	IBOutlet NSTextField* usedLabel;
	IBOutlet NSTextField* timeLabel;
	IBOutlet NSTextField* freeLabel;
	IBOutlet NSMenu *statusMenu;
	IBOutlet NSWindow *loginWindow;
	IBOutlet NSWindow *updateWindow;
	IBOutlet NSProgressIndicator *updatingIndicator;
	//IBOutlet NSButton *checkForUpdatesAtStartupCheckBox;
	IBOutlet NSButton *runAtStartupCheckBox;
	IBOutlet NSButton *savePasswordCheckBox;
	IBOutlet NSTextField *usernameField;
	IBOutlet NSTextField *passwordField;
	IBOutlet NSTextField *userLabel;
	IBOutlet NSTextField *versionLabel;
	IBOutlet NSMenuItem *updateMenuItem;
	IBOutlet NSTextField *percentOfMonthLabel;
	IBOutlet NSPopUpButton *updatePeriodPopUp;
	IBOutlet NSMenuItem *setShowModeIconOnlyButton;
	IBOutlet NSMenuItem *setShowModePercentageButton;
	IBOutlet NSTextField *checkForUpdatesCheckingLabel;
	IBOutlet NSButton *downloadButton;
	
    NSStatusItem * statusItem;
	
	//UMDataStore* data;
}
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenuItem *setShowModeIconOnlyButton;
@property (assign) IBOutlet NSMenuItem *setShowModePercentageButton;
@property (assign) IBOutlet NSButton *downloadButton;
@property (assign) IBOutlet NSMenuItem *updateMenuItem;
@property (assign) IBOutlet NSTextField *checkForUpdatesCheckingLabel;
@property (assign) IBOutlet NSPopUpButton *updatePeriodPopUp;
@property (assign) IBOutlet NSTextField *percentOfMonthLabel;
@property (assign) IBOutlet NSTextField *usernameField;
@property (assign) IBOutlet NSTextField *passwordField;
@property (assign) IBOutlet NSTextField *versionLabel;
@property (assign) IBOutlet NSTextField *freeLabel;
@property (assign) IBOutlet NSTextField *userLabel;
//@property (assign) IBOutlet NSButton *checkForUpdatesAtStartupCheckBox;
@property (assign) IBOutlet NSButton *savePasswordCheckBox;
@property (assign) IBOutlet NSButton *runAtStartupCheckBox;
@property (assign) IBOutlet NSWindow *updateWindow;
@property (assign) IBOutlet	NSProgressIndicator *updatingIndicator;
@property (assign) IBOutlet NSWindow *loginWindow;
@property (assign) IBOutlet NSLevelIndicator *usedMeter;
@property (assign) IBOutlet NSLevelIndicator *timeMeter;
@property (assign) IBOutlet NSProgressIndicator* progressIndicator;
@property (assign) IBOutlet NSTextField* usedLabel;
@property (assign) IBOutlet NSTextField* timeLabel;


-(int)		getTimerPeriodInSeconds;
-(void)		configureTimer;
-(void)		setStatusText:(NSString *)text;
-(IBAction)	complete:(id)sender;
-(IBAction)	cancelOperation:(id)sender;
//-(IBAction) cancelUpdate:(id)sender;
-(IBAction) showLogin:(id)sender;
//-(void)		checkUpdateDone:(id)sender;
-(BOOL)		alert:(NSString *)message;
-(IBAction)	openDownloadPage:(id)sender;
-(IBAction)	openLicencePage:(id)sender;
-(IBAction)	setPreferenceUpdatePeriod:(id)sender;
//-(IBAction) checkforupdates:(id)sender;
-(IBAction) setAtStartup:(id)sender;
- (IBAction) receiveError:(NSString *)errorString;
//-(IBAction) setCheckUpdatesAtStartup:(id)sender;
-(IBAction) setShowModeIconOnly:(id)sender;
-(IBAction) setShowModePercentage:(id)sender;
-(IBAction) update:(id)sender;
-(BOOL)		_doupdate:(id)sender;
-(BOOL)		showSecurityError:(OSStatus)err;
@end
