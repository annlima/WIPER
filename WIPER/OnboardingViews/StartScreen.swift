//
//  StartDrivingScreen.swift
//  AppWIPER
//
//  Created by Andrea Lima Blanca on 10/09/23.
//

import SwiftUI

struct StartDrivingScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var checked = false
    var body: some View {
        NavigationView {
            ZStack {
                VStack() {
                    TopWaveShape()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color("Color").opacity(0.8), Color("Color").opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 950)
                    
                        .edgesIgnoringSafeArea(.all)
                    
                }
                
                VStack() {
                    Spacer()
                        .frame(height: 190)
                    HeaderStartDriving()
                    
                    Text("Bienvenido a")
                        .font(.system(size: 40))
                        .fontWeight(.bold)
                        .foregroundColor(Color("Color"))
                        .padding(.top, 30)

                    Text("WIPER")
                        .font(.system(size: 60))
                        .fontWeight(.heavy)
                        .foregroundColor(Color("Color"))
                        .padding(.bottom, 10)
                    Text("La aplicación que cuida de tu seguridad al manejar")
                        .font(.title2)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    NavigationLink(destination: Onboarding()
                        .environmentObject(locationManager)) {
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [Color("Color"), Color("Color")]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .cornerRadius(20)
                            .shadow(color: .gray.opacity(0.5), radius: 10, x: 0, y: 5)
                            .opacity(checked ? 1 : 0.5)
                            
                            Text("¡Empezar a conducir!")
                                .foregroundColor(.white)
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding()
                        }
                        .frame(height: 60)
                    }
                    .disabled(!checked)
                    .padding(.top, 30)
                    .padding(.bottom, 15)

                    
                    HStack {
                        
                        iOSCheckboxToggleStyle(checked: $checked)
                        NavigationLink(destination: TermsAndConditions()) {
                            Text("Estoy de acuerdo con los términos y condiciones")
                                .font(.system(size: 12))
                                .fontWeight(.semibold)
                                .foregroundColor(Color("Color"))
                        }
                }
                    
                    Spacer()
                
                }
            }
            .padding()
            .background(Color("BackgroundColor").edgesIgnoringSafeArea(.all))
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct iOSCheckboxToggleStyle: View {
    @Binding var checked: Bool
    var body: some View {
    Image(systemName: checked ? "checkmark.square.fill" : "square")
        .foregroundColor(checked ? Color(UIColor.systemBlue) : Color.secondary)
        .onTapGesture {
            self.checked.toggle()
        }
    }
}
    
struct TopWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: -1*width, y: 2))
        path.addCurve(
            to: CGPoint(x: width*1.5, y: height * 0.2),
            control1: CGPoint(x: width, y: height * 0.5),
            control2: CGPoint(x: width, y: 0)
        )
        
        path.addLine(to: CGPoint(x: width, y: 0))

        path.closeSubpath()
        
        return path
    }
}

struct HeaderStartDriving: View {
    var body: some View {
        VStack {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: 5)

        }
    }
}

struct StartDrivingScreen_Previews: PreviewProvider {
    static var previews: some View {
        StartDrivingScreen()
            
    }
}
