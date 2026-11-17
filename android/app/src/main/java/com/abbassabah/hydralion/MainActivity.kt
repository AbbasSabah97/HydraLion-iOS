package com.abbassabah.hydralion

import android.Manifest
import android.app.TimePickerDialog
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.weight
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sin

private val HydraBlue = Color(0xFF4D63F5)
private val HydraBlueDeep = Color(0xFF176FC2)
private val HydraNavy = Color(0xFF11194F)
private val HydraMuted = Color(0xFF7C8299)
private val HydraPanel = Color(0xFFF2F4FC)
private val HydraLavender = Color(0xFFAAB6FF)
private val HydraWhite = Color(0xFFFFFFFF)

class MainActivity : ComponentActivity() {
    private val hydrationViewModel: HydrationViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.statusBarColor = android.graphics.Color.WHITE
        window.navigationBarColor = android.graphics.Color.WHITE
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            window.decorView.systemUiVisibility =
                window.decorView.systemUiVisibility or
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR or
                    android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
        }
        ReminderScheduler.createChannels(this)
        if (Build.VERSION.SDK_INT >= 33 &&
            ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
        ) {
            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 711)
        }
        hydrationViewModel.refreshReminderSchedule()
        setContent {
            val state by hydrationViewModel.state.collectAsState()
            HydraLionTheme {
                HydraLionApp(state, hydrationViewModel)
            }
        }
    }
}

@Composable
private fun HydraLionTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = lightColorScheme(
            primary = HydraBlue,
            secondary = HydraLavender,
            background = HydraWhite,
            surface = HydraWhite,
            onPrimary = HydraWhite,
            onSurface = HydraNavy
        ),
        content = content
    )
}

@Composable
private fun tx(en: String, ar: String): String {
    val language = LocalConfiguration.current.locales[0].language
    return if (language.startsWith("ar")) ar else en
}

private enum class AppTab { HOME, HISTORY, PROGRESS, REMINDERS }

@Composable
private fun HydraLionApp(state: HydrationState, vm: HydrationViewModel) {
    var selectedTab by rememberSaveable { mutableStateOf(AppTab.HOME) }
    var showAdd by rememberSaveable { mutableStateOf(false) }
    var showGoal by rememberSaveable { mutableStateOf(false) }
    BackHandler(enabled = showAdd) { showAdd = false }

    CompositionLocalProvider(
        LocalLayoutDirection provides if (LocalConfiguration.current.locales[0].language.startsWith("ar")) LayoutDirection.Rtl else LayoutDirection.Ltr
    ) {
        Scaffold(
            containerColor = HydraWhite,
            contentWindowInsets = WindowInsets(0, 0, 0, 0),
            bottomBar = {
                if (!showAdd) BottomNavigationBar(selectedTab) { selectedTab = it }
            }
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                if (showAdd) {
                    AddDrinkScreen(
                        onBack = { showAdd = false },
                        onAdd = { kind, amount -> vm.addDrink(kind, amount) }
                    )
                } else {
                    when (selectedTab) {
                        AppTab.HOME -> HomeScreen(state, onAdd = { showAdd = true }, onGoal = { showGoal = true })
                        AppTab.HISTORY -> HistoryScreen(state, vm, onGoal = { showGoal = true })
                        AppTab.PROGRESS -> ProgressScreen(state, onGoal = { showGoal = true })
                        AppTab.REMINDERS -> RemindersScreen(state.reminder, vm, onGoal = { showGoal = true })
                    }
                }
            }
        }
        if (showGoal) {
            GoalDialog(
                currentGoal = state.dailyGoal,
                onDismiss = { showGoal = false },
                onSave = {
                    vm.setDailyGoal(it)
                    showGoal = false
                }
            )
        }
    }
}

@Composable
private fun Header(title: String, onBack: (() -> Unit)? = null, onGoal: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().height(56.dp).padding(horizontal = 18.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (onBack != null) {
            IconButton(onClick = onBack) {
                Icon(Icons.Filled.ArrowBack, contentDescription = tx("Back", "رجوع"), tint = HydraBlue)
            }
        } else {
            Spacer(Modifier.width(44.dp))
        }
        Text(
            title,
            modifier = Modifier.weight(1f),
            color = HydraNavy,
            fontSize = 20.sp,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center
        )
        var menuOpen by remember { mutableStateOf(false) }
        Box {
            IconButton(onClick = { menuOpen = true }) {
                Icon(Icons.Filled.MoreVert, contentDescription = tx("Options", "خيارات"), tint = HydraBlue)
            }
            DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                DropdownMenuItem(
                    text = { Text(tx("Daily goal", "الهدف اليومي")) },
                    onClick = { menuOpen = false; onGoal() }
                )
            }
        }
    }
}

