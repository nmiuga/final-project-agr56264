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
    case combine = "COMBINE"
    case profile = "PROFILE"

    var icon: String {
        switch self {
        case .home:    return "paintbrush"
        case .explore: return "safari"
        case .combine: return "circle.grid.2x2"
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
                case .combine:
                    NavigationStack { CombinePickerView() }
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
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 30)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.terracotta.opacity(0.08))
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - TabBarItem

private struct TabBarItem: View {
    let tab: AppTab
    let isSelected: Bool

    var body: some View {
        Image(systemName: isSelected ? tab.icon + ".fill" : tab.icon)
            .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
            .foregroundStyle(isSelected ? Color.terracotta : Color.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
    }
}

#Preview { ContentView() }
