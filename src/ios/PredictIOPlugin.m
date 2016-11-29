//
//  PredictIOPlugin.m
//  PhoneGapSample
//
//  Created by PredictIO on 14/02/2015.
//
//

#import "PredictIOPlugin.h"
#import "PredictIO.h"
#import "PIOTripSegment.h"

static NSString *const PIOZoneCenterLatitudeKey = @"zoneCenterLatitude";
static NSString *const PIOZoneCenterLongitudeKey = @"zoneCenterLongitude";
static NSString *const PIOZoneRadiusKey = @"zoneRadius";
static NSString *const PIOZoneTypeKey = @"zoneType";

@interface PredictIOPlugin ()

@property (strong, nonatomic) NSArray *tripSegmentKeys;
@property (strong, nonatomic) NSArray *zoneKeys;

@end

@implementation PredictIOPlugin

- (void)start:(CDVInvokedUrlCommand*)command
{
    PredictIO *predictIO = [PredictIO sharedInstance];
    predictIO.delegate = self;

    if (command.arguments != nil && [command.arguments count] > 0) {
        predictIO.apiKey = [command.arguments objectAtIndex:0];
        [predictIO startWithCompletionHandler:^(NSError *error) {
            CDVPluginResult* pluginResult = nil;
            NSString *errorDescription = [error description];
            if (error == nil) {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
            } else {
                pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorDescription];
            }
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }];
    } else {
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"API key missing"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)stop:(CDVInvokedUrlCommand*)command
{
    [[PredictIO sharedInstance] stop];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)kickStartGPS:(CDVInvokedUrlCommand*)command
{
    [[PredictIO sharedInstance] kickStartGPS];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)status:(CDVInvokedUrlCommand*)command
{
    PredictIOStatus status = [[PredictIO sharedInstance] status];
    NSString *statusDesc = @"";
    if (status == PredictIOStatusActive) {
    	statusDesc = @"Active";
    } else if (status == PredictIOStatusLocationServicesDisabled) {
    	statusDesc = @"LocationServicesDisabled";
    } else if (status == PredictIOStatusInsufficientPermission) {
    	statusDesc = @"InsufficientPermission";
    } else if (status == PredictIOStatusInActive) {
    	statusDesc = @"InActive";
    }

    if ([statusDesc isEqualToString:@""]) {
    	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid PredictIO Status"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
    	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:statusDesc];
		[self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)deviceIdentifier:(CDVInvokedUrlCommand*)command {
    NSString *deviceIdentifier = [[PredictIO sharedInstance] deviceIdentifier];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:deviceIdentifier];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setCustomParameter:(CDVInvokedUrlCommand*)command {
    if ([self isValidStringArguments:command.arguments numOfArgs:2]) {
        NSString *key = command.arguments[0];
        NSString *value = command.arguments[1];
        [[PredictIO sharedInstance] setCustomParameter:key andValue:value];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSString *errorMsg = [self errorMessageInValidCustomParameterArguments:command.arguments];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMsg];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)setWebhookURL:(CDVInvokedUrlCommand*)command {
    if ([self isValidStringArguments:command.arguments numOfArgs:1]) {
        NSString *webhookUrl = command.arguments[0];
        [[PredictIO sharedInstance] setWebhookURL:webhookUrl];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    } else {
        NSString *errorMsg = [self errorMessageInValidWebhookArguments:command.arguments];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMsg];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)clearZoneHistory:(CDVInvokedUrlCommand*)command {
    [[PredictIO sharedInstance] clearZoneHistory];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)homeZone:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    PIOZone *homeZone = [PredictIO sharedInstance].homeZone;
    if (homeZone == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    } else {
        NSString *json = (NSString *)[self jsonFromZone:homeZone];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:json];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)workZone:(CDVInvokedUrlCommand*)command {
    CDVPluginResult* pluginResult;
    PIOZone *workZone = [PredictIO sharedInstance].workZone;
    if (workZone == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_NO_RESULT];
    } else {
        NSString *json = (NSString *)[self jsonFromZone:workZone];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:json];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - PredictIODelegate Methods

