package io.predict.plugin;

import android.app.Application;
import android.location.Location;
import android.util.Log;

import io.predict.PIOTripSegment;
import io.predict.PredictIO;
import io.predict.PredictIOListener;

public class PredictIOApp extends Application implements PredictIOListener {

    @Override
    public void onCreate() {
        super.onCreate();		
		PredictIO predictIO = PredictIO.getInstance(this);
        // This notifies sdk that app is initialised
		predictIO.setAppOnCreate(this);
        // set this to get event callbacks
        predictIO.setListener(this);		
    }
	
	    @Override
        public void departed(PIOTripSegment tripSegment) {
            String mess = "User has departed from his location.";
            PredictIOUtils.notify(getApplicationContext(), 1, "Departed", mess);
        }

        @Override
        public void arrived(PIOTripSegment tripSegment) {
            try {
                String message = "User has arrived at destination.";
                PredictIOUtils.notify(getApplicationContext(), 2, "Arrived", message);
            } catch (Exception e) {
                Log.e("Error", "Error = " + e.getMessage());
            }
        }

        @Override
        public void arrivalSuspected(PIOTripSegment tripSegment) {
            try {
                String message = "predict.io suspected, user has arrived at destination";
                PredictIOUtils.notify(getApplicationContext(), 3, "Arrival suspected", message);
            } catch (Exception e) {
                Log.e("Error", "Error = " + e.getMessage());
            }
        }

        @Override
        public void searchingInPerimeter(Location location) {
            PredictIOUtils.notify(getApplicationContext(), 4, "Looking for parking space"
                    , "predict.io has detected that you are looking for parking space");
        }

        @Override
        public void departureCanceled() {
            PredictIOUtils.notify(getApplicationContext(), 5, "Departure canceled"
                    , "predict.io has cancelled a last departed location");
        }

        @Override
        public void didUpdateLocation(Location location) {
        }

        @Override
        public void transportationMode(PIOTripSegment tripSegment) {
            try {
                String message = "Transportation mode: " + tripSegment.transportationMode.toString();
                PredictIOUtils.notify(getApplicationContext(), 6, "Transportation mode predicted", message);
            } catch (Exception e) {
                Log.e("Error", "Error = " + e.getMessage());
            }
        }
}