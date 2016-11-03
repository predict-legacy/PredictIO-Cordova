//
//  PredictIOPlugin.h
//
//  Created by PredictIO on 21/06/2016.
//  Copyright (c) 2016 predict.io by ParkTAG GmbH. All rights reserved.
//  SDK Version 3.1.0

#import <Cordova/CDV.h>
#import "PredictIO.h"

@interface PredictIOPlugin : CDVPlugin
<PredictIODelegate>

/**
 * This starts predict.io if delegate and API-Key are set, otherwise it returns an Error
 * @param apiKey:   PredictIO SDK API Key.
 **/
- (void)start:(CDVInvokedUrlCommand*)command;

/**
 * Stop predict.io
 **/
- (void)stop:(CDVInvokedUrlCommand*)command;

/**
 * Manually activate GPS for short period of time
 **/
- (void)kickStartGPS:(CDVInvokedUrlCommand*)command;

/**
 * This method returns the status of the PredictIO i.e. if it is active or otherwise
 * Possible return values are,
 * Active : predict.io is in a working, active state
 * LocationServicesDisabled : predict.io is not in a working state as the location services are disabled
 * InsufficientPermission : predict.io is not in a working state as the permissions to use location services are not provided by the user
 * InActive : predict.io has not been started. It is in inactive state
 **/
- (void)status:(CDVInvokedUrlCommand*)command;

/**
 * An alphanumeric string that uniquely identifies a device to the predict.io
 **/
- (void)deviceIdentifier:(CDVInvokedUrlCommand*)command;

/*
 * Set custom parameters which can then be sent to a user defined webhook url
 * @param key:   Key to identify a custom parameter value
 * @param value: Custom parameter value
 */
- (void)setCustomParameter:(CDVInvokedUrlCommand*)command;

/*
 * Set a webhook url where all the detected events can then be forwarded along with the custom parameters.
 * This webhook will not support additional authentication. So any additional validation of legitimate requests must take place.
 * @param url: The webhook url
 */
- (void)setWebhookURL:(CDVInvokedUrlCommand*)command;

@end