/* This method is invoked when predict.io detects that the user is about to depart
 * from his location and is approaching to his vehicle
 * @param departureLocation: The Location from where the user departed
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)departing:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"departing" params:params];
}

/* This method is invoked when predict.io detects that the user has just departed
 * from his location and have started a new trip
 * @param departureLocation: The Location from where the user departed
 * @param departureTime: Start time of the trip
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)departed:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"departed" params:params];
}

/* This method is invoked when predict.io is unable to validate the last departure event.
 * This can be due to invalid data received from sensors or the trip amplitude.
 * i.e. If the trip takes less than 5 minutes or the distance travelled is less than 3km
 * @param departureLocation: The Location from where the user departed
 * @param departureTime: Start time of the trip
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)canceledDeparture:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"canceledDeparture" params:params];
}

/* This method is invoked when predict.io detects transportation mode
 * @param: transportationMode: Mode of transportation
 * @param UUID: Trip segment UUID
 */
- (void)detectedTransportationMode:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"detectedTransportationMode" params:params];
}

/* This method is invoked when predict.io suspects that the user has just arrived
 * at his location and have ended a trip
 * Most of the time it is followed by a confirmed arrivedAtLocation event
 * If you need only confirmed arrival events, use arrivedAtLocation method (below) instead
 * @param departureLocation: The Location from where the user departed
 * @param arrivalLocation: The Location where the user arrived and ended the trip
 * @param departureTime: Start time of trip
 * @param arrivalTime: Stop time of trip
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)suspectedArrival:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"suspectedArrival" params:params];
}

/* This method is invoked when predict.io detects that the user has just arrived at destination
 * @param arrivalLocation: The Location where the user arrived and ended a trip
 * @param departureLocation: The Location from where the user departed
 * @param departureTime: Start time of trip
 * @param arrivalTime: Stop time of trip
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)arrived:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"arrived" params:params];
}

/* This method is invoked when predict.io detects that the user is searching for a
 * parking space at a specific location
 * @param location: The Location where predict.io identifies that user is searching for a parking space
 */
- (void)searchingInPerimeter:(CLLocation *)searchingLocation
{
    NSMutableDictionary *searchingParkingData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                              @(searchingLocation.coordinate.latitude), @"latitude",
                                              @(searchingLocation.coordinate.longitude), @"longitude",
                                              nil];

    NSString *params = [self jsonSerializeDictionary:searchingParkingData];
    [self evaluateJSMethod:@"searchingInPerimeter" params:params];
}

/* This method is invoked after few minutes of arriving at the destination and detects if the user is stationary or not
 * @param tripSegment: PIOTripSegment contains details about stationary after arrival
 * @discussion: The following properties are populated currently:
 *  UUID: Unique ID for a trip segment, e.g. to link departure and arrival events
 *  departureLocation: The Location from where the user departed
 *  arrivalLocation: The Location where the user arrived and ended the trip
 *  departureTime: Time of departure
 *  arrivalTime: Time of arrival
 *  transportationMode: Mode of transportation
 *  departureZone: Departure zone
 *  arrivalZone: Arrival Zone
 *  stationary: User activity status as stationary or not
 */
- (void)beingStationaryAfterArrival:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"beingStationaryAfterArrival" params:params];
}

/* This method is invoked when predict.io detects that the user has traveled by air plane and
 * just arrived at destination, this event is independent of usual vehicle trip detection and
 * will not have predecessor departed event
 * @param tripSegment: PIOTripSegment contains details about traveled by air plane event
 * @discussion: The following properties are populated currently
 *  UUID: Unique ID for a trip segment
 *  departureLocation: The Location from where the user started journey
 *  arrivalLocation: The Location where the user arrived and ended the journey
 *  departureTime: Start time of journey
 *  arrivalTime: Stop time of journey
 */
