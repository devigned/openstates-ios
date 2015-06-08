//
//  DistrictDetailViewController.m
//  Created by Gregory Combs on 7/31/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the BSD-3 License included with this source
// distribution.


#import "DistrictDetailViewController.h"
#import "LegislatorDetailViewController.h"
#import "SLFDataModels.h"
#import "SLFRestKitManager.h"
#import "SLFTheme.h"
#import "SLFAlertView.h"
#import "DistrictSearch.h"
#import "MultiRowCalloutAnnotationView.h"
#import "SLFActionPathRegistry.h"

@interface DistrictDetailViewController()
- (void)loadMapWithID:(NSString *)objID;
- (void)loadDataWithResourcePath:(NSString *)path;
- (void)setUpperOrLowerDistrict:(SLFDistrict *)districtMap;
@property (nonatomic,retain) DistrictSearch *districtSearch;
@end

@implementation DistrictDetailViewController
@synthesize resourceClass;
@synthesize upperDistrict;
@synthesize lowerDistrict;
@synthesize districtSearch;
@synthesize onSavePersistentActionPath = _onSavePersistentActionPath;

- (id)initWithDistrictMapID:(NSString *)objID {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.resourceClass = [SLFDistrict class];
        [self loadMapWithID:objID];
    }
    return self;
}

- (void)dealloc {
    [[RKObjectManager sharedManager].requestQueue cancelRequestsWithDelegate:self];
    self.upperDistrict = nil;
    self.lowerDistrict = nil;
    self.districtSearch = nil;
    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.screenName = @"District Detail Screen";
}

- (void)loadMapWithID:(NSString *)objID {
    if (IsEmpty(objID))
        return;
    SLFDistrict *district = [SLFDistrict findFirstByAttribute:@"boundaryID" withValue:objID];
    if (district)
        [self setUpperOrLowerDistrict:district];
    [self loadDataWithResourcePath:[NSString stringWithFormat:@"/districts/boundary/%@", objID]];    // DON'T REALLY LOAD UNLESS WE HAVE TO
}

- (void)setUpperOrLowerDistrict:(SLFDistrict *)newObj {
    if (!newObj)
        return;
    if (newObj.isUpperChamber)
        self.upperDistrict = newObj;
    else
        self.lowerDistrict = newObj;
    if (self.onSavePersistentActionPath) {
        _onSavePersistentActionPath(self.actionPath);
        self.onSavePersistentActionPath = nil;
    }
}

- (NSString *)actionPath {
    SLFDistrict *district = self.lowerDistrict;
    if (!district)
        district = self.upperDistrict;
    return [[self class] actionPathForObject:district];
}

+ (NSString *)actionPathForObject:(id)object {
    NSString *pattern = [SLFActionPathRegistry patternForClass:[self class]];
    if (!pattern)
        return nil;
    if (!object)
        return pattern;
    return RKMakePathWithObjectAddingEscapes(pattern, object, NO);
}

- (void)setOnSavePersistentActionPath:(SLFPersistentActionsSaveBlock)onSavePersistentActionPath {
    if (_onSavePersistentActionPath) {
        Block_release(_onSavePersistentActionPath);
        _onSavePersistentActionPath = nil;
    }
    _onSavePersistentActionPath = Block_copy(onSavePersistentActionPath);
}

- (void)reconfigureForDistrict:(SLFDistrict *)district {
    [self setUpperOrLowerDistrict:district];
    if (![self isViewLoaded])
        return;
    [self.mapView addAnnotation:district];
    [self moveMapToRegion:district.region];
    MKPolygon *polygon = [district polygonFactory];
    if (polygon)
        [self.mapView addOverlay:polygon];
}

- (void)loadDataWithResourcePath:(NSString *)path {
    if (IsEmpty(path))
        return;    
    NSDictionary *queryParameters = [NSDictionary dictionaryWithObject:SUNLIGHT_APIKEY forKey:@"apikey"];
    NSString *pathToLoad = [path appendQueryParams:queryParameters];
    [[SLFRestKitManager sharedRestKit] loadObjectsAtResourcePath:pathToLoad delegate:self withTimeout:SLF_HOURS_TO_SECONDS(7*24)];
}

