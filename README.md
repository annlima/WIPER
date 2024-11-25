# WIPER: Real-Time Hazard Detection for Safer Driving

<img width="468" alt="Captura de pantalla 2024-11-25 a la(s) 2 44 35 p m" src="https://github.com/user-attachments/assets/df31550d-37db-49cc-abbb-928296bd9ee8">

**WIPER** is an iOS application that enhances driving safety by detecting road hazards in real-time. Leveraging advanced computer vision and machine learning models, WIPER identifies objects such as vehicles, pedestrians, road damages, and more to provide timely alerts for drivers.

---

## Features

- **Real-Time Object Detection**: Identifies: "person", "bus", "car", "dog", "bicycle", "truck".
- **Video Recording with Bounding Boxes**: Records driving sessions with hazard annotations overlaid directly on the video.
- **Weather Adaptation**: Improves detection performance by preprocessing images based on weather conditions using filters like CLAHE, dehazing models, and night enhancement.
- **Offline Functionality**: Operates without internet dependency, ensuring uninterrupted safety.
- **Map Integration**: Visualizes routes and hazards detected during driving sessions.
- **Privacy Focused**: Collects minimal data and adheres to strict privacy standards.

---

## Tech Stack

- **Programming Languages**: Swift, Python (for model training and preprocessing).
- **Frameworks**:
  - iOS: SwiftUI, AVFoundation, CoreML, WeatherKit, CoreLocation, MapKit.
  - Machine Learning: PyTorch, YOLOv5.
- **Tools**:
  - Google Colab for model training.
  - CoreML integration for on-device processing.

---

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/WIPER.git
   cd WIPER
   ```

2. Open the project in Xcode:
   ```bash
   open WIPER.xcodeproj
   ```

3. Ensure you have the following:
   - Xcode 13 or later.
   - An iPhone XR or newer device for deployment.

4. Install dependencies:
   - For iOS, configure permissions for camera, location, and notifications in `Info.plist`.

5. Build and run the app on a physical device (recommended for real-time detection).

---

## How It Works

1. **Detection Pipeline**:
   - The app uses YOLOv5 trained on a custom dataset for hazard detection.
   - Bounding boxes and labels for detected objects are displayed on the camera preview.

2. **Weather-Based Preprocessing**:
   - Filters are applied based on real-time weather conditions fetched using WeatherKit.

3. **Video Recording**:
   - Videos are saved locally with hazard annotations overlaid for later review.

4. **Alert System**:
   - Triggers alarms when hazards are detected at unsafe distances.

---

## Demo: Initial configurations



https://github.com/user-attachments/assets/d1ab6b39-8e81-459d-b744-1372a83eaae4



## Demo: Video processing

https://github.com/user-attachments/assets/b2a31a4d-d12c-45d4-8391-a207bdce598f




---

## Usage

1. Launch the app and grant necessary permissions.
2. Start a driving session to enable real-time detection.
3. Access recorded videos with bounding boxes in the gallery.
4. Use the integrated map to visualize routes and hazards.


---

## Contributing

We welcome contributions! To contribute:

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes and push the branch:
   ```bash
   git push origin feature-name
   ```
4. Open a Pull Request on the main repository.

---

## Acknowledgments

- **YOLOv5**: For its robust object detection capabilities.
- **Apple Developer Tools**: For seamless integration with SwiftUI and CoreML.
- **WeatherKit**: For enabling weather-aware preprocessing.
- **Community Contributors**: Thank you for supporting WIPER's development!
