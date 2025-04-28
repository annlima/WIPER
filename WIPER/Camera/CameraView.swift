import SwiftUI
import AVFoundation
import MapKit

struct CameraView: View {
    // Accept the route as an optional parameter
    let calculatedRoute: MKRoute?

    // Initialize ViewModel and Manager
    @StateObject var cameraViewModel: CameraViewModel
    @StateObject var cameraManager = CameraManager()

    // Custom initializer to pass the route to the ViewModel
    init(calculatedRoute: MKRoute?) {
        self.calculatedRoute = calculatedRoute
        // Initialize the ViewModel, passing the route
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(route: calculatedRoute))
    }

    var body: some View {
        ZStack {
            // Pass the initialized ViewModel and Manager
            FullScreenCameraView(cameraViewModel: cameraViewModel, cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
        }
         // Ensure navigation bar remains hidden if needed
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
