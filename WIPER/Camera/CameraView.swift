import SwiftUI
import AVFoundation
import MapKit

struct CameraView: View {
    let calculatedRoute: MKRoute?

    @StateObject var cameraViewModel: CameraViewModel
    @StateObject var cameraManager = CameraManager()
    @StateObject var locationManager = LocationManager()

    init(calculatedRoute: MKRoute?) {
        self.calculatedRoute = calculatedRoute
        _cameraViewModel = StateObject(wrappedValue: CameraViewModel(route: calculatedRoute))
    }

    var body: some View {
        ZStack {
            FullScreenCameraView(
                cameraViewModel: cameraViewModel,
                cameraManager: cameraManager,
                locationManager: locationManager
            )
            .edgesIgnoringSafeArea(.all)
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }
}