@Composable
private fun BottomNavigationBar(selected: AppTab, onSelect: (AppTab) -> Unit) {
    Surface(color = HydraWhite, shadowElevation = 7.dp) {
        Row(
            Modifier.fillMaxWidth().navigationBarsPadding().height(66.dp).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            val tabs = listOf(AppTab.HOME, AppTab.HISTORY, AppTab.PROGRESS, AppTab.REMINDERS)
            tabs.forEach { tab ->
                Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
                    val active = selected == tab
                    Box(
                        Modifier.size(if (active) 48.dp else 44.dp)
                            .clip(CircleShape)
                            .background(if (active) HydraBlue else Color.Transparent)
                            .clickable { onSelect(tab) },
                        contentAlignment = Alignment.Center
                    ) {
                        when (tab) {
                            AppTab.HOME -> Text("💧", fontSize = 24.sp)
                            AppTab.HISTORY -> Icon(Icons.Filled.History, null, tint = if (active) HydraWhite else HydraNavy.copy(alpha = .78f), modifier = Modifier.size(25.dp))
                            AppTab.PROGRESS -> Icon(Icons.Filled.BarChart, null, tint = if (active) HydraWhite else HydraNavy.copy(alpha = .78f), modifier = Modifier.size(25.dp))
                            AppTab.REMINDERS -> Icon(Icons.Filled.Notifications, null, tint = if (active) HydraWhite else HydraNavy.copy(alpha = .78f), modifier = Modifier.size(25.dp))
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun HomeScreen(state: HydrationState, onAdd: () -> Unit, onGoal: () -> Unit) {
    val consumed = totalToday(state.entries)
    val remaining = max(0, state.dailyGoal - consumed)
    val progress = min(1f, consumed.toFloat() / max(1, state.dailyGoal).toFloat())
    Column(Modifier.fillMaxSize().background(HydraWhite)) {
        Header("", onGoal = onGoal)
        BoxWithConstraints(
            Modifier.fillMaxSize().weight(1f).padding(horizontal = 15.dp).padding(top = 42.dp, bottom = 8.dp)
        ) {
            val bottleHeight = maxHeight
            BottleCanvas(progress, Modifier.fillMaxSize().padding(top = 48.dp))
            Column(
                Modifier.align(Alignment.TopCenter).offset(y = bottleHeight * .17f),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.Center) {
                    Text(consumed.toString(), fontSize = 39.sp, fontWeight = FontWeight.Bold, color = HydraNavy)
                    Spacer(Modifier.width(7.dp))
                    Text("ml", fontSize = 21.sp, fontWeight = FontWeight.Medium, color = HydraNavy)
                }
                Text(
                    tx("Remaining ", "المتبقي ") + remaining + " ml",
                    color = HydraMuted,
                    fontSize = 15.sp
                )
            }
            ImageAsset(
                R.drawable.mascot_idle,
                Modifier.align(Alignment.Center).fillMaxWidth(.84f).height(bottleHeight * .48f).offset(y = bottleHeight * .08f)
            )
            Box(
                Modifier.align(Alignment.BottomCenter).padding(bottom = 22.dp)
                    .size(88.dp).clip(CircleShape).background(HydraWhite)
                    .border(2.dp, HydraLavender, CircleShape)
                    .clickable(onClick = onAdd),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Filled.Add, contentDescription = tx("Add a drink", "إضافة مشروب"), tint = HydraBlue, modifier = Modifier.size(39.dp))
            }
            Column(
                Modifier.align(Alignment.TopCenter).offset(y = (-1).dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Box(Modifier.fillMaxWidth(.54f).height(59.dp).clip(RoundedCornerShape(22.dp)).background(HydraBlue))
                Box(Modifier.fillMaxWidth(.48f).height(12.dp).clip(RoundedCornerShape(8.dp)).background(HydraLavender))
            }
        }
    }
}

@Composable
private fun ImageAsset(resource: Int, modifier: Modifier = Modifier) {
    androidx.compose.foundation.Image(
        painter = painterResource(resource),
        contentDescription = tx("HydraLion mascot", "شخصية هايدرا ليون"),
        contentScale = ContentScale.Fit,
        modifier = modifier
    )
}

@Composable
private fun BottleCanvas(progress: Float, modifier: Modifier = Modifier) {
    val animation = rememberInfiniteTransition(label = "bottle-animation")
    val phase by animation.animateFloat(
        initialValue = 0f,
        targetValue = (2f * PI).toFloat(),
        animationSpec = infiniteRepeatable(tween(9200, easing = LinearEasing), repeatMode = RepeatMode.Restart),
        label = "water-wave"
    )
    val bubblePhase by animation.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(14500, easing = LinearEasing), repeatMode = RepeatMode.Restart),
        label = "rising-bubbles"
    )
    Canvas(modifier) {
        val w = size.width
        val h = size.height
        val bottle = Path().apply {
            moveTo(w * .28f, 0f)
            cubicTo(w * .10f, h * .035f, w * .04f, h * .12f, w * .04f, h * .26f)
            lineTo(w * .04f, h * .83f)
            quadraticTo(w * .04f, h, w * .21f, h)
            lineTo(w * .79f, h)
            quadraticTo(w * .96f, h, w * .96f, h * .83f)
            lineTo(w * .96f, h * .26f)
            cubicTo(w * .96f, h * .12f, w * .90f, h * .035f, w * .72f, 0f)
            close()
        }
        drawPath(
            bottle,
            Brush.linearGradient(
                listOf(Color(0xFFEAF3FF).copy(alpha = .68f), Color.White.copy(alpha = .18f), Color(0xFFDCEAFF).copy(alpha = .58f)),
                start = Offset(0f, 0f),
                end = Offset(w, h)
            )
        )
        val fill = progress.coerceIn(0f, 1f)
        if (fill > .005f) {
            val surfaceY = h * (1f - fill)
            val water = Path().apply {
                for (i in 0..100) {
                    val x = w * i / 100f
                    val y = surfaceY + sin((x / w) * 2f * PI + phase * .52f).toFloat() * 7.dp.toPx() +
                        sin((x / w) * 3.7f * PI - phase * .34f + .7f).toFloat() * 3.dp.toPx()
                    if (i == 0) moveTo(x, y) else lineTo(x, y)
                }
                lineTo(w, h)
                lineTo(0f, h)
                close()
            }
            clipPath(bottle) {
                drawPath(
                    water,
                    Brush.verticalGradient(
                        listOf(Color(0xFF4FA8EF).copy(alpha = .86f), Color(0xFF2D8DDD).copy(alpha = .91f), Color(0xFF176BBE).copy(alpha = .97f)),
                        startY = surfaceY,
                        endY = h
                    )
                )
                val surface = Path().apply {
                    for (i in 0..100) {
                        val x = w * i / 100f
                        val y = surfaceY + sin((x / w) * 2f * PI + phase * .52f).toFloat() * 7.dp.toPx() +
                            sin((x / w) * 3.7f * PI - phase * .34f + .7f).toFloat() * 3.dp.toPx()
                        if (i == 0) moveTo(x, y) else lineTo(x, y)
                    }
                }
                drawPath(surface, Color.White.copy(alpha = .44f), style = Stroke(width = 1.3.dp.toPx(), cap = StrokeCap.Round))
                for (i in 0 until 18) {
                    val xRatio = listOf(.12f, .23f, .34f, .46f, .58f, .69f, .80f, .88f, .18f, .39f, .53f, .74f, .29f, .63f, .84f, .44f, .16f, .77f)[i]
                    val radius = (2.3f + (i % 5) * 1.25f) * density
                    val travel = (bubblePhase + i * .173f) % 1f
                    val y = h - travel * (h - surfaceY)
                    val fade = ((y - surfaceY) / (22.dp.toPx())).coerceIn(0f, 1f)
                    val driftX = sin(phase * .55f + i * 1.7f).toFloat() * 4.dp.toPx()
                    if (y > surfaceY + 3.dp.toPx()) {
                        drawCircle(Color.White.copy(alpha = .07f * fade), radius, Offset(w * xRatio + driftX, y))
                        drawCircle(Color.White.copy(alpha = .58f * fade), radius, Offset(w * xRatio + driftX, y), style = Stroke(width = 1.1.dp.toPx()))
                        drawCircle(Color.White.copy(alpha = .72f * fade), radius * .20f, Offset(w * xRatio + driftX - radius * .28f, y - radius * .36f))
                    }
                }
                drawRoundRect(
                    Brush.verticalGradient(listOf(Color.White.copy(alpha = .36f), Color.White.copy(alpha = .015f))),
                    topLeft = Offset(w * .105f, h * .23f),
                    size = Size(w * .047f, h * .42f),
                    cornerRadius = CornerRadius(w * .025f)
                )
                drawRoundRect(
                    Color.White.copy(alpha = .18f),
                    topLeft = Offset(w * .86f, h * .31f),
                    size = Size(w * .018f, h * .27f),
                    cornerRadius = CornerRadius(w * .012f)
                )
            }
        }
        drawPath(
            bottle,
            Brush.linearGradient(listOf(Color.White.copy(alpha = .98f), Color(0xFF82A9F1).copy(alpha = .70f), Color.White.copy(alpha = .94f))),
            style = Stroke(width = 4.5.dp.toPx())
        )
        drawPath(bottle, Color.White.copy(alpha = .74f), style = Stroke(width = 1.2.dp.toPx()))
    }
}

@Composable
private fun AddDrinkScreen(onBack: () -> Unit, onAdd: (DrinkKind, Int) -> Unit) {
    var kind by rememberSaveable { mutableStateOf(DrinkKind.WATER) }
    var amount by rememberSaveable { mutableIntStateOf(250) }
    var didAdd by rememberSaveable { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().background(HydraWhite)) {
        Header(tx("Add Drink", "إضافة مشروب"), onBack = onBack, onGoal = {})
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(Modifier.height(18.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(5.dp)) {
                DrinkKind.values().forEach { drink ->
                    val active = kind == drink
                    Column(
                        Modifier.weight(1f).clip(RoundedCornerShape(18.dp))
                            .background(if (active) HydraPanel else HydraWhite)
                            .clickable(enabled = !didAdd) { kind = drink }
                            .padding(vertical = 8.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Box(
                            Modifier.size(52.dp).clip(CircleShape)
                                .background(if (active) HydraBlue else Color(drink.color).copy(alpha = .12f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(drink.emoji, fontSize = 25.sp)
                        }
                        Text(
                            if (LocalConfiguration.current.locales[0].language.startsWith("ar")) drink.titleAr else drink.titleEn,
                            color = if (active) HydraBlue else HydraNavy,
                            fontSize = 11.sp,
                            fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal,
                            textAlign = TextAlign.Center,
                            maxLines = 1
                        )
                    }
                }
            }
            Spacer(Modifier.height(26.dp))
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                CircleAction(Icons.Filled.Remove, enabled = !didAdd) { amount = max(50, amount - 50) }
                Spacer(Modifier.weight(1f))
                Text(amount.toString() + " ml", fontSize = 36.sp, fontWeight = FontWeight.SemiBold, color = HydraNavy)
                Spacer(Modifier.weight(1f))
                CircleAction(Icons.Filled.Add, enabled = !didAdd) { amount = min(3000, amount + 50) }
            }
            Spacer(Modifier.height(18.dp))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf(150, 250, 330, 500).forEach { preset ->
                    Box(
                        Modifier.weight(1f).height(52.dp).clip(RoundedCornerShape(14.dp))
                            .background(if (amount == preset) HydraBlue else HydraPanel)
                            .clickable(enabled = !didAdd) { amount = preset },
                        contentAlignment = Alignment.Center
                    ) {
                        Text(preset.toString() + " ml", color = if (amount == preset) HydraWhite else HydraNavy, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    }
                }
            }
            Spacer(Modifier.height(12.dp))
            ImageAsset(
                if (didAdd) R.drawable.mascot_cheers else R.drawable.mascot_drink,
                Modifier.fillMaxWidth(.84f).height(270.dp)
            )
            Button(
                onClick = {
                    if (!didAdd) {
                        onAdd(kind, amount)
                        didAdd = true
                    }
                },
                enabled = !didAdd,
                modifier = Modifier.fillMaxWidth().height(58.dp).padding(bottom = 4.dp),
                colors = ButtonDefaults.buttonColors(containerColor = HydraBlue, disabledContainerColor = HydraBlue.copy(alpha = .72f)),
                shape = RoundedCornerShape(30.dp)
            ) {
                Text(if (didAdd) tx("Drink Added!", "تمت إضافة المشروب!") else tx("Add Drink", "إضافة المشروب"), fontSize = 18.sp, color = HydraWhite)
            }
            Spacer(Modifier.height(16.dp))
        }
    }
}

@Composable
private fun CircleAction(icon: androidx.compose.ui.graphics.vector.ImageVector, enabled: Boolean, onClick: () -> Unit) {
    Box(
        Modifier.size(58.dp).clip(CircleShape).background(HydraPanel)
            .clickable(enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(icon, null, tint = HydraBlue, modifier = Modifier.size(26.dp))
    }
}

@Composable
private fun HistoryScreen(state: HydrationState, vm: HydrationViewModel, onGoal: () -> Unit) {
    var period by rememberSaveable { mutableIntStateOf(0) }
    var selectedDay by rememberSaveable { mutableLongStateOf(System.currentTimeMillis()) }
    var editing by remember { mutableStateOf<DrinkEntry?>(null) }
    Column(Modifier.fillMaxSize().background(HydraWhite)) {
        Header(tx("History", "السجل"), onGoal = onGoal)
        Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp).clip(RoundedCornerShape(18.dp)).background(HydraPanel).padding(4.dp)) {
            listOf(tx("Day", "اليوم"), tx("7 days", "7 أيام"), tx("30 days", "30 يوماً")).forEachIndexed { index, label ->
                Box(
                    Modifier.weight(1f).height(43.dp).clip(RoundedCornerShape(14.dp))
                        .background(if (period == index) HydraBlue else Color.Transparent)
                        .clickable { period = index },
                    contentAlignment = Alignment.Center
                ) {
                    Text(label, color = if (period == index) HydraWhite else HydraNavy, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                }
            }
        }
        if (period == 0) {
            val days = (0..6).map { offset ->
                Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -offset) }
            }.reversed()
            Row(
                Modifier.fillMaxWidth().horizontalScroll(rememberScrollState()).padding(horizontal = 12.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(7.dp)
            ) {
                days.forEach { day ->
                    val selected = sameDay(day.timeInMillis, selectedDay)
                    Column(
                        Modifier.width(52.dp).clip(RoundedCornerShape(15.dp))
                            .background(if (selected) HydraBlue else HydraPanel)
                            .clickable { selectedDay = day.timeInMillis }
                            .padding(vertical = 10.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text(SimpleDateFormat("EEE", Locale.getDefault()).format(day.time), color = if (selected) HydraWhite else HydraMuted, fontSize = 11.sp)
                        Text(day.get(Calendar.DAY_OF_MONTH).toString(), color = if (selected) HydraWhite else HydraNavy, fontSize = 19.sp, fontWeight = FontWeight.SemiBold)
                    }
                }
            }
            val records = state.entries.filter { sameDay(it.timestamp, selectedDay) }.sortedByDescending { it.timestamp }
            if (records.isEmpty()) {
                Column(Modifier.fillMaxSize().weight(1f), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.Center) {
                    ImageAsset(R.drawable.mascot_relax, Modifier.size(190.dp))
                    Text(tx("No drinks recorded for this day", "لا توجد مشروبات مسجلة لهذا اليوم"), color = HydraMuted, fontSize = 15.sp)
                }
            } else {
                LazyColumn(Modifier.weight(1f).padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(9.dp)) {
                    items(records, key = { it.id }) { entry ->
                        HistoryEntryCard(
                            entry,
                            onEdit = { editing = entry },
                            onDelete = { vm.deleteEntry(entry.id) }
                        )
                    }
                }
            }
        } else {
            val days = if (period == 1) 7 else 30
            LazyColumn(
                Modifier.weight(1f).padding(horizontal = 16.dp).padding(top = 18.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items((0 until days).toList()) { offset ->
                    val day = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -offset) }
                    val total = totalForCalendarDay(state.entries, day)
                    val ratio = (total.toFloat() / max(1, state.dailyGoal)).coerceIn(0f, 1f)
                    Row(
                        Modifier.fillMaxWidth().height(48.dp).clip(RoundedCornerShape(12.dp)).background(HydraPanel).padding(horizontal = 12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(SimpleDateFormat("dd MMM", Locale.getDefault()).format(day.time), color = HydraNavy, fontSize = 12.sp, modifier = Modifier.width(62.dp))
                        Box(Modifier.weight(1f).height(12.dp).clip(CircleShape).background(Color(0xFFDDE4F8))) {
                            Box(Modifier.fillMaxWidth(ratio).fillMaxHeight().clip(CircleShape).background(HydraBlue))
                        }
                        Text(total.toString() + " ml", color = HydraMuted, fontSize = 11.sp, textAlign = TextAlign.End, modifier = Modifier.width(64.dp))
                    }
                }
            }
        }
    }
    editing?.let { entry ->
        EditEntryDialog(entry, onDismiss = { editing = null }, onSave = {
            vm.updateEntry(entry.id, it)
            editing = null
        })
    }
}

@Composable
private fun HistoryEntryCard(entry: DrinkEntry, onEdit: () -> Unit, onDelete: () -> Unit) {
    var menu by remember(entry.id) { mutableStateOf(false) }
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(19.dp)).background(HydraPanel).padding(horizontal = 13.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.size(48.dp).clip(CircleShape).background(Color(entry.kind.color).copy(alpha = .13f)), contentAlignment = Alignment.Center) {
            Text(entry.kind.emoji, fontSize = 23.sp)
        }
        Spacer(Modifier.width(12.dp))
        Column(Modifier.weight(1f)) {
            Text(if (LocalConfiguration.current.locales[0].language.startsWith("ar")) entry.kind.titleAr else entry.kind.titleEn, color = HydraNavy, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Text(entry.amountMl.toString() + " ml", color = HydraMuted, fontSize = 13.sp)
        }
        Text(SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date(entry.timestamp)), color = HydraMuted, fontSize = 11.sp)
        Box {
            IconButton(onClick = { menu = true }) {
                Icon(Icons.Filled.MoreVert, contentDescription = tx("Entry actions", "إجراءات السجل"), tint = HydraNavy)
            }
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(
                    text = { Text(tx("Edit", "تعديل")) },
                    leadingIcon = { Icon(Icons.Filled.Edit, null) },
                    onClick = { menu = false; onEdit() }
                )
                DropdownMenuItem(
                    text = { Text(tx("Delete", "حذف")) },
                    leadingIcon = { Icon(Icons.Filled.Delete, null) },
                    onClick = { menu = false; onDelete() }
                )
            }
        }
    }
}

@Composable
private fun EditEntryDialog(entry: DrinkEntry, onDismiss: () -> Unit, onSave: (Int) -> Unit) {
    var amount by remember(entry.id) { mutableStateOf(entry.amountMl.toString()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tx("Edit drink", "تعديل المشروب")) },
        text = {
            Column {
                Text(if (LocalConfiguration.current.locales[0].language.startsWith("ar")) entry.kind.titleAr else entry.kind.titleEn)
                OutlinedTextField(value = amount, onValueChange = { amount = it.filter(Char::isDigit).take(4) }, label = { Text(tx("Amount (ml)", "الكمية (مل)")) })
            }
        },
        confirmButton = {
            TextButton(onClick = { amount.toIntOrNull()?.let { onSave(it.coerceIn(10, 3000)) } }) { Text(tx("Save", "حفظ")) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tx("Cancel", "إلغاء")) } }
    )
}

