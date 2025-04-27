# WIPER: Real-Time Hazard Detection for Safer Driving

<img width="468" alt="Captura de pantalla 2024-11-25 a la(s) 2 44 35 p m" src="https://github.com/user-attachments/assets/df31550d-37db-49cc-abbb-928296bd9ee8">

**WIPER** is an iOS application that enhances driving safety by detecting road hazards in real-time. Leveraging advanced computer vision and machine learning models, WIPER identifies objects such as vehicles, pedestrians, and more to provide timely alerts for drivers.

---

# WIPER - Driving Safety Assistant

## Description

WIPER is an iOS application designed to enhance driving safety by utilizing computer vision and artificial intelligence techniques. It processes the camera feed in real-time to detect potential road hazards, estimate distances, and provide timely audio-visual alerts to the driver. The app features adaptive image enhancement for various weather conditions, integrates map functionalities, and allows users to record their driving sessions.

## Features

- **Real-time Object Detection:** Identifies vehicles (cars, buses, trucks), pedestrians, cyclists, and other objects using a Core ML model (YOLOv5s).
- **Distance Estimation:** Calculates the distance to detected objects using:
  - Camera intrinsics (focal length) and known object dimensions.
  - Depth data from TrueDepth or LiDAR sensors on compatible devices for higher accuracy.
- **Adaptive Image Enhancement:** Applies specific image filters to improve visibility based on current weather conditions (Sunny/CLAHE, Fog/Dehaze, Rain Removal, Night Enhancement) fetched via WeatherKit.
- **Intelligent Alarm System:**
  - Triggers audible alarms based on calculated stopping distances, considering current vehicle speed, distance to the detected object, and road conditions (wet/dry estimated from visibility data).
  - Includes an `AlarmManager` to handle sound playback and prevent excessive alerts.
- **Speed Overlay:** Displays the current speed obtained from GPS data directly on the camera view.
- **Driving Session Recording:** Allows users to record video footage of their journey. Option to save recordings to the photo gallery.
- **Map Integration:**
  - Displays current location and destination on a map.
  - Search for destinations and calculate routes.
  - Save and manage favorite locations.
- **Performance Optimization:** Adjusts camera resolution, frame processing rate, and detection confidence thresholds based on the device model's performance level (Low, Medium, High) to ensure smooth operation.
- **User-Friendly Onboarding:** Guides new users through necessary permissions (Camera, Location, Notifications).
- **Landscape Camera View:** Ensures the camera preview is correctly oriented in landscape mode.

## Technologies Used

- **Swift:** Primary programming language.
- **SwiftUI:** For building the user interface.
- **AVFoundation:** For camera access, session management, video/depth data capture, and recording.
- **Vision:** For running the object detection model.
- **Core ML:** For loading and using the YOLOv5s object detection model.
- **MapKit:** For displaying maps, annotations, calculating routes, and searching locations.
- **CoreLocation:** For accessing GPS data (speed, location) and managing permissions.
- **WeatherKit:** To fetch current weather conditions for image enhancement adjustments.
- **Photos:** To save recorded videos to the device gallery.
- **UserNotifications:** To request and manage notification permissions.

## Code Structure Overview

### Core Logic

- `CameraViewModel`: Central class handling video frame processing, object detection, depth data processing, distance calculation, weather fetching, and alarm logic coordination.
- `CameraManager`: Manages the `AVCaptureSession`, inputs/outputs, recording, and performance-based configuration.
- `ImageEnhancer`: Applies image enhancement filters.
- `AlarmSystem` / `AlarmManager`: Determine when to trigger alarms and manage sound playback.
- `DeviceManager`: Detects device model, capabilities (LiDAR), and provides relevant info like focal length.
- `LocationManager`: Handles location updates, speed calculation, and permissions.

### UI Components (SwiftUI)

- `ContentView` / `WIPERApp`: Main application entry point.
- `SplashScreen` / `StartDrivingScreen`: Initial screens.
- `Onboarding` / `CameraPermissionTab` / `NotificationsTab` / `LocationPermissionTab` / `GoTab`: Onboarding flow.
- `FavoriteRoute`: Main map view for selecting destinations and starting navigation.
- `CustomMapView`: `UIViewRepresentable` wrapper for `MKMapView`.
- `FullScreenCameraView` / `CameraPreview`: Displays the live camera feed and overlays.
- `SpeedOverlayView`: Shows the current speed.
- `SwipeToDeleteRow`: UI component for favorite locations list.
- `TermsAndConditions`: Displays the terms view.

### UIKit Integration

- `LandscapeCameraViewController`: Ensures correct camera preview orientation in landscape.
- `ViewController`: Older `MKMapView` implementation (potentially for reference or an alternative view).
- `AppDelegate` / `SceneDelegate`: Standard iOS application lifecycle management.

### Utilities & Extensions

- `CGRect` extension for Hashable conformance.
- `EquatableLocation`: Wrapper for `CLLocation` to use with SwiftUI state.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/WIPER.git
