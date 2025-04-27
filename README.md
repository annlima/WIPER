# WIPER: Real-Time Hazard Detection for Safer Driving

<img width="468" alt="Captura de pantalla 2024-11-25 a la(s) 2 44 35 p m" src="https://github.com/user-attachments/assets/df31550d-37db-49cc-abbb-928296bd9ee8">

**WIPER** is an iOS application that enhances driving safety by detecting road hazards in real-time. Leveraging advanced computer vision and machine learning models, WIPER identifies objects such as vehicles, pedestrians, and more to provide timely alerts for drivers.

---

# WIPER - Driving Safety Assistant

## Description

WIPER is an iOS application designed to enhance driving safety by utilizing computer vision and artificial intelligence techniques[cite: 325]. It processes the camera feed in real-time to detect potential road hazards, estimate distances, and provide timely audio-visual alerts to the driver[cite: 18, 19, 195, 325, 331]. The app features adaptive image enhancement for various weather conditions, integrates map functionalities, and allows users to record their driving sessions[cite: 1, 8, 12, 14, 91, 195, 379, 403].

## Features

* **Real-time Object Detection:** Identifies vehicles (cars, buses, trucks), pedestrians, cyclists, and other objects using a Core ML model (YOLOv5s)[cite: 195, 204, 242].
* **Distance Estimation:** Calculates the distance to detected objects using:
    * Camera intrinsics (focal length) and known object dimensions[cite: 219, 220, 221, 222].
    * Depth data from TrueDepth or LiDAR sensors on compatible devices for higher accuracy[cite: 190, 250, 251, 258, 260, 263].
* **Adaptive Image Enhancement:** Applies specific image filters to improve visibility based on current weather conditions (Sunny/CLAHE, Fog/Dehaze, Rain Removal, Night Enhancement) fetched via WeatherKit[cite: 1, 5, 8, 12, 14, 195, 198, 217, 234, 235].
* **Intelligent Alarm System:**
    * Triggers audible alarms based on calculated stopping distances, considering current vehicle speed, distance to the detected object, and road conditions (wet/dry estimated from visibility data)[cite: 18, 19, 20, 24, 26, 28, 49, 52].
    * Includes an `AlarmManager` to handle sound playback and prevent excessive alerts[cite: 31, 32, 34].
* **Speed Overlay:** Displays the current speed obtained from GPS data directly on the camera view[cite: 55, 99, 401].
* **Driving Session Recording:** Allows users to record video footage of their journey[cite: 91, 105, 106, 149, 152]. Option to save recordings to the photo gallery[cite: 109, 110, 276].
* **Map Integration:**
    * Displays current location and destination on a map[cite: 379, 403, 458].
    * Search for destinations and calculate routes[cite: 449, 453].
    * Save and manage favorite locations[cite: 405, 419, 446].
* **Performance Optimization:** Adjusts camera resolution, frame processing rate, and detection confidence thresholds based on the device model's performance level (Low, Medium, High) to ensure smooth operation[cite: 146, 147, 162, 168, 171, 174, 179, 185, 208, 229].
* **User-Friendly Onboarding:** Guides new users through necessary permissions (Camera, Location, Notifications)[cite: 281, 289, 302, 313].
* **Landscape Camera View:** Ensures the camera preview is correctly oriented in landscape mode[cite: 120, 130, 135].

## Technologies Used

* **Swift:** Primary programming language.
* **SwiftUI:** For building the user interface[cite: 281, 379, 403, 471].
* **AVFoundation:** For camera access, session management, video/depth data capture, and recording[cite: 90, 119, 134, 142, 194].
* **Vision:** For running the object detection model[cite: 194, 230, 237, 239].
* **Core ML:** For loading and using the YOLOv5s object detection model[cite: 194, 204].
* **MapKit:** For displaying maps, annotations, calculating routes, and searching locations[cite: 379, 403, 458].
* **CoreLocation:** For accessing GPS data (speed, location) and managing permissions[cite: 392, 393, 403, 458].
* **WeatherKit:** To fetch current weather conditions for image enhancement adjustments[cite: 194, 199, 216].
* **Photos:** To save recorded videos to the device gallery[cite: 194, 276].
* **UserNotifications:** To request and manage notification permissions[cite: 281, 308].

