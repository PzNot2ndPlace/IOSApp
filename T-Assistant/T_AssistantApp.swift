//
//  T_AssistantApp.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("[Push] Пользователь не дал разрешение на уведомления")
            }
        }
        
        Messaging.messaging().delegate = self
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("[Push] FCM Token (через делегат): \(fcmToken ?? "nil")")
        if let token = fcmToken {
            NotificationService.shared.saveFCMToken(token) { result in
                switch result {
                case .success:
                    print("[Push] FCM токен успешно отправлен на сервер")
                case .failure(let error):
                    print("[Push] Ошибка отправки FCM токена: \(error.localizedDescription)")
                }
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Messaging.messaging().token { token, error in
            if let error = error {
                print("[Push] Ошибка получения FCM токена: \(error)")
            } else if let token = token {
                print("[Push] FCM токен (ручной запрос): \(token)")
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[Push] Не удалось зарегистрироваться для удалённых уведомлений: \(error.localizedDescription)")
    }
}

@main
struct T_AssistantApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        
        appearance.shadowColor = nil
        appearance.shadowImage = nil

        UITabBar.appearance().standardAppearance = appearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                if authViewModel.isAuthorized {
                    MainTabView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            } else {
                OnboardingFlowView()
            }
        }
    }
}