@Composable
private fun ProgressScreen(state: HydrationState, onGoal: () -> Unit) {
    val consumed = totalToday(state.entries)
    val remaining = max(0, state.dailyGoal - consumed)
    val progress = min(1f, consumed.toFloat() / max(1, state.dailyGoal).toFloat())
    Column(Modifier.fillMaxSize().background(HydraWhite)) {
        Header(tx("Water Reminder", "تذكير شرب الماء"), onGoal = onGoal)
        Box(Modifier.fillMaxSize().weight(1f), contentAlignment = Alignment.Center) {
            Canvas(Modifier.size(286.dp)) {
                val stroke = 19.dp.toPx()
                drawArc(HydraPanel, -90f, 360f, false, style = Stroke(stroke, cap = StrokeCap.Round))
                if (progress > 0f) {
                    drawArc(
                        Brush.sweepGradient(listOf(HydraLavender, HydraBlue, HydraBlueDeep, HydraLavender)),
                        -90f, 360f * progress, false,
                        style = Stroke(stroke, cap = StrokeCap.Round)
                    )
                }
            }
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(String.format(Locale.getDefault(), "%.2f %%", progress * 100f), color = HydraNavy, fontSize = 37.sp, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(13.dp))
                Text(consumed.toString() + " ml", color = HydraNavy, fontSize = 27.sp, fontWeight = FontWeight.SemiBold)
                Spacer(Modifier.height(6.dp))
                Text(tx("Remaining ", "المتبقي ") + remaining + " ml", color = HydraMuted, fontSize = 14.sp)
            }
        }
    }
}

