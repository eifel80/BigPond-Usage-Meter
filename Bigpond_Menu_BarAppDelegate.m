//
//  Bigpond_Menu_BarAppDelegate.m
//  Bigpond Menu Bar
//
//  Created by Anthony on 11/02/10.
//  Copyright 2010 Anthony. All rights reserved.
//

/*
 
 
 When user clicks "Deny" on keychain, don't try to login with a blank password.
 
 
 
 */



#import "Bigpond_Menu_BarAppDelegate.h"

@implementation BigpondUsageMeterDesktopAppDelegate
@synthesize	
window, usedMeter, checkForUpdatesCheckingLabel,timeMeter, usedLabel,
progressIndicator,timeLabel,setShowModePercentageButton,updateWindow,
loginWindow,savePasswordCheckBox, percentOfMonthLabel, usernameField,
/*eckForUpdatesAtStartupCheckBo*/runAtStartupCheckBox,updateMenuItem,
versionLabel, setShowModeIconOnlyButton, userLabel,updatingIndicator,
passwordField, freeLabel, updatePeriodPopUp, downloadButton;


typedef struct tagUsageInfo{
	
	unsigned long long download;
	unsigned long long upload;
	unsigned long long unmetered;
	unsigned long long usage;
	unsigned long long time;
	
} usageInfo;


usageInfo	newest;
double		updateReady					= 0.0;
BOOL		canceledUpdate				= NO;
BOOL		inConnection				= NO;
long double currentmonthpercent			= 0.0;
int			kShowModePercentage			= 0;
int			kShowModeIconOnly			= 1;
int			percentage					= 0;
BOOL		debugMode					= NO;

NSTimer *	updateTimer;
NSString *	kBigpondConnect;

NSString *	password_non_keychain		= @"";
NSString *	kUpdateServer				= @"http://url3.tk/bpver.php";
NSString *	kUpdateServerPage			= @"http://url3.tk/?p=bpmb";
NSString *	kSoftwareLicencePage		= @"http://url3.tk/?p=mblicence";

NSString *	kImageResourceDefaultIcon	= @"bp";
NSString *	kImageResourceFadedIcon		= @"fade";
NSString *	kImageResourceFailIcon		= @"fail";

NSString *	kPreferenceKeyNameUpdate	= @"Update";
NSString *	kPreferenceKeyNameShow		= @"Show";
NSString *	kPreferenceKeyNameDoNotSave	= @"DoNotSave";
NSString *	kPreferenceKeyNameUsername	= @"Username";
NSString *	kBundleVersionKeyName		= @"CFBundleVersion";
NSString *	kPreferenceKeyNamePeriod	= @"Period";
NSString *	kPreferenceKeyHasRunBefore	= @"HasRunBefore";

char *		kKeyChainserverName			= "signon.bigpond.com";
UInt16		kKeyChainPort				= 443;
char *		kKeyChainPath				= "";

//NSString *passwordCache=nil;

OSStatus kSecurityErrorNotFound			= -25300;


UsageMeter* meter;


