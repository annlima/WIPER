import SwiftUI

struct SplashScreen: View {
    @State private var isAnimating = false
    @State private var navigateToStartScreen = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color("BackgroundColor")
                    .edgesIgnoringSafeArea(.all)
                
                Circle()
                    .fill(Color("Color"))
                    .scaleEffect(isAnimating ? 3 : 0.1)
                    .animation(.easeOut(duration: 1), value: isAnimating)
                    .onAppear {
                        
                        withAnimation(.easeOut(duration: 1)) {
                            isAnimating = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            
                            navigateToStartScreen = true
                        }
                    }
                
            }
            .navigationDestination(isPresented: $navigateToStartScreen) {
                StartDrivingScreen()
            }
            .navigationBarHidden(true)
        }
    }
}

struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreen()
    }
}
