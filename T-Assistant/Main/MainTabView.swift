//
//  MainTabView.swift
//  T-Assistant
//
//  Created by Богдан Тарченко on 16.06.2025.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                ChatViewScreen()
                    .padding(.vertical)
                    .tabItem {
                        Image(selectedTab == 0 ? "leftTabIconActive" : "leftTabIconUnactive")
                    }
                    .tag(0)

                ReminderListView()
                    .padding(.bottom)
                    .tabItem {
                        Image(selectedTab == 1 ? "secTabIconActive" : "secTabIconUnactive")
                    }
                    .tag(1)
                
                LocationsView()
                    .padding(.vertical)
                    .tabItem {
                        Image(systemName: "map.fill")
                    }
                    .tag(2)
            }
        }
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(Color.white, for: .tabBar)
    }
}