- (NSString*) getApplicationFilePath {
	return [[NSBundle mainBundle] bundlePath];
}
- (NSString *) timeString{
	return [[NSDate date] 
			descriptionWithCalendarFormat:@"%H:%M" 
			timeZone:nil
			locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}

CFIndex lastcheckStartupIndexFound=-1;
- (BOOL) doesRunAtStartup{
	lastcheckStartupIndexFound=-1;
	NSString *thisURL = [self getApplicationFilePath];
	OSStatus 			err;
	NSArray *			items;
	CFIndex				itemCount;
	items = NULL;
	
	err = LIAECopyLoginItems((CFArrayRef*)&items);
	if (err == noErr) {
		itemCount = [items count];
		for(int i=0;i<itemCount;i++){
			NSDictionary *dict;
			dict=[items objectAtIndex:i];
			NSURL *url = [dict valueForKey:@"URL"];
			NSString* str = [url path];
			if([thisURL isEqualToString:str]){
				lastcheckStartupIndexFound = i;
				[items release];
				return YES;
			}
		}
	}
	[items release];
	return NO;
}

- (BOOL)getFSRef:(FSRef *)aFSRef forString:(NSString *)string{
	return FSPathMakeRef((const UInt8 *)[string UTF8String], aFSRef,NULL) == noErr;
}
- (BOOL) createStartupEntry{
	
	FSRef item;
	if(![self getFSRef:&item forString:[self getApplicationFilePath]]){
		[self alert:[NSString stringWithFormat:
					 @"Error - Couldn't set the app to run at startup. getFSRef:&item forString:%@",
					 [self getApplicationFilePath]]];
		return NO;
	}
	
	Boolean hideIt=NO;
	int err=0;
	if(err=LIAEAddRefAtEnd(&item,hideIt)){
		[self alert:[NSString stringWithFormat:
					 @"Error couldn't set the app to run at startup: LIAEAddRefAtEnd(&item,NO) returned %d"
					 ,err]];
		return NO;
	}
	return YES;
}
- (BOOL) deleteStartupEntry{
	if([self doesRunAtStartup]){
		if(lastcheckStartupIndexFound!=-1){
			OSStatus err = LIAERemove(lastcheckStartupIndexFound);
			if(err){
				[self alert:[NSString stringWithFormat:
							 @"Unexpected error from: LIAERemove(%d) = %d",
							 lastcheckStartupIndexFound,
							 err]];
			}
			if([self doesRunAtStartup]){
				[self alert:[NSString stringWithFormat:
							 @"Could not delete startup entry in Login Items. %@ %@(%d)",
							 @"Please go to Accounts in System Preferences, then click",
							 @"\"Login Items\" and delete the entry there.\n\nLIAERemove",
							 lastcheckStartupIndexFound]];
				return NO;
			}
		}
	}
	return YES;
}
- (IBAction) setAtStartup:(id)sender{
	if([runAtStartupCheckBox state]==NSOnState){
		if(![self doesRunAtStartup]){
			if(![self createStartupEntry]){
				[runAtStartupCheckBox setState:NSOffState];
			}
		}
	}else {
		if(![self deleteStartupEntry]){
			[runAtStartupCheckBox setState:NSOnState];
		}
	}
}
- (IBAction) loadPreferences:(id)sender{
	
	if(![[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyHasRunBefore]){
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPreferenceKeyNameUpdate];
		[[NSUserDefaults standardUserDefaults] setBool:NO  forKey:kPreferenceKeyNameDoNotSave];
		[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:kPreferenceKeyNamePeriod];
		[[NSUserDefaults standardUserDefaults] setInteger:kShowModePercentage forKey:kPreferenceKeyNameShow];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPreferenceKeyHasRunBefore];
	}
	
	//BOOL SettingCheckForUpdatesAtStartup=[[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameUpdate];
	BOOL SettingDoNotSavePasswordInKeyChainDataBase=[[NSUserDefaults standardUserDefaults] 
													 boolForKey:kPreferenceKeyNameDoNotSave];
	int SetttingUpdatePeriodIndexSetting=[[NSUserDefaults standardUserDefaults]
										  integerForKey:kPreferenceKeyNamePeriod];
	int SettingShowModeIndexSetting=[[NSUserDefaults standardUserDefaults] 
									 integerForKey:kPreferenceKeyNameShow];
	[updatePeriodPopUp selectItemAtIndex:SetttingUpdatePeriodIndexSetting];
	NSString* SettingUsernameOrEmailAccountForBigpondLogin=[[NSUserDefaults standardUserDefaults] 
															stringForKey:kPreferenceKeyNameUsername];
	if(SettingUsernameOrEmailAccountForBigpondLogin==NULL){
		SettingUsernameOrEmailAccountForBigpondLogin=@"";
	}
	if(SettingShowModeIndexSetting==kShowModeIconOnly){
		[setShowModeIconOnlyButton setState:NSOnState];
		[setShowModePercentageButton setState:NSOffState];
	}else {
		[setShowModeIconOnlyButton setState:NSOffState];
		[setShowModePercentageButton setState:NSOnState];
	}
	[runAtStartupCheckBox setState:[self doesRunAtStartup]?NSOnState:NSOffState];
	[versionLabel setStringValue:[NSString stringWithFormat:
								  @"Version: %@",
								  [[[NSBundle mainBundle] infoDictionary] objectForKey:kBundleVersionKeyName]]];
	//[checkForUpdatesAtStartupCheckBox setState:(SettingCheckForUpdatesAtStartup?NSOnState:NSOffState)];
	[savePasswordCheckBox setState:(SettingDoNotSavePasswordInKeyChainDataBase?NSOffState:NSOnState)];
	[usernameField setStringValue:SettingUsernameOrEmailAccountForBigpondLogin];
	if([SettingUsernameOrEmailAccountForBigpondLogin isEqualToString:@""]){
		[userLabel setStringValue:@"<nobody>"];
	}else {
		[userLabel setStringValue:SettingUsernameOrEmailAccountForBigpondLogin];
	}
	[passwordField setStringValue:@""];
}
/*
- (IBAction) setCheckUpdatesAtStartup:(id)sender{
	//Replaced by Sparkle
	return;
	//[[NSUserDefaults standardUserDefaults] setBool:([checkForUpdatesAtStartupCheckBox state]==NSOnState) forKey:kPreferenceKeyNameUpdate];
}*/
/*
- (BOOL) _docheckupdate:(id)sender{
	//do not call this function directly, call update;
	
	NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
	updateReady=0.0;
	canceledUpdate=NO;
	
	NSString *responseString;
	NSURLResponse* resp;
	NSError *error;
	
	NSURLRequest* req = [NSURLRequest requestWithURL:[NSURL URLWithString:kUpdateServer]];
	NSData* data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&error];
	NSString *newest=@"0.0";
	if(responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]){
		newest=[NSString stringWithFormat:@"%@",responseString];
	}
	if((canceledUpdate==NO) 
	   && ([newest floatValue]>[[[[NSBundle mainBundle] infoDictionary] 
								 objectForKey:kBundleVersionKeyName] floatValue]))	{
		updateReady=[newest floatValue];
	}
	[responseString release];
	[self performSelectorOnMainThread:@selector(checkUpdateDone:)withObject:nil waitUntilDone:NO];
	
    [autoreleasepool drain];
	return YES;
}
 */