@Composable
private fun RemindersScreen(settings: ReminderSettings, vm: HydrationViewModel, onGoal: () -> Unit) {
    val context = LocalContext.current
    Column(Modifier.fillMaxSize().background(HydraWhite)) {
        Header(tx("Reminders", "التذكيرات"), onGoal = onGoal)
        Column(
            Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 16.dp).padding(top = 12.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            Card(shape = RoundedCornerShape(22.dp), colors = CardDefaults.cardColors(containerColor = HydraWhite), border = androidx.compose.foundation.BorderStroke(1.dp, HydraPanel)) {
                Column {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 17.dp), verticalAlignment = Alignment.CenterVertically) {
                        Column(Modifier.weight(1f)) {
                            Text(tx("Reminder", "التذكير"), color = HydraNavy, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                            Text(tx("Get notified to drink water", "احصل على تنبيه لشرب الماء"), color = HydraMuted, fontSize = 12.sp)
                        }
                        Switch(checked = settings.enabled, onCheckedChange = { vm.updateReminder(settings.copy(enabled = it)) })
                    }
                    SettingDivider()
                    SettingDropdown(
                        tx("Interval", "الفاصل الزمني"),
                        settings.intervalMinutes.toString() + " " + tx("minutes", "دقيقة"),
                        listOf(15, 30, 45, 60, 90, 120, 180).map { it.toString() + " " + tx("minutes", "دقيقة") }
                    ) { index -> vm.updateReminder(settings.copy(intervalMinutes = listOf(15, 30, 45, 60, 90, 120, 180)[index])) }
                    SettingDivider()
                    TimeSettingRow(tx("Start Time", "وقت البدء"), settings.startMinutes) { value ->
                        val end = if (value >= settings.endMinutes) min(1439, value + 60) else settings.endMinutes
                        vm.updateReminder(settings.copy(startMinutes = value, endMinutes = end))
                    }
                    SettingDivider()
                    TimeSettingRow(tx("End Time", "وقت الانتهاء"), settings.endMinutes) { value ->
                        if (value > settings.startMinutes) vm.updateReminder(settings.copy(endMinutes = value))
                    }
                }
            }
            Card(shape = RoundedCornerShape(22.dp), colors = CardDefaults.cardColors(containerColor = HydraWhite), border = androidx.compose.foundation.BorderStroke(1.dp, HydraPanel)) {
                Column {
                    Text(tx("Notifications", "الإشعارات"), color = HydraNavy, fontSize = 19.sp, fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(horizontal = 18.dp, vertical = 18.dp))
                    SettingDivider()
                    Row(Modifier.fillMaxWidth().padding(horizontal = 18.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(tx("Sound", "الصوت"), color = HydraNavy, modifier = Modifier.weight(1f))
                        Switch(checked = settings.soundEnabled, onCheckedChange = { vm.updateReminder(settings.copy(soundEnabled = it)) })
                    }
                    SettingDivider()
                    Column(Modifier.padding(horizontal = 18.dp, vertical = 12.dp)) {
                        Text(tx("Message", "نص الإشعار"), color = HydraNavy, fontSize = 14.sp, fontWeight = FontWeight.Medium)
                        OutlinedTextField(
                            value = settings.message,
                            onValueChange = { vm.updateReminder(settings.copy(message = it)) },
                            modifier = Modifier.fillMaxWidth().padding(top = 7.dp),
                            singleLine = false,
                            minLines = 2,
                            placeholder = { Text(tx("Notification message", "رسالة الإشعار")) }
                        )
                    }
                    SettingDivider()
                    SettingDropdown(
                        tx("Snooze", "تأجيل التذكير"),
                        settings.snoozeMinutes.toString() + " " + tx("minutes", "دقيقة"),
                        listOf(5, 10, 15, 30).map { it.toString() + " " + tx("minutes", "دقيقة") }
                    ) { index -> vm.updateReminder(settings.copy(snoozeMinutes = listOf(5, 10, 15, 30)[index])) }
                }
            }
            Text(
                tx(
                    "MIUI tip: allow HydraLion in Autostart and set Battery saver to No restrictions so reminders can arrive reliably while the screen is locked.",
                    "ملاحظة MIUI: فعّل التشغيل التلقائي للتطبيق واجعل توفير البطارية على «بلا قيود» لضمان وصول التذكيرات عند قفل الشاشة."
                ),
                color = HydraMuted,
                fontSize = 12.sp,
                lineHeight = 18.sp,
                modifier = Modifier.padding(horizontal = 5.dp)
            )
        }
    }
}

