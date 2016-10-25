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

#pragma mark - PredictIODelegate Methods

/* This method is invoked when predict.io detects that the user is about to depart
 * from his location and is approaching to his vehicle
 * @param departureLocation: The Location from where the user departed
 * @param transportMode: Mode of transport
 * @param UUID: Trip segment UUID
 */
- (void)departing:(PIOTripSegment *)tripSegment
{
    NSMutableDictionary *departingData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                          @(tripSegment.departureLocation.coordinate.latitude), @"departureLatitude",
                                          @(tripSegment.departureLocation.coordinate.longitude), @"departureLongitude",
                                          [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                          tripSegment.UUID, @"UUID",
                                          nil];

    NSString *params = [self jsonSerializeDictionary:departingData];
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
    NSMutableDictionary *departedData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        @(tripSegment.departureLocation.coordinate.latitude), @"departureLatitude",
                                        @(tripSegment.departureLocation.coordinate.longitude), @"departureLongitude",
                                        @([tripSegment.departureTime timeIntervalSince1970]), @"departureTime",
                                        [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                        tripSegment.UUID, @"UUID",
                                        nil];

    NSString *params = [self jsonSerializeDictionary:departedData];
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
- (void)departureCanceled:(PIOTripSegment *)tripSegment
{
    NSMutableDictionary *departureCanceledData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                  @(tripSegment.departureLocation.coordinate.latitude), @"departureLatitude",
                                                  @(tripSegment.departureLocation.coordinate.longitude), @"departureLongitude",
                                                  @([tripSegment.departureTime timeIntervalSince1970]), @"departureTime",
                                                  [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                                  tripSegment.UUID, @"UUID",
                                                  nil];

    NSString *params = [self jsonSerializeDictionary:departureCanceledData];
    [self evaluateJSMethod:@"departureCanceled" params:params];
}

/* This method is invoked when predict.io detects transportation mode
 * @param: transportationMode: Mode of transportation
 * @param UUID: Trip segment UUID
 */
- (void)transportationMode:(PIOTripSegment *)tripSegment
{
    NSMutableDictionary *departedData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                         tripSegment.UUID, @"UUID",
                                         nil];

    NSString *params = [self jsonSerializeDictionary:departedData];
    [self evaluateJSMethod:@"transportationMode" params:params];
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
- (void)arrivalSuspected:(PIOTripSegment *)tripSegment
{
  NSMutableDictionary *arrivalSuspectedData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            @(tripSegment.arrivalLocation.coordinate.latitude), @"arrivalLatitude",
                                            @(tripSegment.arrivalLocation.coordinate.longitude), @"arrivalLongitude",
                                            @(tripSegment.departureLocation.coordinate.latitude), @"departureLatitude",
                                            @(tripSegment.departureLocation.coordinate.longitude), @"departureLongitude",
                                            @([tripSegment.departureTime timeIntervalSince1970]), @"departureTime",
                                            @([tripSegment.arrivalTime timeIntervalSince1970]), @"arrivalTime",
                                            [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                            tripSegment.UUID, @"UUID",
                                            nil];

  NSString *params = [self jsonSerializeDictionary:arrivalSuspectedData];
  [self evaluateJSMethod:@"arrivalSuspected" params:params];
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
    NSMutableDictionary *arrivedAtData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        @(tripSegment.arrivalLocation.coordinate.latitude), @"arrivalLatitude",
                                        @(tripSegment.arrivalLocation.coordinate.longitude), @"arrivalLongitude",
                                        @(tripSegment.departureLocation.coordinate.latitude), @"departureLatitude",
                                        @(tripSegment.departureLocation.coordinate.longitude), @"departureLongitude",
                                        @([tripSegment.departureTime timeIntervalSince1970]), @"departureTime",
                                        @([tripSegment.arrivalTime timeIntervalSince1970]), @"arrivalTime",
                                        [self transportMode:tripSegment.transportationMode], @"transportationMode",
                                        tripSegment.UUID, @"UUID",
                                        nil];

    NSString *params = [self jsonSerializeDictionary:arrivedAtData];
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

#pragma mark - Helper Methods

- (NSString *)transportMode:(TransportationMode)transportMode {
    if (transportMode == TransportationModeUndetermined) {
      return @"Undetermined";
    } else if (transportMode == TransportationModeCar) {
      return @"Car";
    } else {
      return @"NonCar";
    }
}

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

@end
