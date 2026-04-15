//
//  ContentView.swift
//  MetDigitalGallery
//
//  Root view — custom 3-tab bottom navigation bar matching the Figma design.
//  Tabs: HOME → HomeView, EXPLORE → ExploreView, PROFILE → ProfileView
//

import SwiftUI

// MARK: - AppTab

enum AppTab: String, CaseIterable {
    case home    = "HOME"
    case explore = "EXPLORE"
    case profile = "PROFILE"

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .explore: return "safari"
        case .profile: return "person"
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack { HomeView() }
                case .explore:
                    NavigationStack { ExploreView() }
                case .profile:
                    NavigationStack { ProfileView() }
                }
            }
            .padding(.bottom, 80)

            CustomTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - CustomTabBar

private struct CustomTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    TabBarItem(tab: tab, isSelected: selectedTab == tab)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 28)
        .background(Color.cream)
        .overlay(Divider(), alignment: .top)
    }
}

// MARK: - TabBarItem

private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
            Text(tab.rawValue)
                .font(.caption)
                .tracking(1.2)
        }
        .foregroundStyle(isSelected ? Color.white : Color.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            isSelected ? Color.terracotta : Color.clear,
            in: Capsule()
        )
    }
}

#Preview { ContentView() }
