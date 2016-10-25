package io.predict.plugin;

import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.IBinder;
import android.support.annotation.Nullable;
import android.support.v4.app.NotificationCompat;

import io.predict.cordova.example.R;

public class PredictIOForegroundService extends Service {
    protected Integer NOTIFICATION_ID = 101;

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    public static void stop(Context context) {
        context.stopService(new Intent(context, PredictIOForegroundService.class));
    }

    @Override
    public void onDestroy() {
        stopForeground(true);
        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        LoadNotification loadNotification = new LoadNotification("PredictIO", "Active");
        loadNotification.notifyMessage();
        return START_STICKY;
    }

    class LoadNotification {
        private String titleMessage;
        private String textMessage;

        public LoadNotification(String titleMessage, String textMessage) {
            this.titleMessage = titleMessage;
            this.textMessage = textMessage;
        }

        public void notifyMessage() {
            NotificationCompat.Builder builder = getNotificationBuilder(PredictIOForegroundService.class);
            startForeground(NOTIFICATION_ID, builder.build());
        }

        protected NotificationCompat.Builder getNotificationBuilder(Class clazz) {
            final NotificationCompat.Builder builder = new NotificationCompat.Builder(getApplicationContext());
            builder.setSmallIcon(R.drawable.icon);  // icon id of the image
            builder.setContentTitle(this.titleMessage)
                    .setContentText(this.textMessage);
            Intent foregroundIntent = new Intent(getApplicationContext(), clazz);
            foregroundIntent.setFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
                    | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            PendingIntent contentIntent = PendingIntent.getActivity(getApplicationContext(), 0,
                    foregroundIntent, 0);
            builder.setContentIntent(contentIntent);
            return builder;
        }
    }
}