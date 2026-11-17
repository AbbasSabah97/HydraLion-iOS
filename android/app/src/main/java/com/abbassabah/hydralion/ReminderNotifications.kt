package com.abbassabah.hydralion

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.RingtoneManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import java.util.Calendar

object ReminderScheduler {
    const val ACTION_NOTIFY = "com.abbassabah.hydralion.ACTION_NOTIFY"
    const val ACTION_SNOOZE = "com.abbassabah.hydralion.ACTION_SNOOZE"
    private const val NOTIFICATION_ID = 4100
    private const val ALARM_REQUEST = 4101
    private const val SNOOZE_REQUEST = 4102
    private const val SNOOZE_ACTION_REQUEST = 4103
    private const val SOUND_CHANNEL = "hydralion_reminders_sound"
    private const val SILENT_CHANNEL = "hydralion_reminders_silent"

    fun createChannels(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = NotificationChannel(SOUND_CHANNEL, "HydraLion reminders", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "Scheduled hydration reminders"
            enableVibration(true)
            setSound(
                RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION),
                AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build()
            )
        }
        val silent = NotificationChannel(SILENT_CHANNEL, "HydraLion silent reminders", NotificationManager.IMPORTANCE_DEFAULT).apply {
            description = "Silent hydration reminders"
            enableVibration(true)
            setSound(null, null)
        }
        manager.createNotificationChannel(sound)
        manager.createNotificationChannel(silent)
    }

    fun scheduleNext(context: Context) {
        val settings = HydrationStorage.load(context).reminder
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java).setAction(ACTION_NOTIFY)
        val pending = PendingIntent.getBroadcast(
            context, ALARM_REQUEST, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pending)
        if (!settings.enabled) return

        val now = Calendar.getInstance()
        val start = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, settings.startMinutes / 60)
            set(Calendar.MINUTE, settings.startMinutes % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val end = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, settings.endMinutes / 60)
            set(Calendar.MINUTE, settings.endMinutes % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }

        val next = when {
            now.before(start) -> start
            !now.before(end) -> (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
            else -> {
                val elapsedMinutes = ((now.timeInMillis - start.timeInMillis) / 60000L).toInt()
                val interval = settings.intervalMinutes.coerceAtLeast(15)
                val nextSlot = (elapsedMinutes / interval + 1) * interval
                val candidate = (start.clone() as Calendar).apply { add(Calendar.MINUTE, nextSlot) }
                if (candidate.after(end)) {
                    (start.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, 1) }
                } else candidate
            }
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
        }
    }

    fun scheduleSnooze(context: Context) {
        val settings = HydrationStorage.load(context).reminder
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, ReminderReceiver::class.java).setAction(ACTION_NOTIFY)
        val pending = PendingIntent.getBroadcast(
            context, SNOOZE_REQUEST, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val triggerAt = System.currentTimeMillis() + settings.snoozeMinutes.coerceAtLeast(1) * 60_000L
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pending)
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pending)
        }
    }

    fun showNotification(context: Context) {
        createChannels(context)
        val settings = HydrationStorage.load(context).reminder
        val channel = if (settings.soundEnabled) SOUND_CHANNEL else SILENT_CHANNEL
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPending = PendingIntent.getActivity(
            context, 4200, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val snoozeIntent = Intent(context, ReminderReceiver::class.java).setAction(ACTION_SNOOZE)
        val snoozePending = PendingIntent.getBroadcast(
            context, SNOOZE_ACTION_REQUEST, snoozeIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val actionTitle = "Remind me later (" + settings.snoozeMinutes + " min)"
        val notification = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_water_drop)
            .setContentTitle("HydraLion 💧")
            .setContentText(settings.message.ifBlank { "Time to drink water! 💧" })
            .setStyle(NotificationCompat.BigTextStyle().bigText(settings.message))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(openPending)
            .addAction(R.drawable.ic_water_drop, actionTitle, snoozePending)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(NOTIFICATION_ID, notification)
        } catch (_: SecurityException) {
            // The user can disable notifications at the Android/MIUI system level.
        }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        when (intent?.action) {
            ReminderScheduler.ACTION_SNOOZE -> {
                NotificationManagerCompat.from(context).cancel(4100)
                ReminderScheduler.scheduleSnooze(context)
            }
            else -> {
                ReminderScheduler.showNotification(context)
                ReminderScheduler.scheduleNext(context)
            }
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        ReminderScheduler.createChannels(context)
        ReminderScheduler.scheduleNext(context)
    }
}
