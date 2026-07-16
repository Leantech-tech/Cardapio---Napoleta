package com.tachao.tachao_menu

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent

/**
 * Receiver necessário para que o Android autorize o app a entrar em lock task mode
 * (modo quiosque). Sem esse receiver declarado no AndroidManifest.xml com a
 * meta-data android.app.device_admin, o startLockTask() falha com SecurityException.
 */
class KioskDeviceAdminReceiver : DeviceAdminReceiver() {
    override fun onLockTaskModeEntering(context: Context, intent: Intent, pkg: String) {
        super.onLockTaskModeEntering(context, intent, pkg)
    }

    override fun onLockTaskModeExiting(context: Context, intent: Intent) {
        super.onLockTaskModeExiting(context, intent)
    }
}