@Composable
private fun SettingDivider() {
    Divider(color = HydraPanel, thickness = 1.dp)
}

@Composable
private fun SettingDropdown(title: String, value: String, options: List<String>, onSelect: (Int) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Row(
        Modifier.fillMaxWidth().clickable { expanded = true }.padding(horizontal = 18.dp, vertical = 17.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, color = HydraNavy, fontSize = 15.sp, modifier = Modifier.weight(1f))
        Text(value, color = HydraMuted, fontSize = 13.sp)
        Box {
            IconButton(onClick = { expanded = true }, modifier = Modifier.size(30.dp)) {
                Icon(Icons.Filled.MoreVert, null, tint = HydraMuted)
            }
            DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
                options.forEachIndexed { index, option ->
                    DropdownMenuItem(text = { Text(option) }, onClick = { expanded = false; onSelect(index) })
                }
            }
        }
    }
}

@Composable
private fun TimeSettingRow(title: String, minutes: Int, onSelect: (Int) -> Unit) {
    val context = LocalContext.current
    val calendar = Calendar.getInstance().apply {
        set(Calendar.HOUR_OF_DAY, minutes / 60)
        set(Calendar.MINUTE, minutes % 60)
    }
    Row(
        Modifier.fillMaxWidth().clickable {
            TimePickerDialog(
                context,
                { _, hour, minute -> onSelect(hour * 60 + minute) },
                calendar.get(Calendar.HOUR_OF_DAY),
                calendar.get(Calendar.MINUTE),
                android.text.format.DateFormat.is24HourFormat(context)
            ).show()
        }.padding(horizontal = 18.dp, vertical = 17.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(title, color = HydraNavy, fontSize = 15.sp, modifier = Modifier.weight(1f))
        Text(SimpleDateFormat("h:mm a", Locale.getDefault()).format(calendar.time), color = HydraMuted, fontSize = 13.sp)
    }
}

@Composable
private fun GoalDialog(currentGoal: Int, onDismiss: () -> Unit, onSave: (Int) -> Unit) {
    var value by remember(currentGoal) { mutableStateOf(currentGoal.toString()) }
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(tx("Daily water goal", "الهدف اليومي للماء")) },
        text = {
            OutlinedTextField(
                value = value,
                onValueChange = { value = it.filter(Char::isDigit).take(5) },
                label = { Text(tx("Goal in ml", "الهدف بالملليلتر")) },
                singleLine = true
            )
        },
        confirmButton = {
            TextButton(onClick = { value.toIntOrNull()?.let { if (it in 250..10000) onSave(it) } }) {
                Text(tx("Save", "حفظ"))
            }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text(tx("Cancel", "إلغاء")) } }
    )
}

private fun totalToday(entries: List<DrinkEntry>): Int {
    val today = Calendar.getInstance()
    return totalForCalendarDay(entries, today)
}

private fun totalForCalendarDay(entries: List<DrinkEntry>, day: Calendar): Int {
    return entries.filter { entry ->
        val date = Calendar.getInstance().apply { timeInMillis = entry.timestamp }
        date.get(Calendar.YEAR) == day.get(Calendar.YEAR) &&
            date.get(Calendar.DAY_OF_YEAR) == day.get(Calendar.DAY_OF_YEAR)
    }.sumOf { it.amountMl }
}

private fun sameDay(timestampA: Long, timestampB: Long): Boolean {
    val a = Calendar.getInstance().apply { timeInMillis = timestampA }
    val b = Calendar.getInstance().apply { timeInMillis = timestampB }
    return a.get(Calendar.YEAR) == b.get(Calendar.YEAR) &&
        a.get(Calendar.DAY_OF_YEAR) == b.get(Calendar.DAY_OF_YEAR)
}
