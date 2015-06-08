//
//  SLFChamber.m
//  Created by Gregory Combs on 9/3/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "SLFChamber.h"
#import "SLFState.h"

NSString * const SLFChamberUpperType = @"upper";
NSString * const SLFChamberLowerType = @"lower";

@interface SLFChamber()
- (NSString *)getTitleAbbreviation;
@end

@implementation SLFChamber
@synthesize stateID;
@synthesize state;
@synthesize type;
@synthesize term;
@synthesize title;
@synthesize name;
@synthesize shortName;
@synthesize titleAbbreviation;
@synthesize initial;

+ (SLFChamber *)chamberWithType:(NSString *)aType forState:(SLFState *)aState {
    if (aType && [aType isEqualToString:SLFChamberLowerType])
        return [LowerChamber lowerForState:aState];
    else if (aType && [aType isEqualToString:SLFChamberUpperType])
        return [UpperChamber upperForState:aState];
    return nil;
}

- (void)dealloc {
    self.stateID = nil;
    self.state = nil;
    self.type = nil;
    self.term = nil;
    self.title = nil;
    self.name = nil;
    self.initial = nil;
    self.titleAbbreviation = nil;
    [super dealloc];
}

- (SLFChamber *)opposingChamber {
    if (self.state.isUnicameral)
        return nil;
    if ([self isKindOfClass:[UpperChamber class]])
        return [LowerChamber lowerForState:self.state];
    else if ([self isKindOfClass:[LowerChamber class]])
        return [UpperChamber upperForState:self.state];
    return nil;
}

- (NSString *)formalName {
    return [NSString stringWithFormat:@"%@ %@", self.state.name, self.name];
}

- (NSString *)shortName {
    NSArray *words = [self.name componentsSeparatedByString:@" "];
    if ([words count] > 1 && [[words objectAtIndex:0] length] > 4) { // just to make sure we have a decent, single name
        return [words objectAtIndex:0];
    }
    return self.name;
}

- (NSString *)initial {
    if (IsEmpty(initial))
        initial = [[self.name substringToIndex:1] copy];
	return initial;
}

- (NSString *)getTitleAbbreviation {
    if (!self.title)
        return nil;
    return [NSString stringWithFormat:@"%@.", [self.title substringToIndex:3]];
}

+ (NSString *)chamberTypeForSearchScopeIndex:(NSInteger)scopeIndex {
    if (scopeIndex == 1)
        return SLFChamberUpperType;
    else if (scopeIndex == 2)
        return SLFChamberLowerType;
    return nil;
}

+ (NSArray *)chamberSearchScopeTitlesWithState:(SLFState *)state {
    if (!state)
        return nil;
    NSArray *chambers = state.chambers;
    if (state.isUnicameral || IsEmpty(chambers) || [chambers count] < 2)
        return nil; // No point in creating a scope bar if there's only one chamber.
    return [NSArray arrayWithObjects:NSLocalizedString(@"Both",@""), [[chambers objectAtIndex:0] shortName], [[chambers objectAtIndex:1] shortName], nil];
}

- (BOOL)isUpperChamber {
    return NO; // see UpperChamber subclass
}

@end

@implementation UpperChamber
+ (UpperChamber *)upperForState:(SLFState *)aState {
    UpperChamber *chamber = [[[UpperChamber alloc] init] autorelease];
    chamber.type = SLFChamberUpperType;
    chamber.state = aState;
    chamber.stateID = aState.stateID;
    chamber.term = aState.upperChamberTerm;
    chamber.title = aState.upperChamberTitle;
    chamber.name = aState.upperChamberName;
    chamber.titleAbbreviation = [chamber getTitleAbbreviation];
    return chamber;
}

- (NSString *)getTitleAbbreviation {
    if (self.title && [[self.title lowercaseString] hasPrefix:@"council"])
        return NSLocalizedString(@"Cncl.", @"Abbreviation for Councilmember");
    return [super getTitleAbbreviation];
}

- (BOOL)isUpperChamber {
    return YES;
}

@end

@implementation LowerChamber
+ (LowerChamber *)lowerForState:(SLFState *)aState {
    if (aState.isUnicameral)
        return nil;
    LowerChamber *chamber = [[[LowerChamber alloc] init] autorelease];
    chamber.type = SLFChamberLowerType;
    chamber.state = aState;
    chamber.stateID = aState.stateID;
    chamber.term = aState.lowerChamberTerm;
    chamber.title = aState.lowerChamberTitle;
    chamber.name = aState.lowerChamberName;
    chamber.titleAbbreviation = [chamber getTitleAbbreviation];
   return chamber;
}

- (NSString *)getTitleAbbreviation {
    if (self.title && [[self.title lowercaseString] hasPrefix:@"assembly"])
        return NSLocalizedString(@"Asm.", @"Abbreviation for Assembly");
    return [super getTitleAbbreviation];
}
@end
