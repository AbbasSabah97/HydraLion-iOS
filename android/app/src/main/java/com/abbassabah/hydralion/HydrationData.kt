package com.abbassabah.hydralion

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import com.google.gson.Gson
import com.google.gson.JsonSyntaxException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Calendar
import java.util.UUID

enum class DrinkKind(
    val titleEn: String,
    val titleAr: String,
    val emoji: String,
    val color: Long
) {
    WATER("Water", "الماء", "💧", 0xFF378FE8),
    TEA("Green Tea", "الشاي الأخضر", "🍵", 0xFF4C9B62),
    COFFEE("Coffee", "القهوة", "☕", 0xFF805033),
    JUICE("Orange Juice", "العصير", "🍊", 0xFFF39A28),
    MILK("Milk", "الحليب", "🥛", 0xFF9CB8E8)
}

data class DrinkEntry(
    val id: String = UUID.randomUUID().toString(),
    val kind: DrinkKind = DrinkKind.WATER,
    val amountMl: Int = 250,
    val timestamp: Long = System.currentTimeMillis()
)

data class ReminderSettings(
    val enabled: Boolean = false,
    val intervalMinutes: Int = 60,
    val startMinutes: Int = 8 * 60,
    val endMinutes: Int = 22 * 60,
    val message: String = "Time to drink water! 💧",
    val snoozeMinutes: Int = 5,
    val soundEnabled: Boolean = true
)

data class HydrationState(
    val dailyGoal: Int = 3000,
    val entries: List<DrinkEntry> = emptyList(),
    val reminder: ReminderSettings = ReminderSettings()
)

object HydrationStorage {
    private const val PREFS = "hydralion_local_data"
    private const val STATE_KEY = "hydration_state_v1"
    private val gson = Gson()

    @Synchronized
    fun load(context: Context): HydrationState {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(STATE_KEY, null)
            ?: return HydrationState()
        return try {
            gson.fromJson(raw, HydrationState::class.java) ?: HydrationState()
        } catch (_: JsonSyntaxException) {
            HydrationState()
        } catch (_: Exception) {
            HydrationState()
        }
    }

    @Synchronized
    fun save(context: Context, state: HydrationState) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(STATE_KEY, gson.toJson(state))
            .apply()
    }
}

class HydrationViewModel(application: Application) : AndroidViewModel(application) {
    private val _state = MutableStateFlow(HydrationStorage.load(application))
    val state: StateFlow<HydrationState> = _state.asStateFlow()

    private fun commit(next: HydrationState) {
        _state.value = next
        HydrationStorage.save(getApplication(), next)
    }

    fun addDrink(kind: DrinkKind, amountMl: Int) {
        val entry = DrinkEntry(kind = kind, amountMl = amountMl.coerceIn(10, 3000))
        commit(_state.value.copy(entries = listOf(entry) + _state.value.entries))
    }

    fun deleteEntry(id: String) {
        commit(_state.value.copy(entries = _state.value.entries.filterNot { it.id == id }))
    }

    fun updateEntry(id: String, amountMl: Int) {
        commit(_state.value.copy(entries = _state.value.entries.map {
            if (it.id == id) it.copy(amountMl = amountMl.coerceIn(10, 3000)) else it
        }))
    }

    fun setDailyGoal(value: Int) {
        commit(_state.value.copy(dailyGoal = value.coerceIn(250, 10000)))
    }

    fun updateReminder(value: ReminderSettings) {
        commit(_state.value.copy(reminder = value))
        ReminderScheduler.scheduleNext(getApplication())
    }

    fun refreshReminderSchedule() {
        ReminderScheduler.scheduleNext(getApplication())
    }

    fun totalForDay(day: Calendar): Int {
        val target = day.clone() as Calendar
        return _state.value.entries.filter { entry ->
            val entryDay = Calendar.getInstance().apply { timeInMillis = entry.timestamp }
            entryDay.get(Calendar.YEAR) == target.get(Calendar.YEAR) &&
                entryDay.get(Calendar.DAY_OF_YEAR) == target.get(Calendar.DAY_OF_YEAR)
        }.sumOf { it.amountMl }
    }
}