- (void)traveledByAirplane:(PIOTripSegment *)tripSegment
{
    NSString *params = [self jsonFromTripSegment:tripSegment];
    [self evaluateJSMethod:@"traveledByAirplane" params:params];
}

/* This is invoked when new location information is received from location services
 * Implemented this method if you need raw GPS data, instead of creating new location manager
 * Since, it is not recommended to use multiple location managers in a single app
 * @param location: New location
 */
- (void)didUpdateLocation:(CLLocation *)location
{
    NSMutableDictionary *didUpdateLocationData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                 @(location.coordinate.latitude), @"latitude",
                                                 @(location.coordinate.longitude), @"longitude",
                                                 nil];

    NSString *params = [self jsonSerializeDictionary:didUpdateLocationData];
    [self evaluateJSMethod:@"didUpdateLocation" params:params];
}

#pragma mark - TripSegment To JSON Conversion Methods

- (NSString *)transportMode:(TransportationMode)transportMode {
    if (transportMode == TransportationModeUndetermined) {
      return @"Undetermined";
    } else if (transportMode == TransportationModeCar) {
      return @"Car";
    } else {
      return @"NonCar";
    }
}

- (NSString *)zoneType:(PIOZoneType)zoneType {
    NSString *zone;
    switch (zoneType) {
        case PIOZoneTypeHome:
            zone = @"Home";
            break;
        case PIOZoneTypeWork:
            zone = @"Work";

        default:
            zone = @"Other";
            break;
    }
    return zone;
}

- (NSArray *)tripSegmentKeys {
    if (_tripSegmentKeys == nil) {
        return @[@"arrivalLatitude", @"arrivalLongitude", @"departureLatitude", @"departureLongitude",
                 @"departureTime", @"arrivalTime", @"transportationMode", @"UUID", @"departureZone",
                 @"arrivalZone", @"stationaryAfterArrival"];
    }
    return _tripSegmentKeys;
}

- (NSArray *)valuesOfTripSegment:(PIOTripSegment *)tripSegment {
    NSObject *arrivalLatitude = [self checkObject:tripSegment.arrivalLocation
                                        withDoubleValue:tripSegment.arrivalLocation.coordinate.latitude];
    NSObject *arrivalLongitude = [self checkObject:tripSegment.arrivalLocation
                                         withDoubleValue:tripSegment.arrivalLocation.coordinate.longitude];
    NSObject *departureLatitude = [self checkObject:tripSegment.departureLocation
                                          withDoubleValue:tripSegment.departureLocation.coordinate.latitude];
    NSObject *departureLongitude = [self checkObject:tripSegment.departureLocation
                                           withDoubleValue:tripSegment.departureLocation.coordinate.longitude];
    NSObject *departureTime = [self checkObject:tripSegment.departureTime
                                      withDoubleValue:[tripSegment.departureTime timeIntervalSince1970]];
    NSObject *arrivalTime = [self checkObject:tripSegment.arrivalTime
                                    withDoubleValue:[tripSegment.arrivalTime timeIntervalSince1970]];
    NSObject *departureZone = [self checkObject:tripSegment.departureZone
                                withObjectValue:[self dictionaryFromZone:tripSegment.departureZone]];
    NSObject *arrivalZone = [self checkObject:tripSegment.arrivalZone
                              withObjectValue:[self dictionaryFromZone:tripSegment.arrivalZone]];
    return @[arrivalLatitude, arrivalLongitude, departureLatitude, departureLongitude, departureTime,
             arrivalTime, [self transportMode:tripSegment.transportationMode], tripSegment.UUID,
             departureZone, arrivalZone, @(tripSegment.stationaryAfterArrival)];
}

- (NSDictionary *)dictionaryFromTripSegment:(PIOTripSegment *)tripSegment {
    NSDictionary *tripSegmentDic = [[NSDictionary alloc] initWithObjects:[self valuesOfTripSegment:tripSegment]
                                                                 forKeys:self.tripSegmentKeys];
    return tripSegmentDic;
}