/*
- (IBAction) checkforupdates:(id)sender{
	//replaced by sparkle
	return;
	[checkForUpdatesCheckingLabel setStringValue:@"Checking for updates..."];
	[downloadButton setEnabled:NO];
	[updateWindow makeKeyAndOrderFront:self];
	[updatingIndicator startAnimation:self];
	[self performSelectorInBackground:@selector(_docheckupdate:) withObject:self];
	
}*/
/*
- (IBAction) silentupdate:(id)sender{
	//replaced by sparkle
	return;
	//[self performSelectorInBackground:@selector(_docheckupdate:) withObject:self];
}*/
/*
-(IBAction) cancelUpdate:(id)sender{
	updateReady=0.0;
	[self checkUpdateDone:self];
}
 */
- (IBAction) openDownloadPage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kUpdateServerPage]];
}
- (IBAction) openLicencePage:(id)sender{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:kSoftwareLicencePage]];
}
/*
-(void) checkUpdateDone:(id)sender{
	if(updateReady!=0.0){
		[updateWindow makeKeyAndOrderFront:self];
		[checkForUpdatesCheckingLabel setStringValue:[NSString stringWithFormat:
													  @"New version (%0.01f) available for download!",
													  updateReady]];
		[downloadButton setEnabled:YES];
	}else {
		[downloadButton setEnabled:NO];
		[updateWindow close];
	}
	[updatingIndicator stopAnimation:self];
}
*/

