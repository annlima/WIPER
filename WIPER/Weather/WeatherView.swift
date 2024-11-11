//
//  WeatherView.swift
//  WIPER
//
//  Created by Dicka J. Lezama on 17/10/24.
//

import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            Text("Visibility: \(viewModel.visibilityCategory)")
                .padding()
        }
        .onAppear {
            if let coordinates = locationManager.currentLocation {
                Task {
                    await viewModel.fetchWeatherData(for: coordinates)
                }
            } else {
                print("Location not available")
            }
        }
        .onChange(of: locationManager.currentLocation) { newLocation in
            if let coordinates = newLocation {
                Task {
                    await viewModel.fetchWeatherData(for: coordinates)
                }
            }
        }
    }
}


#Preview {
    WeatherView()
}