## Code Structure Overview

* **Core Logic:**
    * `CameraViewModel`: Central class handling video frame processing, object detection, depth data processing, distance calculation, weather fetching, and alarm logic coordination[cite: 194, 195, 196].
    * `CameraManager`: Manages the `AVCaptureSession`, inputs/outputs, recording, and performance-based configuration[cite: 142, 143, 144].
    * `ImageEnhancer`: Applies image enhancement filters[cite: 1].
    * `AlarmSystem` / `AlarmManager`: Determine when to trigger alarms and manage sound playback[cite: 18, 19, 31].
    * `DeviceManager`: Detects device model, capabilities (LiDAR), and provides relevant info like focal length[cite: 57, 60, 62, 75, 88].
    * `LocationManager`: Handles location updates, speed calculation, and permissions[cite: 393, 394].
* **UI Components (SwiftUI):**
    * `ContentView` / `WIPERApp`: Main application entry point[cite: 471, 473].
    * `SplashScreen` / `StartDrivingScreen`: Initial screens[cite: 341, 363].
    * `Onboarding` / `CameraPermissionTab` / `NotificationsTab` / `LocationPermissionTab` / `GoTab`: Onboarding flow[cite: 281, 289, 302, 313, 296].
    * `FavoriteRoute`: Main map view for selecting destinations and starting navigation[cite: 403].
    * `CustomMapView`: `UIViewRepresentable` wrapper for `MKMapView`[cite: 379].
    * `FullScreenCameraView` / `CameraPreview`: Displays the live camera feed and overlays[cite: 90, 91, 134, 135].
    * `SpeedOverlayView`: Shows the current speed[cite: 55].
    * `SwipeToDeleteRow`: UI component for favorite locations list[cite: 369].
    * `TermsAndConditions`: Displays the terms view[cite: 322].
* **UIKit Integration:**
    * `LandscapeCameraViewController`: Ensures correct camera preview orientation in landscape[cite: 119, 120].
    * `ViewController`: Older `MKMapView` implementation (potentially for reference or an alternative view)[cite: 458].
    * `AppDelegate` / `SceneDelegate`: Standard iOS application lifecycle management[cite: 469, 470].
* **Utilities & Extensions:**
    * `CGRect` extension for Hashable conformance[cite: 89].
    * `EquatableLocation`: Wrapper for `CLLocation` to use with SwiftUI state[cite: 392].

## Installation

1.  Clone the repository: `git clone https://github.com/your-username/WIPER.git`
2.  Open the `.xcodeproj` or `.xcworkspace` file in Xcode.
3.  Ensure you have the necessary dependencies (Core ML model file `best_yolov5s.mlmodel` needs to be included in the project target)[cite: 204].
4.  Sign the app with your developer account.
5.  Build and run on a physical iOS device (Camera and Location features require a device).

## Usage

1.  Launch the app.
2.  Proceed through the onboarding screens, granting necessary permissions (Camera, Location, Notifications)[cite: 281].
3.  On the map screen (`FavoriteRoute`), search for a destination or select a favorite location[cite: 403, 416, 425].
4.  Tap "Empezar a viajar" to start the camera view[cite: 431, 432].
5.  Mount the phone securely on the dashboard or windshield.
6.  The app will display the camera feed with object detection boxes and the speed overlay[cite: 99, 100].
7.  Optionally, tap the record button to start/stop recording the drive[cite: 105, 107].
8.  The app will provide audible alerts if potential hazards are detected based on distance and speed[cite: 29, 52].

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.





