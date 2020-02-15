/*
 *  mirror.m
 *  mirror
 *
 *  Created by Fabian Canas on 2/4/09.
 *  Copyright 2009-2018 Fabián Cañas. All rights reserved.
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
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSUInteger, MirrorAction) {
    help,
    on,
    off,
    toggle,
    query,
    linkDiplays,
};

MirrorAction getAction(int *masterIndex, int *slaveIndex)
{
    NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
    MirrorAction action = toggle;

    for (int idx = 0; idx < args.count; idx++) {
        NSString *arg = args[idx];
        if ([arg isEqualToString:@"-h"]){
            action = help;
            break;
        }
        if ([arg isEqualToString:@"-t"]){
            action = toggle;
            break;
        }
        if ([arg isEqualToString:@"-on"]){
            action = on;
            break;
        }
        if ([arg isEqualToString:@"-off"]){
            action = off;
            break;
        }
        if ([arg isEqualToString:@"-q"]){
            action = query;
            break;
        }
        if ([arg isEqualToString:@"-l"]) {
            if (args.count < idx + 2) {
                break;
            }
            NSString *masterIndexString = args[idx + 1];
            NSString *slaveIndexString = args[idx + 2];
            if (masterIndex != NULL) {
                *masterIndex = [masterIndexString intValue];
            }
            if (slaveIndex != NULL) {
                *slaveIndex = [slaveIndexString intValue];
            }
            action = linkDiplays;
            break;
        }
    }

    return action;
}

#define MAX_DISPLAYS 10
#define SECONDARY_DISPLAY_COUNT 9

static CGDisplayCount numberOfTotalDspys = MAX_DISPLAYS;

static CGDirectDisplayID activeDspys[MAX_DISPLAYS];
static CGDirectDisplayID onlineDspys[MAX_DISPLAYS];
static CGDirectDisplayID secondaryDspys[SECONDARY_DISPLAY_COUNT];

CGError multiConfigureDisplays(CGDisplayConfigRef configRef, CGDirectDisplayID *secondaryDspys, int count, CGDirectDisplayID master) {
    CGError error = kCGErrorSuccess;
    for (int i = 0; i<count; i++) {
        error = error ?: CGConfigureDisplayMirrorOfDisplay(configRef, secondaryDspys[i], master);
    }
    return error;
}

int main (int argc, const char * argv[]) {
    int masterIndex, slaveIndex;
    MirrorAction action = getAction(&masterIndex, &slaveIndex);
    
    if (action == help){
        printf("Mirror Displays version 1.2.1\nCopyright 2009-2020, Fabián Cañas\n");
        printf("usage: mirror [option]\n\n");
        printf("Only the first option passed will be applied\n");
        printf("\n  -h\t\tPrint this usage and exit.");
        printf("\n  -t\t\tToggle mirroring (default behavior)");
        printf("\n  -on\t\tTurn Mirroring On");
        printf("\n  -off\t\tTurn Mirroring Off");
        printf("\n  -q\t\tQuery the Mirroring state and write \"on\" or \"off\" to stdout");
        printf("\n  -l A B\t Makes display at index B mirror the display at index A");
        printf("\n");
        return 0;
    }
    
    CGDisplayCount numberOfActiveDspys;
    CGDisplayCount numberOfOnlineDspys;
    
    CGDisplayErr activeError = CGGetActiveDisplayList(numberOfTotalDspys,activeDspys,&numberOfActiveDspys);
    
    if (activeError!=0) {
        printf("Error in obtaining active diplay list: %d\n",activeError);
        return activeError;
    }

    CGDisplayErr onlineError = CGGetOnlineDisplayList (numberOfTotalDspys,onlineDspys,&numberOfOnlineDspys);
    
    if (onlineError!=0) {
        printf("Error in obtaining online diplay list: %d\n",onlineError);
        return onlineError;
    }
    
    if (numberOfOnlineDspys<2) {
        printf("No secondary display detected.\n");
        return 1;
    }
    
    bool displaysMirrored = CGDisplayIsInMirrorSet(CGMainDisplayID());
    int secondaryDisplayIndex = 0;
    for (int displayIndex = 0; displayIndex<numberOfOnlineDspys; displayIndex++) {
        if (onlineDspys[displayIndex] != CGMainDisplayID()) {
            secondaryDspys[secondaryDisplayIndex] = onlineDspys[displayIndex];
            secondaryDisplayIndex++;
        }
    }

    if (action == toggle) {
        if (displaysMirrored) {
            action = off;
        } else {
            action = on;
        }
    }

    CGDisplayConfigRef configRef;
    CGError err = CGBeginDisplayConfiguration (&configRef);
    if (err != 0) {
        printf("Error with CGBeginDisplayConfiguration: %d\n",err);
        return err;
    }

    switch (action) {
        case on:
            err = multiConfigureDisplays(configRef, secondaryDspys, numberOfOnlineDspys - 1, CGMainDisplayID());
            break;
        case off:
            err = multiConfigureDisplays(configRef, secondaryDspys, numberOfOnlineDspys - 1, kCGNullDirectDisplay);
            break;
        case query:
            if (displaysMirrored) {
                printf("on\n");
            } else {
                printf("off\n");
            }
            break;
        case linkDiplays:
            if (numberOfOnlineDspys <= masterIndex) {
                printf("Index of specified master display out of bounds\n");
                return 1;
            }
            if (numberOfOnlineDspys <= slaveIndex) {
                printf("Index of slave display out of bounds\n");
                return 1;
            }
            err = CGConfigureDisplayMirrorOfDisplay(configRef, onlineDspys[slaveIndex], onlineDspys[masterIndex]);
            break;
        default:
            break;
    }
    if (err != 0) printf("Error configuring displays: %d\n",err);
    
    // Apply the changes
    err = CGCompleteDisplayConfiguration (configRef,kCGConfigurePermanently);
    if (err != 0) printf("Error applying configuration: %d\n",err);
    
    return err;
}
