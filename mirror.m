/*
 *  mirror.m
 *  mirror
 *
 *  Created by Fabian Canas on 2/4/09.
 *  Copyright 2009 Fabián Cañas. All rights reserved.
 *
 *  This program is free software: you can redistribute it and/or modify	
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *  
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>

int main (int argc, const char * argv[]) {
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSArray *args = [[NSProcessInfo processInfo] arguments];
    NSCountedSet *cset = [[NSCountedSet alloc] initWithArray:args];
    NSArray *sorted_args = [[cset allObjects]
							sortedArrayUsingSelector:@selector(compare:)];
    NSEnumerator *enm = [sorted_args objectEnumerator];
    id word;
	
	enum MirrorMode {
		help,
		on,
		off,
		toggle,
		query
	} mode;
	
	mode = toggle;
	
    while (word = [enm nextObject]) {
//        printf("%s\n", [word UTF8String]);
		if (strcmp([word UTF8String], "-h")==0){
			mode = help;
			break;
		}
		if (strcmp([word UTF8String], "-t")==0){
			mode = toggle;
			break;
		}
		if (strcmp([word UTF8String], "-on")==0){
			mode = on;
			break;
		}
		if (strcmp([word UTF8String], "-off")==0){
			mode = off;
			break;
		}
		if (strcmp([word UTF8String], "-q")==0){
			mode = query;
			break;
		}
    }
    [cset release];
	[pool drain];
	// Ending Objective-C code. Don't need a pool anymore?
	if (mode == help){
		printf("Mirror Displays version 1.03\nCopyright 2009, Fabián Cañas\n");
		printf("usage: mirror [option]\tPassing more than one option produces undefined behavior.");
		printf("\n  -h\t\tPrint this usage and exit.");
		printf("\n  -t\t\tToggle mirroring (default behavior)");
		printf("\n  -on\t\tTurn Mirroring On");
		printf("\n  -off\t\tTurn Mirroring Off");
		printf("\n  -q\t\tQuery the Mirroring state and write \"on\" or \"off\" to stdout");
		printf("\n");
		return 0;
	}
	
	CGDisplayCount numberOfActiveDspys;
	CGDisplayCount numberOfOnlineDspys;
	
	CGDisplayCount numberOfTotalDspys = 2; // The number of total displays I'm interested in
	
	CGDirectDisplayID activeDspys[] = {0,0};
	CGDirectDisplayID onlineDspys[] = {0,0};
	CGDirectDisplayID secondaryDspy;
	
	CGDisplayErr activeError = CGGetActiveDisplayList (numberOfTotalDspys,activeDspys,&numberOfActiveDspys);
	
	if (activeError!=0) NSLog(@"Error in obtaining active diplay list: %d\n",activeError);
	
	CGDisplayErr onlineError = CGGetOnlineDisplayList (numberOfTotalDspys,onlineDspys,&numberOfOnlineDspys);
	
	if (onlineError!=0) NSLog(@"Error in obtaining online diplay list: %d\n",onlineError);
	
	if (numberOfOnlineDspys==2) { // Right now we're only dealing with two available monitors
		
		if (onlineDspys[0]==CGMainDisplayID()){
			secondaryDspy = onlineDspys[1];
		} else {
			secondaryDspy = onlineDspys[0];
		}
		
		CGDisplayConfigRef configRef;
		CGError err = CGBeginDisplayConfiguration (&configRef);
		if (err != 0) NSLog(@"Error with CGBeginDisplayConfiguration: %d\n",err);
		// Experimental Code for changing the color and timing for the fade effect.
		//CGError fadeChangeError;
		//fadeChangeError = CGConfigureDisplayFadeEffect (configRef,1.5,1.5,0.0,0.0,0.0);
		//if (fadeChangeError!= 0) NSLog(@"Error with CGConfigureDisplayFadeEffect %d\n",fadeChangeError);
		
		switch (mode) {
			case toggle:
				if (numberOfActiveDspys==2) { // Displays are unmirrored -> mirror them
					err = CGConfigureDisplayMirrorOfDisplay (configRef,secondaryDspy,CGMainDisplayID());
				} else { // Displays are mirrored -> unmirror them
					err = CGConfigureDisplayMirrorOfDisplay (configRef,secondaryDspy,kCGNullDirectDisplay);
				}
				break;
			case on:
				if (numberOfActiveDspys==2)
					err = CGConfigureDisplayMirrorOfDisplay (configRef,secondaryDspy,CGMainDisplayID());
				//else return 0;
				break;
			case off:
				if (numberOfActiveDspys!=2)
					err = CGConfigureDisplayMirrorOfDisplay (configRef,secondaryDspy,kCGNullDirectDisplay);
				//else return 0;
				break;
			case query:
				if (numberOfActiveDspys==2) { // Displays are unmirrored
					printf("off\n");
				} else { // Displays are mirrored
					printf("on\n");
				}
				break;
			default:
				break;
		}
		if (err != 0) NSLog(@"Error with the switch commands!: %d\n",err);
		
		// Apply the changes
		err = CGCompleteDisplayConfiguration (configRef,kCGConfigurePermanently);
		if (err != 0) NSLog(@"Error with CGCompleteDisplayConfiguration: %d\n",err);
	} else {
    if (numberOfOnlineDspys>2) {
      printf("Cannot handle more than 2 displays at this time. %d displays detected.\n",numberOfOnlineDspys);
    } else {
      printf("No secondary display detected.\n");
    }
  }

	
    return 0;	
}
