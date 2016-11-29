package io.predict.plugin;

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.location.Location;
import android.os.Build;
import android.support.annotation.Nullable;
import android.text.TextUtils;

import com.google.android.gms.common.ConnectionResult;
import com.google.android.gms.common.GoogleApiAvailability;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import io.predict.PIOTripSegment;
import io.predict.PIOZone;
import io.predict.PredictIO;
import io.predict.PredictIOListener;
import io.predict.PredictIOStatus;
import io.predict.TransportationMode;

import static io.predict.plugin.PredictIOForegroundService.NOTIFICATION_CONTENT;

public class PredictIOPlugin extends CordovaPlugin implements PredictIOListener {
    private static final String LOCATION = Manifest.permission.ACCESS_COARSE_LOCATION;
    private static final int LOCATION_CODE = 1;
    private CallbackContext mCallbackContext;
    private JSONArray mData;
    private boolean isStartForegroundService;
    private String mNotificationContent;

    @Override
    public void initialize(CordovaInterface cordova, CordovaWebView webView) {
        super.initialize(cordova, webView);
        //ParkTAG SDK code
        PredictIO predictIO = PredictIO.getInstance(getApplicationContext());
        // This notifies sdk that app is initialised
        predictIO.setAppOnCreate((Application) getApplicationContext());
        // set this to get event callbacks
        predictIO.setListener(this);
    }

    @Override
    public boolean execute(String action, JSONArray data, CallbackContext callbackContext)
            throws JSONException {
        PredictIO predictIO = PredictIO.getInstance(getApplicationContext());
        if ("start".equals(action)) {
            if (cordova.hasPermission(LOCATION)) {
                startTracker(data, callbackContext);
            } else {
                mCallbackContext = callbackContext;
                mData = data;
                cordova.requestPermission(this, LOCATION_CODE, LOCATION);
            }
            return true;
        } else if ("stop".equals(action)) {
            stopTracker(callbackContext);
            return true;
        } else if ("minimize".equals(action)) {
            minimize();
            return true;
        } else if ("setListener".equals(action)) {
            predictIO.setListener(this);
            return true;
        } else if ("status".equals(action)) {
            String message;
            switch (predictIO.getStatus()) {
                case ACTIVE:
                    message = "ACTIVE";
                    break;
                case LOCATION_DISABLED:
                    message = "LOCATION_DISABLED";
                    break;
                case AIRPLANE_MODE_ENABLED:
                    message = "AIRPLANE_MODE_ENABLED";
                    break;
                case INSUFFICIENT_PERMISSION:
                    message = "INSUFFICIENT_PERMISSION";
                    break;
                default:
                case IN_ACTIVE:
                    message = "IN_ACTIVE";
                    break;
            }
            callbackContext.success(message);
            return true;
        } else if ("isSearchingInPerimeterEnabled".equals(action)) {
            boolean isSearchParkingEnable = predictIO.isSearchingInPerimeterEnabled();
            callbackContext.success(String.valueOf(isSearchParkingEnable));
            return true;
        } else if ("deviceIdentifier".equals(action)) {
            String deviceIdentifier = predictIO.getDeviceIdentifier();
            callbackContext.success(deviceIdentifier);
            return true;
        } else if ("setCustomParameter".equals(action)) {
            setCustomParameter(data, predictIO);
            return true;
        } else if ("setWebhookURL".equals(action)) {
            setWebhookURL(data, predictIO);
            return true;
        } else {
            return false;
        }
    }