-(BOOL) saveToKeyChain:(NSString *)password forUsername:(NSString *)username{
	if([username isEqualToString:@""] || [password isEqualToString:@""]){
		return NO;
	}
	
	
	//FIX THIS
	
	
	/*if(passwordCache){
	 [passwordCache dealloc];
	 passwordCache=nil;
	 }*/
	char * passwordData=(char *)[password UTF8String];
	char * accountName=(char *)[username UTF8String];
	
	
	SecKeychainItemRef itemRef;
	OSStatus err = SecKeychainFindInternetPassword (
													NULL,
													strlen(kKeyChainserverName),
													kKeyChainserverName,
													0,
													NULL,
													strlen(accountName),
													accountName,
													strlen(kKeyChainPath),
													kKeyChainPath,
													kKeyChainPort,
													kSecProtocolTypeHTTPS,
													kSecAuthenticationTypeHTMLForm,
													NULL,
													NULL,
													&itemRef
													);
	if(err==kSecurityErrorNotFound){
		//the keychain item does not exist
		err =  SecKeychainAddInternetPassword (
											   NULL,
											   strlen(kKeyChainserverName),
											   kKeyChainserverName,
											   0,
											   NULL,
											   strlen(accountName),
											   accountName,
											   strlen(kKeyChainPath),
											   kKeyChainPath,
											   kKeyChainPort,
											   kSecProtocolTypeHTTPS,
											   kSecAuthenticationTypeHTMLForm,
											   strlen(passwordData),
											   passwordData,
											   NULL
											   );
		if(err){
			[self showSecurityError:err];
			return NO;
		}
		return YES;
	}
	else if(err){
		[self showSecurityError:err];
	} else if(itemRef) {
		err=SecKeychainItemModifyContent (
										  itemRef,
										  NULL,
										  strlen(passwordData),
										  passwordData
										  );
		if(err){
			[self showSecurityError:err];
			return NO;
		}
		return YES;
		
		
	}
	
	return NO;	
}
- (BOOL) showSecurityError:(OSStatus)err{
	if(err){
		if(err==errKCAuthFailed){
			[self alert:@"Keychain Error: Please allow access to the keychain. The username and password are stored in the keychain."];
		}
		else {
			NSString *msg = (NSString *)SecCopyErrorMessageString(err, NULL);
			[self alert:[NSString stringWithFormat:@"Keychain Error: %@",msg]];
			[msg release];
		}
		return YES;
	}
	return NO;
}
- (NSString *)getPasswordFromKeychainItem:(NSString *)username
{
	if([username isEqualToString:@""]){
		return nil;
	}
	
	UInt32 passwordLength;
	char * passwordData;
	char * accountName=(char *)[username UTF8String];
	
	OSStatus err = SecKeychainFindInternetPassword (
													NULL,
													strlen(kKeyChainserverName),
													kKeyChainserverName,
													0,
													NULL,
													strlen(accountName),
													accountName,
													strlen(kKeyChainPath),
													kKeyChainPath,
													kKeyChainPort,
													kSecProtocolTypeHTTPS,
													kSecAuthenticationTypeHTMLForm,
													&passwordLength,
													(void**)&passwordData,
													NULL
													);
	NSString *password=@"";
	
	
	
	if(err==kSecurityErrorNotFound){
		[self receiveError:@"kSecurityErrorNotFound: Line 431"];
		 [window makeKeyAndOrderFront:self];
		 [userLabel setStringValue:@"<nobody>"];
		 [self showLogin:self];
		
		return nil;
		//the keychain item does not exist
	}
	else if(err){
		[self showSecurityError:err];
		//September 5 10:41
		return nil;
		
	} else {
		if(passwordData){
			/*
			 
			 This code is wrong because passwordData is not null terminated!
			password=[NSString stringWithUTF8String:passwordData];
			if(password==nil){
				
				[self receiveError:@"Using deprecated stringWithCString instead of stringWithUTF8String. Will continue anyway."];
				password=[NSString stringWithCString:passwordData];
				if(password==nil){
					[self receiveError:@"NSString stringWithCString is nil. line 451"];
					
					[self receiveError:[NSString stringWithFormat:@"NSString stringWithCString is nil! line 453. password @ %d, passwordData @ %d. Will attempt to display passwordData with percent s.",password,passwordData]];
					[self receiveError:[NSString stringWithFormat:@"passwordData: %s",passwordData]];
					
				}
			}
			 */
			NSString *releaseme=[[NSString alloc] initWithBytes:passwordData length:passwordLength encoding:NSUTF8StringEncoding];
			
			password=[NSString stringWithString:releaseme];
			[releaseme release];
			
			SecKeychainItemFreeContent(NULL,passwordData);
		}
	}
	//passwordCache=[[NSString stringWithString:password] retain];
	return password;	
}
- (NSString *) getPasswordForUsername:(NSString *)username{
	if(username==nil){
		return nil;
	}
	NSString *password=nil;
	if([[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameDoNotSave]==YES){
		password=password_non_keychain;
	}
	else {
		password=[self getPasswordFromKeychainItem:username];
	}
	
	if([password isEqualToString:@""]){
		return nil;
	}
	return password;
}

- (NSString *) getUsername{
	NSString *username=[[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
	if(username==nil){
		username=@"";
	}
	if([username isEqualToString:@""]){
		[self receiveError:@"Please Login"];
		return nil;
	}
	return username;
}
/*
- (NSString *) getCommandLine{
	NSString *username=nil;
	NSString *password=nil;
	
	username=[[NSUserDefaults standardUserDefaults] stringForKey:kPreferenceKeyNameUsername];
	if(username==nil){
		return nil;
	}
	if([username isEqualToString:@""]){
		return nil;
	}
	if([[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameDoNotSave]==YES){
		password=password_non_keychain;
	}
	else {
		password=[self getPasswordFromKeychainItem:username];
	}
	
	if([password isEqualToString:@""]){
		return nil;
	}
	
	return [NSString stringWithFormat:
			@"%@ %@ %@",
			kBigpondConnect,
			username,
			[password stringByReplacingOccurrencesOfString:@" " withString:@"\\ "]
			];
}
 */
- (IBAction) receiveError:(NSString *)errorString{
	
	/*
	 @"Could Not Connect"
	 @"No Response"
	 @"Wrong Password"
	 @"No Data" //ignore
	 @"Empty Reply"  //ignore
	 @"Error code"  //ignore
	 @"Account Locked for 20 mins"
	 @"Wrong Response" //ignore
	 @"ERR%@"
	 
	 */
	if(debugMode){
		NSLog(@"\"%@\"",errorString);
	}
	NSString *error = [[errorString stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""];
	
	[statusItem setImage:[NSImage imageNamed:kImageResourceFailIcon]];
	if([error isEqualToString:@"Please Login"]){
		[window makeKeyAndOrderFront:self];
		[userLabel setStringValue:@"<nobody>"];
		[self showLogin:self];
	}else if([error isEqualToString:@"Could Not Connect"]){
		[statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
	}
	else if([error isEqualToString:@"Wrong Password"]){
		[window makeKeyAndOrderFront:self];
		//stop timer
		[updateTimer invalidate];
		[self showLogin:self];
	}else if([error isEqualToString:@"Account Locked for 20 mins"]){
		[window makeKeyAndOrderFront:self];
		[self alert:
		 @"Your BigPond Account has been locked from accessing your usage data for 20 minutes after several unsuccessful password attempts."];
	} else {
		[self alert:[NSString stringWithFormat:
					 @"An unexpected error occured. %@",error]];
	}
	[self setStatusText:@""];
	
	[freeLabel setStringValue:@""];
	[usedLabel setStringValue:[NSString stringWithFormat:@"Error: %@",error]];
	
}
- (BOOL) alert:(NSString *)message{
	
	//return NO;
	[window makeKeyAndOrderFront:self];
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	//[[self window] setAlphaValue:1.0];
	[alert addButtonWithTitle:@"OK"];
	[alert setMessageText:message];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self 
					 didEndSelector:nil 
						contextInfo:nil];
	return true;
}

UsageMeter *meter;
- (usageInfo) getInfoInternal{
	
	// NO MEMORY LEAKS!!!
	
	usageInfo new;
	
	new.download=0;
	new.upload=0;
	new.unmetered=0;
	new.usage=0;
	new.time=0;
	
	NSString *username=[self getUsername];
	if(username==nil){
		
		return new;
	}
	NSString *password=[self getPasswordForUsername:username];
	if(password==nil){
		
		if(debugMode){
			NSLog(@"Password was equal to nil");
		}
		return new;
	}
	
	NSString *txt=[meter refresh:username withPassword:password];
	if(![txt isEqualToString:@""])
	{
		[self receiveError:txt];
		return new;
	}
	new.time=time(0);
	new.usage=[meter usageMB];
	new.download=[meter bandwMB];
	unsigned long nnn=[meter billpday];
	currentmonthpercent=100.0*(double)nnn/(double)30;
	
	return new;
	
	
}

- (usageInfo) getInfo{
	
	return [self getInfoInternal];
	/*
	usageInfo new;
	
	new.download=0;
	new.upload=0;
	new.unmetered=0;
	new.usage=0;
	new.time=time(0);
	
	NSString* cmdline=[self getCommandLine];	
	if(cmdline==nil)
	{
		NSString * errorString;
		[self receiveError:errorString];
		new.time=0;
		return new;
	}
	
	FILE *s=popen([cmdline UTF8String],"r");
	char line[512];
	line[512]=0;
	line[0]=0;
	int lineid=0;
	
	int good=1;
	if(s){
		while ( (lineid < 4) && (fgets( line, sizeof line, s)))	{
			if(!good){
				break;
			}
			unsigned long long nnn;
			switch (lineid) {
				case 0:
					if(line[0]<48 || line[0]>57){
						good=0;
					}
					sscanf(line, "%llu",&new.usage);
					break;
				case 1:
					sscanf(line, "%llu",&new.download);
					break;
				case 3:
					sscanf(line, "%llu",&nnn);
					
					currentmonthpercent=100.0*(double)nnn/(double)30;
					break;
				default:
					break;
			}
			lineid++;
		}
		
		
		pclose(s);
	}else {
		good=0;
	}
	
	if(!good){
		if(line[0]==0){
			[self receiveError:@"Could Not Start Process"];
		}else {
			[self receiveError:[NSString stringWithUTF8String:line]];
		}
		
		new.time=0;//this signals that the entry is invalid.
		return new;
	}
	return new;
	 */
}
- (BOOL) _doupdate:(id)sender{
	//do not call this function directly, call update;
	
	NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
	usageInfo justthen=[self getInfo];
    [autoreleasepool drain];
	
	if(justthen.time){
		newest=justthen;
		[self performSelectorOnMainThread:@selector(workDone:)withObject:nil waitUntilDone:NO];
	}else {
		[self performSelectorOnMainThread:@selector(workFailed:)withObject:nil waitUntilDone:NO];
	}
	
	return YES;
}
- (IBAction) setPreferenceUpdatePeriod:(id)sender{
	[[NSUserDefaults standardUserDefaults]
	 setInteger:[updatePeriodPopUp indexOfSelectedItem]
	 forKey:kPreferenceKeyNamePeriod];
	
	[updateTimer invalidate];
	[self configureTimer];
	/*updateTimer=[[NSTimer scheduledTimerWithTimeInterval:[self getTimerPeriodInSeconds]
	 target: self
	 selector: @selector(update:)
	 userInfo: nil
	 repeats: YES] retain];*/
}
- (IBAction) update:(id)sender{
	if(!inConnection){
		if(![updateTimer isValid]){
			
			//[updateTimer dealloc];
			[self configureTimer];			
			/*updateTimer=[[NSTimer scheduledTimerWithTimeInterval: [self getTimerPeriodInSeconds]
			 target: self
			 selector: @selector(update:)
			 userInfo: nil
			 repeats: YES] retain];*/
		}
		[updateMenuItem setTitle:@"Updating..."];
		[updateMenuItem setEnabled:NO];
		inConnection=YES;
		[progressIndicator startAnimation:self];
		[self performSelectorInBackground:@selector(_doupdate:) withObject:self];
	}
}

- (IBAction)complete:(id)sender{
    [loginWindow orderOut:nil];
    [NSApp endSheet:loginWindow];
	NSString* login_username=[usernameField stringValue];
	[userLabel setStringValue:login_username];
	NSString* login_password=[passwordField stringValue];
	if(![login_password isEqualToString:@""] && ![login_username isEqualToString:@""]){
		[[NSUserDefaults standardUserDefaults] 
		 setBool:([savePasswordCheckBox state]==NSOffState) 
		 forKey:kPreferenceKeyNameDoNotSave];
		
		if([[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameDoNotSave]==YES){
			//Do not save the password in the keychain.
			password_non_keychain=login_password;
			
		}else {
			password_non_keychain=@"";
			[self saveToKeyChain:login_password forUsername:login_username];
		}
		[[NSUserDefaults standardUserDefaults] setValue:login_username forKey:kPreferenceKeyNameUsername];
		[self update:self];
	}else {
		[self showLogin:self];
	}
	[statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
}

- (IBAction)cancelOperation:(id)sender{
    [loginWindow orderOut:nil];
    [NSApp endSheet:loginWindow];
}


-(IBAction) cancelDialog:(id)sender{
	
}
-(IBAction) showLogin:(id)sender
{
	NSString* SettingUsernameOrEmailAccountForBigpondLogin=[[NSUserDefaults standardUserDefaults] 
															stringForKey:kPreferenceKeyNameUsername];
	if(SettingUsernameOrEmailAccountForBigpondLogin==NULL){
		SettingUsernameOrEmailAccountForBigpondLogin=@"";
	}
	
	[savePasswordCheckBox setState:([[NSUserDefaults standardUserDefaults]
									 boolForKey:kPreferenceKeyNameDoNotSave]?NSOffState:NSOnState)];
	[usernameField setStringValue:SettingUsernameOrEmailAccountForBigpondLogin];
	[passwordField setStringValue:@""];
	
	[NSApp beginSheet:loginWindow modalForWindow:window modalDelegate:self
	   didEndSelector:NULL contextInfo:nil];
	[loginWindow makeFirstResponder:usernameField];
}
NSString *statusItemText=nil;
-(void) setStatusText:(NSString *)text{
	if([[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceKeyNameShow]==kShowModeIconOnly){
		[statusItem setTitle:@""];
	}else {
		[statusItem setTitle:text];
	}
	
}
- (IBAction) setShowModeIconOnly:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:kShowModeIconOnly forKey:kPreferenceKeyNameShow];
	[setShowModeIconOnlyButton setState:NSOnState];
	[setShowModePercentageButton setState:NSOffState];
	[self setStatusText:@""];
}
- (IBAction) setShowModePercentage:(id)sender{
	[[NSUserDefaults standardUserDefaults] setInteger:kShowModePercentage forKey:kPreferenceKeyNameShow];
	[setShowModeIconOnlyButton setState:NSOffState];
	[setShowModePercentageButton setState:NSOnState];
	[self setStatusText:[NSString stringWithFormat:@"%d%%",percentage ]];
}

-(void) workFailed:(id)sender{
	inConnection=NO;
	[progressIndicator stopAnimation:self];
	[updateMenuItem setTitle:[NSString stringWithFormat:@"Update - Last Update Failed"]];
	[updateMenuItem setEnabled:YES];
}
-(void) configureTimer{
	//int interval=[self getTimerPeriodInSeconds];
	[updateTimer invalidate];
	[updateTimer release];
	updateTimer=[[NSTimer scheduledTimerWithTimeInterval: [self getTimerPeriodInSeconds]
												  target: self
												selector: @selector(update:)
												userInfo: nil
		  										 repeats: YES] retain];
	
	
	/*
	 [updateTimer initWithFireDate:[NSDate dateWithTimeIntervalSinceNow: 60.0]
	 interval:interval
	 target:self
	 selector:@selector(update:)
	 userInfo:nil
	 repeats:YES];
	 */
}
-(void) workDone:(id)sender
{
	if(newest.download){
		[usedMeter setDoubleValue:(double)(newest.usage*100)/(double)newest.download];
		[timeMeter setDoubleValue:(double)(currentmonthpercent)];
		[usedLabel setStringValue:[NSString stringWithFormat:
								   @"%d MB (%d%%)",
								   newest.usage,
								   (int)(round(100.0*newest.usage/(double)newest.download))]];
		
		//Memory Leak
		percentage = (round(100.0*(double)newest.usage/(double)newest.download));
		[self setStatusText:[NSString stringWithFormat:@"%d%%",percentage]];
		
		[percentOfMonthLabel setStringValue:[NSString stringWithFormat:@"%d%%",(int)(currentmonthpercent)]];
		double ccurrentmonthpercent=currentmonthpercent;
		[timeLabel setStringValue:[NSString stringWithFormat:
								   @"%dd remain",
								   (signed int)(30.0-(ccurrentmonthpercent*30.0/100.0))]];
		
		[freeLabel setStringValue:[NSString stringWithFormat:@"Free: %d MB",
								   (int)((double)newest.download-(double)newest.usage)]];
	}
	[statusItem setImage:[NSImage imageNamed:kImageResourceDefaultIcon]];
	[progressIndicator stopAnimation:self];
	inConnection=NO;
	[updateMenuItem setTitle:[NSString stringWithFormat:@"Update Now - Last updated: %@",[self timeString]]];
	[updateMenuItem setEnabled:YES];
}
/*
- (void) itIsTimeToCheckForUpdatesNow: (NSTimer *) timer{
	[self silentupdate:self];
}
 */

- (int) getTimerPeriodInSeconds{
	
	int SetttingUpdatePeriodIndexSetting=[[NSUserDefaults standardUserDefaults] integerForKey:kPreferenceKeyNamePeriod];
	switch (SetttingUpdatePeriodIndexSetting) {
		case 0:
			return 20 MINUTES;
		case 1:
			return 30 MINUTES;
		case 2:
			return 60 MINUTES;
		case 3:
			return 128 MINUTES;
		default:
			return 30 MINUTES;
	}
}
- (void) setup
{
	
	meter= [[UsageMeter alloc] init];
	
	[self loadPreferences:self];
	
	//set timer to check for updates.
	/*
	if([[NSUserDefaults standardUserDefaults] boolForKey:kPreferenceKeyNameUpdate]){
		
		
		[NSTimer scheduledTimerWithTimeInterval: 5 MINUTES
										 target: self
									   selector: @selector(itIsTimeToCheckForUpdatesNow:)
									   userInfo: nil
										repeats: NO];
	}
	*/
	updateTimer=[[NSTimer scheduledTimerWithTimeInterval: [self getTimerPeriodInSeconds]
												  target: self
												selector: @selector(update:)
												userInfo: nil
		  										 repeats: YES] retain];
	
	//TODO: Check if ready. ie first run
	
	[self update:self];
	
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	[self setup];
}

-(void)awakeFromNib{
	kBigpondConnect=[[[NSString stringWithFormat:
					   @"%@/Contents/Resources/bigpondconnect",
					   [self getApplicationFilePath]] stringByReplacingOccurrencesOfString:@" " withString:@"\\ "] retain];
	//[self alert:kBigpondConnect];
	
	newest.download=newest.upload=newest.unmetered=newest.usage=newest.time=0;
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength] retain];
	[statusItem setMenu:statusMenu];
	[self setStatusText:@""];
	[statusItem setImage:[NSImage imageNamed:kImageResourceFadedIcon]];
	[statusItem setHighlightMode:YES];

}
@end
