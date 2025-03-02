import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var navigateToStartScreen = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color("BackgroundColor")
                    .edgesIgnoringSafeArea(.all)
                Circle()
                    .fill(Color("Color"))
                    .scaleEffect(isAnimating ? 3 : 0.1)
                    .animation(.easeOut(duration: 1))
                    .onAppear {
                        withAnimation {
                            isAnimating = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            navigateToStartScreen = true
                        }
                    }
                
                NavigationLink(destination: StartDrivingScreen(), isActive: $navigateToStartScreen) {
                    EmptyView()
                }
            }
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