- (NSString *)jsonFromTripSegment:(PIOTripSegment *)tripSegment {
    NSDictionary *tripSegmentDictionary = [self dictionaryFromTripSegment:tripSegment];
    NSString *params = [self jsonSerializeDictionary:tripSegmentDictionary];
    return params;
}

#pragma mark - PIOZone to JSON Conversion Methods

- (NSArray *)zoneKeys {
    if (_zoneKeys == nil) {
        _zoneKeys = @[PIOZoneCenterLatitudeKey, PIOZoneCenterLongitudeKey, PIOZoneRadiusKey,
                         PIOZoneTypeKey];
    }
    return _zoneKeys;
}

- (NSArray *)valuesOfZone:(PIOZone *)zone {
    NSObject *zoneCenterLatitude = [self checkObject:zone withDoubleValue:zone.center.latitude];
    NSObject *zoneCenterLongitude = [self checkObject:zone withDoubleValue:zone.center.longitude];
    NSObject *zoneRadius = [self checkObject:zone withDoubleValue:zone.radius];
    NSObject *zoneType = [self checkObject:zone withObjectValue:[self zoneType:zone.zoneType]];
    return @[zoneCenterLatitude, zoneCenterLongitude, zoneRadius, zoneType];
}

- (NSDictionary *)dictionaryFromZone:(PIOZone *)zone {
    NSDictionary *zoneDic = [[NSDictionary alloc] initWithObjects:[self valuesOfZone:zone]
                                                          forKeys:self.zoneKeys];
    return zoneDic;
}

- (NSString *)jsonFromZone:(PIOZone *)zone {
    NSDictionary *zoneDictionary = [self dictionaryFromZone:zone];
    NSString *params = [self jsonSerializeDictionary:zoneDictionary];
    return params;
}

#pragma mark - JSON to JavaScript

- (NSString *)jsonSerializeDictionary:(NSDictionary *)dictionary
{
    NSString *jsonString = nil;
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
                                                       options:0
                                                         error:&error];
    if (jsonData != nil) {
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    }

    return jsonString;
}

- (void)evaluateJSMethod:(NSString *)methodName params:(NSString *)params
{
    NSString *jsStatement = methodName;

    if (params == nil) {
        jsStatement = [jsStatement stringByAppendingString:@"();"];
    } else {
        jsStatement = [jsStatement stringByAppendingString:@"('"];
        jsStatement = [jsStatement stringByAppendingString:params];
        jsStatement = [jsStatement stringByAppendingString:@"');"];
    }

    [self.commandDelegate evalJs:jsStatement];
}

#pragma mark - Validation Methods

- (BOOL)isValidStringArguments:(NSArray *)arguments numOfArgs:(NSUInteger)numOfArgs {
    if (arguments == nil || arguments.count != numOfArgs) {
        return NO;
    } else {
        for (int index = 0; index<numOfArgs; index++) {
            if (![arguments[index] isKindOfClass:[NSString class]]) {
                return NO;
            }
        }
    }
    return YES;
}

- (NSString *)errorMessageInValidCustomParameterArguments:(NSArray *)arguments {
    if (arguments == nil || arguments.count != 2) {
        return @"Expecting two parameters, a key and a value";
    } else {
        if (![arguments[0] isKindOfClass:[NSString class]] ||
            ![arguments[1] isKindOfClass:[NSString class]]) {
            return @"Arguments can only be of string type";
        }
    }
    return nil;
}

- (NSString *)errorMessageInValidWebhookArguments:(NSArray *)arguments {
    if (arguments == nil || arguments.count != 1) {
        return @"Expecting one parameter, a webhook url string";
    } else {
        if (![arguments[0] isKindOfClass:[NSString class]]) {
            return @"Argument can only be of string type";
        }
    }
    return nil;
}

- (NSObject *)checkObject:(NSObject *)object withDoubleValue:(double)value {
    return (object == nil ? [NSNull null] : @(value));
}

- (NSObject *)checkObject:(NSObject *)object withObjectValue:(NSObject *)value {
    return (object == nil ? [NSNull null] : value);
}

@end