    private void setWebhookURL(JSONArray data, PredictIO predictIO) {
        if (data != null) {
            try {
                String value = data.optString(0, null);
                if (!TextUtils.isEmpty(value)) {
                    predictIO.setWebhookURL(value);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void setCustomParameter(JSONArray data, PredictIO predictIO) {
        if (data != null) {
            try {
                String key = data.optString(0, null);
                String value = data.optString(1, null);
                if (!TextUtils.isEmpty(key) && !TextUtils.isEmpty(value)) {
                    predictIO.setCustomParameter(key, value);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private void minimize() {
        Activity activity = cordova.getActivity();
        if (activity != null) {
            activity.moveTaskToBack(true);
        }
    }

    private void startTracker(JSONArray params, final CallbackContext callbackContext) {
        boolean isSearchingInPerimeterEnaled = false;
        if (params != null) {
            try {
                isSearchingInPerimeterEnaled = params.optBoolean(0, false);
                isStartForegroundService = params.optBoolean(1, false);
                mNotificationContent = params.optString(2, null);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        try {
            PredictIO predictIO = PredictIO.getInstance(getApplicationContext());
            predictIO.enableSearchingInPerimeter(isSearchingInPerimeterEnaled);
            if (predictIOValidation(callbackContext, predictIO)) {
                return;
            }
            //noinspection MissingPermission
            predictIO.start(new PredictIO.PIOActivationListener() {
                @Override
                public void onActivated() {
                    if (isStartForegroundService) {
                        startForegroundService(mNotificationContent);
                    }
                    callbackContext.success();
                }

                @Override
                public void onActivationFailed(int error) {
                    switch (error) {
                        case 401:
                            callbackContext.error("Please verify your API_KEY!");
                            break;
                        case 403:
                            callbackContext.error("Please grant all required permissions");
                            break;
                    }
                }
            });
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
            e.printStackTrace();
        }
    }

    private boolean predictIOValidation(CallbackContext callbackContext, PredictIO predictIO) {
        //Validate tracker not already running
        if (predictIO.getStatus() == PredictIOStatus.ACTIVE) {
            callbackContext.success();
            return true;
        }

        //Validate google play services
        final GoogleApiAvailability apiAvailability = GoogleApiAvailability.getInstance();
        int resultCode = apiAvailability.isGooglePlayServicesAvailable(getApplicationContext());
        if (resultCode != ConnectionResult.SUCCESS) {
            if (apiAvailability.isUserResolvableError(resultCode)) {
                apiAvailability.getErrorDialog(this.cordova.getActivity(), resultCode, 1000).show();
            }
            callbackContext.success();
            return true;
        }
        return false;
    }

    private void startForegroundService(String notificationContent) {
        Intent intent = new Intent(getApplicationContext(), PredictIOForegroundService.class);
        intent.putExtra(NOTIFICATION_CONTENT, notificationContent);
        getApplicationContext().startService(intent);
    }

    private void stopForegroundService() {
        getApplicationContext().stopService(new Intent(getApplicationContext(), PredictIOForegroundService.class));
    }

    private void stopTracker(CallbackContext callbackContext) {
        try {
            stopForegroundService();
            PredictIO.getInstance(getApplicationContext()).stop();
            callbackContext.success();
        } catch (Exception e) {
            callbackContext.error(e.getMessage());
            e.printStackTrace();
        }
    }

    private Context getApplicationContext() {
        return this.cordova.getActivity().getApplicationContext();
    }

    @Override
    public void departed(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("departed('" + param + "')");
    }

    @Override
    public void searchingInPerimeter(Location location) {
        if (location != null) {
            evaluateJavascript("searchingInPerimeter('" + getJsonParams(location) + "')");
        }
    }

    @Override
    public void suspectedArrival(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("suspectedArrival('" + param + "')");
    }

    @Override
    public void arrived(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("arrived('" + param + "')");
    }

    @Override
    public void traveledByAirplane(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("traveledByAirplane('" + param + "')");
    }

    @Override
    public void beingStationaryAfterArrival(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("beingStationaryAfterArrival('" + param + "')");
    }

    @Override
    public void canceledDeparture(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("canceledDeparture('" + param + "')");
    }

    @Override
    public void didUpdateLocation(Location location) {
        if (location != null) {
            evaluateJavascript("didUpdateLocation('" + getJsonParams(location) + "')");
        }
    }

    @Override
    public void detectedTransportationMode(PIOTripSegment tripSegment) {
        String param = getJsonParams(tripSegment);
        evaluateJavascript("detectedTransportationMode('" + param + "')");
    }

    private String getJsonParams(Location location) {
        JSONObject jsonParam = new JSONObject();
        try {
            if (location != null) {
                jsonParam.put("latitude", location.getLatitude());
                jsonParam.put("longitude", location.getLongitude());
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonParam.toString();
    }

    private String getJsonParams(PIOTripSegment tripSegment) {
        JSONObject jsonParam = new JSONObject();
        try {
            jsonParam.put("UUID", tripSegment.UUID);
            jsonParam.put("departureTime", tripSegment.departureTime != null ? tripSegment.departureTime.getTime() : null);
            if (tripSegment.departureLocation != null) {
                jsonParam.put("departureLatitude", tripSegment.departureLocation.getLatitude());
                jsonParam.put("departureLongitude", tripSegment.departureLocation.getLongitude());
            } else {
                jsonParam.put("departureLatitude", null);
                jsonParam.put("departureLongitude", null);
            }
            jsonParam.put("arrivalTime", tripSegment.arrivalTime != null ? tripSegment.arrivalTime.getTime() : null);
            if (tripSegment.arrivalLocation != null) {
                jsonParam.put("arrivalLatitude", tripSegment.arrivalLocation.getLatitude());
                jsonParam.put("arrivalLongitude", tripSegment.arrivalLocation.getLongitude());
            } else {
                jsonParam.put("arrivalLatitude", null);
                jsonParam.put("arrivalLongitude", null);
            }
            if (tripSegment.transportationMode != null) {
                String transportationMode = "Undetermined";
                if (TransportationMode.CAR == tripSegment.transportationMode) {
                    transportationMode = "Car";
                } else if (TransportationMode.NON_CAR == tripSegment.transportationMode) {
                    transportationMode = "NonCar";
                } else if (TransportationMode.BICYCLE == tripSegment.transportationMode) {
                    transportationMode = "Bicycle";
                }
                jsonParam.put("transportationMode", transportationMode);
            } else {
                jsonParam.put("transportationMode", null);
            }
            jsonParam.put("stationaryAfterArrival", tripSegment.stationaryAfterArrival);
            jsonParam.put("departureZone", getZoneParams(tripSegment.departureZone));
            jsonParam.put("arrivalZone", getZoneParams(tripSegment.arrivalZone));
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonParam.toString();
    }

    @Nullable
    private JSONObject getZoneParams(PIOZone pioZone) throws JSONException {
        if (pioZone != null && pioZone.center != null) {
            JSONObject jsonObject = new JSONObject();
            jsonObject.put("zoneCenterLatitude", pioZone.center.latitude);
            jsonObject.put("zoneCenterLongitude", pioZone.center.longitude);
            jsonObject.put("zoneRadius", pioZone.radius);
            if (pioZone.zoneType != null) {
                String zoneType = "Other";
                if (pioZone.zoneType == PIOZone.PIOZoneType.HOME) {
                    zoneType = "Home";
                } else if (pioZone.zoneType == PIOZone.PIOZoneType.WORK) {
                    zoneType = "Work";
                }
                jsonObject.put("zoneType", zoneType);
            } else {
                jsonObject.put("zoneType", null);
            }
            return jsonObject;
        }
        return null;
    }

    private void evaluateJavascript(final String js) {
        if (webView != null && webView.getView() != null) {
            webView.getView().post(new Runnable() {
                public void run() {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
                        webView.sendJavascript(js);
                    } else {
                        webView.loadUrl("javascript:" + js);
                    }
                }
            });
        }
    }

    public void onRequestPermissionResult(int requestCode, String[] permissions, int[] grantResults)
            throws JSONException {
        switch (requestCode) {
            case LOCATION_CODE:
                if (mCallbackContext != null) {
                    startTracker(mData, mCallbackContext);
                }
                break;
        }
    }
}
