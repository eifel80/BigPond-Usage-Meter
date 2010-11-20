#import "UsageMeter.h"
/*----------
 The code is a mess, but I will try to explain :)
 
 These are the string functions used:
 
 * NSMakeRange(location,length)
 
 * newstring=[mystring stringByReplacingOccurrencesOfString:@"x" withString:"y"];
 
 * newstring=[mystring substringWithRange:NSMakeRange(myrange)];
 
 
 
 
 basically, it downloads
 "https://signon.bigpond.com/login?goto=https%3A%2F%2Fmy.bigpond.com%3A443%2Fmybigpond%2Fmyaccount%2Fmyusage%2Fdaily%2Fdefault.do"
 
 And you send a 'POST' with the following url encoded data.
 
 username=myusername@bigpond.com
 password=thepassword
 goto, this should equal the same as the GET goto.
 encoded=false (i don't know what this is)
 gx_charset=UTF-8
 
 
 
 remember to urlencode/escapeURIComponent, and set the "Content-Type" header to "application/x-www-form-urlencoded"
 An example of a correctly encoded value would be:
 
 "username=myusername@bigpond.net.au&password=mypassword&goto=https%3A%2F%2Fmy.bigpond.com%3A443%2Fmybigpond%2Fmyaccount%2Fmyusage%2Fdaily%2Fdefault.do&encoded=false&gx_charset=UTF-8"
 
 
 
 the server returns the usage meter page. I think that Mac OS X automatically handles http redirects. BTW, XmlHTTPRequest automatically handles them too.
 
 
 Cookies are automattically handled, but I wrote some code to handle them myself, which is useless, but I left it in there anyway
 just incase it ever fails to recognise a cookie anyway.
 
 --------------------------------------------------------------------------------
 So when data is ready, it just scans through the html.
 
 There are two different usage meter pages, this works with both types. There is a slightly different usage meter page for some wireless customers, this works for that too. 
 
 
 and also, the bigpond site has some encoding errors, which don't stuff this program up anymore.
 The site says latin encoding if you don't handle the cookies correctly.
 The encoding on that page confuses me.
 
 
 */

@implementation UsageMeter

unsigned long _dayss=0;
unsigned long _used,_total;
unsigned long billingstart=0;



NSMutableArray *js_used, *js_date,*js_unmetered,*js_upload,*js_download;
#ifdef JSON
#warning Compiling with JSON
- (int) printjson {
	NSEnumerator * nenumerator = [js_date objectEnumerator];
	NSString *datee;
	printf("{\"date\":[");
	int first=0; //IMPORTANT: if it is the first time then first is = 0
	while(datee = [nenumerator nextObject])	{
		if(first){printf(",");}first=1;
		printf("\"%s\"",[datee cString]);
	}
	nenumerator = [js_used objectEnumerator];
	
	printf("],\"used\":[");
	first=0;
	while(datee = [nenumerator nextObject])	{
		if(first){printf(",");}first=1;
		printf("%s",[datee cString]);
	}
	nenumerator = [js_download objectEnumerator];
	
	printf("],\"download\":[");first=0;
	while(datee = [nenumerator nextObject])	{
		if(first){printf(",");}first=1;
		printf("%s",[datee cString]);
	}
	
	printf("],\"upload\":[");first=0;
	nenumerator = [js_upload objectEnumerator];
	while(datee = [nenumerator nextObject])	{
		if(first){printf(",");}first=1;
		printf("%s",[datee cString]);
		
	}
	nenumerator = [js_unmetered objectEnumerator];
	
	printf("],\"unmetered\":[");first=0;
	while(datee = [nenumerator nextObject])	{
		if(first){printf(",");}first=1;
		printf("%s",[datee cString]);
	}
	printf("]}");
	return 0;
}
#else


