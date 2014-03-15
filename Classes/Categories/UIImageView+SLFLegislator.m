//
//  UIImageView+SLFLegislator.m
//  Created by Greg Combs on 2/3/12.
//
//  OpenStates by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "UIImageView+SLFLegislator.h"
#import "UIImageView+AFNetworking.h"
#import "SLFReachable.h"
#import "SLFDataModels.h"

static UIImage *placeholderImage;

@implementation UIImageView (SLFLegislator)

- (void)setImageWithLegislator:(SLFLegislator *)legislator {
    if (!legislator) {
        self.image = nil;
        return;
    }
    NSString *photoURL = legislator.normalizedPhotoURL;
    if (!placeholderImage)
        placeholderImage = [[UIImage imageNamed:@"placeholder"] retain];
    if (SLFIsReachableAddressNoAlert(photoURL)) {
        [self setImageWithURL:[NSURL URLWithString:photoURL] placeholderImage:placeholderImage];
        return;
    }
    [self setImage:placeholderImage];
}


@end