#pragma mark RKObjectLoaderDelegate methods

- (void)objectLoader:(RKObjectLoader*)objectLoader didLoadObject:(id)object {    
    if (!object || ![object isKindOfClass:self.resourceClass])
        return;
    SLFDistrict *district = object;
    [self reconfigureForDistrict:district];
}

- (void)objectLoader:(RKObjectLoader*)objectLoader didFailWithError:(NSError*)error {
    self.onSavePersistentActionPath = nil;
    [SLFAlertView showWithTitle:@"Unable to load district" message:@"Sorry, we were unable to load the district map." buttonTitle:@"OK"];
//    [SLFRestKitManager showFailureAlertWithRequest:objectLoader error:error];
    NSLog(@"Error loading district: %@", error.description);
}

- (SLFDistrict *)districtMapForPolygon:(MKPolygon *)polygon {
    if (!polygon)
        return nil;
    NSString *boundaryID = [polygon subtitle];
    if (IsEmpty(boundaryID)) {
        if (self.upperDistrict && polygon.pointCount == self.upperDistrict.polygonFactory.pointCount)
            return self.upperDistrict;
        return self.lowerDistrict;
    }
    return [SLFDistrict findFirstByAttribute:@"boundaryID" withValue:boundaryID];
}

#pragma mark -
#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKPolygon class]])
    {
        SLFDistrict *district = [self districtMapForPolygon:(MKPolygon*)overlay];
        MKPolygonView *aView = [[[MKPolygonView alloc] initWithPolygon:(MKPolygon*)overlay] autorelease];
        if (!district)
            aView.fillColor = [[UIColor grayColor] colorWithAlphaComponent:0.2];
        else if (district.isUpperChamber)
            aView.fillColor = [[SLFAppearance accentOrangeColor] colorWithAlphaComponent:0.2];
        else 
            aView.fillColor = [[SLFAppearance accentBlueColor] colorWithAlphaComponent:0.4];
        aView.strokeColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7];
        aView.lineWidth = 2;
        return aView;
    }
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)aMapView viewForAnnotation:(id <MKAnnotation>)annotation { 
    MKAnnotationView *annotationView = [super mapView:aMapView viewForAnnotation:annotation];
    if (annotationView && [annotationView isKindOfClass:[MultiRowCalloutAnnotationView class]]) {
        MultiRowCalloutAnnotationView *multiView = (MultiRowCalloutAnnotationView *)annotationView;
		__block __typeof__(self) bself = self;
        multiView.onCalloutAccessoryTapped = ^(MultiRowCalloutCell *cell, UIControl *control, NSDictionary *userData) {
            NSString *legID = [userData valueForKey:@"legID"];
            NSString *path = [SLFActionPathNavigator navigationPathForController:[LegislatorDetailViewController class] withResourceID:legID];
            if (!IsEmpty(path))
                [SLFActionPathNavigator navigateToPath:path skipSaving:NO fromBase:bself popToRoot:NO];
        };
        return multiView;
    }
    return annotationView;
}

- (void)beginBoundarySearchForCoordininate:(CLLocationCoordinate2D)coordinate {
    __block __typeof__(self) bself = self;
    self.districtSearch = [DistrictSearch districtSearchForCoordinate:coordinate 
                                             successBlock:^(NSArray *results) {
                                                 for (NSString *districtID in results)
                                                     [bself loadMapWithID:districtID];
                                                 bself.districtSearch = nil;
                                             }
                                             failureBlock:^(NSString *message, DistrictSearchFailOption failOption) {
                                                 if (failOption == DistrictSearchFailOptionLog)
                                                     RKLogError(@"%@", message);
                                                 else
                                                     [SLFAlertView showWithTitle:NSLocalizedString(@"Geolocation Error", @"") message:message buttonTitle:NSLocalizedString(@"OK", @"")];
                                                 bself.districtSearch = nil;
                                             }];
}

@end
