package com.rise.alarmclock

class RiseAlarmPlugin {
    fun forceSpeakerForAlarm() = true
    fun capEarphoneVolume(percent: Int) = percent.coerceIn(0, 40)
}