- (int) printjson {
	NSLog(@"JSON requested when compiled without #JSON");
	return 0;
}
#endif
- (NSString *) refresh:(NSString*)username withPassword:(NSString*)password{
	
	NSString * data;
	

	@try{

		if([username isEqualToString:@"example@bigpond.com"]){
			return @"Please Login";
		}
		NSString	*cookiealls=NULL;
		NSString	*post;
		NSData		*postData;
		
		
		int usecookie=0;
	tryagainbutthisisslower:
		
		post = [NSString stringWithFormat:@"username=%@&password=%@&goto=%@&encoded=false&gx_charset=UTF-8",
				[username stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
				[password stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
				//https://usagemeter.bigpond.com/daily.do
				[@"https://usagemeter.bigpond.com/daily.do" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
				//[@"https://my.bigpond.com:443/mybigpond/myaccount/myusage/daily/default.do" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
		
		postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
		NSString	*postLength = [NSString stringWithFormat:@"%d", [postData length]];
		NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
		
		
		//[request setURL:[NSURL URLWithString:@"https://signon.bigpond.com/login?goto=https%3A%2F%2Fmy.bigpond.com%3A443%2Fmybigpond%2Fmyaccount%2Fmyusage%2Fdaily%2Fdefault.do"]];
		//https://usagemeter.bigpond.com/daily.do
		[request setURL:[NSURL URLWithString:@"https://signon.bigpond.com/login?goto=https%3A%2F%2Fusagemeter.bigpond.com%3A443%2Fdaily.do"]];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10 UsageMeterDataUpdater/1.1" forHTTPHeaderField:@"User-Agent"];
		[request setHTTPShouldHandleCookies:YES];
		
		if((usecookie)) {
			[request setValue:cookiealls forHTTPHeaderField:@"Cookie"];
		}
		
		[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
		[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
		[request setHTTPBody:postData];
		
		//NSURLResponse *resp = nil;
		NSHTTPURLResponse *resp=nil;
		NSError *err = nil;
		
		NSData *response = [NSURLConnection sendSynchronousRequest: request returningResponse: &resp error: &err];
		if(!response){
			return @"Could Not Connect";
		}
		if(!resp){
			return @"No Response";
		}
		unsigned int dataloaded=0;	
		if([resp textEncodingName])	{			
			if([[resp textEncodingName] isEqualToString:@"iso-8859-1"])
			{
				//Wrong Password ?
				data = [[NSString alloc] initWithData:response encoding:NSISOLatin1StringEncoding];
				dataloaded=1;
				NSRange cfoundRange = [data rangeOfString:@"Your username/password combination is incorrect or incomplete"];
				
				if(cfoundRange.location != NSNotFound) {
					[data release];
					return @"Wrong Password";
				}
			}
		}
		if(!dataloaded){
			data = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
			dataloaded=1;
		}
		
		//Debug mode
		//[data release];
		//data = [[NSString alloc] initWithContentsOfFile:@"/debug/new.html"];
		
		if(!data){
			return @"No Data";
		}
		if([data length]==0){
			[data release];
			return @"Empty Reply";
		}
		if([err code]){
			[data release];
			return @"Error code";}
		
		NSRange index;
		NSString *all;
		NSString *b;
		
		unsigned long iused=0;
		unsigned long itotoal=0;
		unsigned long ibillstart=0;
		
		NSRange foundRange = [data rangeOfString:@"Account Locked</h1>"];
		if(foundRange.location != NSNotFound) {
			[data release];
			return @"Account Locked for 20 mins";
		}
		foundRange = [data rangeOfString:@"<td nowrap=\"nowrap\" style=\"vertical-align:bottom\">Current Usage Allowance:</td>"];
		if (foundRange.location == NSNotFound)
		{
			foundRange = [data rangeOfString:@"<title>503 Service Temporarily Unavailable</title>"];
			if (foundRange.location != NSNotFound)
			{
				[data release];
				return @"Service Temporarily Unavailable";
				
			}
			//New usage meter page (16 Nov 2010)
			foundRange = [data rangeOfString:@"<th>Monthly Plan Allowance:</th><td>"];
			NSString *top;
			NSString *bacctype;
			NSString *acctype;
			
			
			top=[data substringFromIndex:foundRange.location+foundRange.length];
			acctype = [top substringToIndex:[top rangeOfString:@"B"].location];
			
			bacctype=acctype;
			acctype=[[[bacctype stringByReplacingOccurrencesOfString:@"T" withString:@"000000"] stringByReplacingOccurrencesOfString:@"G" withString:@"000"] stringByReplacingOccurrencesOfString:@"M" withString:@""];
			
			//itotoal: Monthly Plan Allowance. (MB)
			itotoal=[[acctype stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
		
			//NSRange table_begin=[top rangeOfString:@"<table class=\"usage bottom_margin\">"]; (there is rubbish around here)
			NSRange table_begin=[top rangeOfString:@"</thead>"];
			NSRange table_end = [top rangeOfString:@"<div  id=\"usagenotes\" class=\"content terms\">" options:NSLiteralSearch range:NSMakeRange(table_begin.location, [top length]-table_begin.location)];
			NSString * table=[top substringWithRange:NSMakeRange(table_begin.location, table_end.location-table_begin.location)];
			
		
			
#ifdef JSON
			
			if(0){//THIS CODE WILL NOT WORK
				  //It has not been updated. table, can be splitted into rows by "<tr" however. I think the first entry will be nothing.
				
				
				
			NSArray * days = [table componentsSeparatedByString:@"<tr"];
			
			NSEnumerator * nenumerator = [days objectEnumerator];
			NSString *today;
			
			js_used=[[NSMutableArray alloc] init];
			js_date=[[NSMutableArray alloc] init];
			js_unmetered=[[NSMutableArray alloc] init];
			js_upload=[[NSMutableArray alloc] init];
			js_download=[[NSMutableArray alloc] init];
			unsigned long dc=0;
			while(today = [nenumerator nextObject]){
				if((!dayv2) || (dayv2 && (dc>1)))
				{
					NSRange rr=[today rangeOfString:@"<td"];
					if(rr.length==0){
						break;
					}
					
					NSString *_ta = [today substringFromIndex:rr.location];
					_ta = [_ta substringFromIndex:[_ta rangeOfString:@">"].location+1];
					NSArray  *_tp = [_ta componentsSeparatedByString:@"<td"];
					NSString *_tn = [[_tp objectAtIndex:0] substringToIndex: ( [[_tp objectAtIndex:0] rangeOfString:@"</"].location  )    ];
					if([_tn isEqualToString:@"<strong>Total"]){
						break;
					}
					[js_date addObject:_tn];
					NSString *toend=[[_tp objectAtIndex:2] substringToIndex: ( [[_tp objectAtIndex:2] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_download addObject:toend];
					toend=[[_tp objectAtIndex:3] substringToIndex: ( [[_tp objectAtIndex:3] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_upload addObject:toend];
					
					toend=[[_tp objectAtIndex:4] substringToIndex: ( [[_tp objectAtIndex:4] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_used addObject:toend];
					
					toend=[[_tp objectAtIndex:5] substringToIndex: ( [[_tp objectAtIndex:5] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_unmetered addObject:toend];
					
				}
				dc++;
			}
			}
#endif
			
			index = [table rangeOfString:@"<th scope=\"row\" class=\"a_left\">"];
			b = [table substringWithRange:NSMakeRange(index.location+index.length, 3)];
			ibillstart=[[b stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
			index=[top rangeOfString:@"<strong class=\"blue\">Total</strong>"];
			int likels=0;
			if(index.length==0){
				likels=1;
				//This code will not work
				index=[top rangeOfString:@"<td class=\"tdLeftNoWrap\"><strong>Total</strong></td>"];
			}
			
			NSString *bused = [top substringWithRange:NSMakeRange(index.location+index.length,200)];
			
			
			//this just skips through to the right column, which is the TOTAL BILLED USAGE,
			int boldfontbegin=[bused rangeOfString:@"<b>"].location+3;
			int boldfontend=[bused rangeOfString:@"</b>"].location;
			bused = [bused substringWithRange:NSMakeRange(boldfontbegin, boldfontend-boldfontbegin)];

			iused=[[bused stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
			
			
			billingstart=ibillstart;
			_used=iused;
			_total=itotoal;
			if(dataloaded){
				[data release];
			}
			return @"";
			
			
			//end new usage meter page
		}
		else {
			
			//old usage meter page. Many people still have this.
			NSString *top;
			NSString *bacctype;
			NSString *acctype;
			
			
			top=[data substringFromIndex:foundRange.location+96];
			bacctype=[top substringWithRange:NSMakeRange([top rangeOfString:@">"].location+1, 50)];
			acctype = [bacctype substringToIndex:[bacctype rangeOfString:@"B"].location];
			
			bacctype=acctype;
			acctype=[[[bacctype stringByReplacingOccurrencesOfString:@"T" withString:@"000000"] stringByReplacingOccurrencesOfString:@"G" withString:@"000"] stringByReplacingOccurrencesOfString:@"M" withString:@""];
			itotoal=[[acctype stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
			index = [top rangeOfString:@"<tr bgcolor=\"#CDE1F1\">"];
			if(index.length==0){
				index = [top rangeOfString:@"onchange=\"this.form.submit();\"><option  selected=\"selected\""];
			}
			all = [top substringFromIndex:index.location+index.length];
			
			NSString * table = [all substringToIndex:[all rangeOfString:@"</table>"].location];
			NSRange st=[table rangeOfString:@"<table"];
			unsigned long dayv2=0;
			if(st.length!=0){
				table=[table substringFromIndex:st.location+6];
				table=[table substringFromIndex:[table rangeOfString:@">"].location+1];
				dayv2=1;
			}
			
#ifdef JSON
			NSArray * days = [table componentsSeparatedByString:@"<tr"];
			
			NSEnumerator * nenumerator = [days objectEnumerator];
			NSString *today;
			
			js_used=[[NSMutableArray alloc] init];
			js_date=[[NSMutableArray alloc] init];
			js_unmetered=[[NSMutableArray alloc] init];
			js_upload=[[NSMutableArray alloc] init];
			js_download=[[NSMutableArray alloc] init];
			unsigned long dc=0;
			while(today = [nenumerator nextObject]){
				if((!dayv2) || (dayv2 && (dc>1)))
				{
					NSRange rr=[today rangeOfString:@"<td"];
					if(rr.length==0){
						break;
					}
					
					NSString *_ta = [today substringFromIndex:rr.location];
					_ta = [_ta substringFromIndex:[_ta rangeOfString:@">"].location+1];
					NSArray  *_tp = [_ta componentsSeparatedByString:@"<td"];
					NSString *_tn = [[_tp objectAtIndex:0] substringToIndex: ( [[_tp objectAtIndex:0] rangeOfString:@"</"].location  )    ];
					if([_tn isEqualToString:@"<strong>Total"]){
						break;
					}
					[js_date addObject:_tn];
					NSString *toend=[[_tp objectAtIndex:2] substringToIndex: ( [[_tp objectAtIndex:2] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_download addObject:toend];
					toend=[[_tp objectAtIndex:3] substringToIndex: ( [[_tp objectAtIndex:3] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_upload addObject:toend];
					
					toend=[[_tp objectAtIndex:4] substringToIndex: ( [[_tp objectAtIndex:4] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_used addObject:toend];
					
					toend=[[_tp objectAtIndex:5] substringToIndex: ( [[_tp objectAtIndex:5] rangeOfString:@"</"].location  )    ];
					toend=[toend substringFromIndex:[toend rangeOfString:@">"].location+1];
					toend=[toend stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
					toend=[toend stringByReplacingOccurrencesOfString:@"-" withString:@"0"];
					[js_unmetered addObject:toend];
					
				}
				dc++;
			}
#endif
			index = [all rangeOfString:@">"];
			b = [all substringWithRange:NSMakeRange(index.location+1, 3)];
			ibillstart=[[b stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
			index=[all rangeOfString:@"<td nowrap=\"nowrap\"><strong>Total</strong></td>"];
			int likels=0;
			if(index.length==0){
				likels=1;
				index=[all rangeOfString:@"<td class=\"tdLeftNoWrap\"><strong>Total</strong></td>"];
			}
			
			NSString *bused = [all substringFromIndex:index.location+index.length];
			
			
			//this just skips through to the right column, which is the TOTAL BILLED USAGE,
			index=[bused rangeOfString:@"<td"];bused = [bused substringFromIndex:index.location+index.length];
			index=[bused rangeOfString:@"<td"];bused = [bused substringFromIndex:index.location+index.length];
			index=[bused rangeOfString:@"<td"];bused = [bused substringFromIndex:index.location+index.length];
			index=[bused rangeOfString:@"<td"];bused = [bused substringWithRange:NSMakeRange(index.location+index.length,50)];
			
			index=[bused rangeOfString:@"</"];
			int x=[bused rangeOfString:@">"].location+1;
			NSString *used = [bused substringWithRange:NSMakeRange(x, index.location-x)];
			used=[used stringByReplacingOccurrencesOfString:@"<strong>" withString:@""];
			iused=[[used stringByReplacingOccurrencesOfString:@" " withString:@""] intValue];
			
			
			billingstart=ibillstart;
			_used=iused;
			_total=itotoal;
			if(dataloaded){
				[data release];
			}
			return @"";
			
		}
	}
	@catch(NSException * theException){
		return [NSString stringWithFormat:@"ERR%@",[theException reason]];
	}
	return NO;
	
}
- (unsigned long) usageMB{return _used;}
- (unsigned long) bandwMB{return _total;}
- (unsigned long) freeMB {return _total-_used;}
- (unsigned long) percent{return (_used*100)/(_total);}
- (unsigned long) daysthismonth{
	//close enough
	return 30;
}
- (unsigned long) billppercent{return ([self billpday]*100)/[self daysthismonth];}
- (unsigned long) dayofmonth{
	NSInteger dayi;
	
	NSCalendar *calendar= [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
	NSCalendarUnit unitFlags = NSDayCalendarUnit;
	NSDateComponents *dateComponents = [calendar components:unitFlags fromDate:[NSDate date]];
	dayi= [dateComponents day];
	[calendar release];
	return dayi;
}
- (unsigned long) billpday{return ([self dayofmonth]+[self daysthismonth]-billingstart)%[self daysthismonth];}
- (unsigned long) billpdaysleft{return [self billpday]-[self daysthismonth];}

@end


/*

old code
*/
 //[request setValue:@"application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5" forHTTPHeaderField:@"Accept"];
//[request setValue:@"en-us" forHTTPHeaderField:@"Accept-Language"];
//[request setValue:@"iso-8859-5, unicode-1-1;q=0.8" forHTTPHeaderField:@"Accept-Charset"];


