//
//  TermsAndConditions.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 22/09/24.
//

import SwiftUI

struct TermsAndConditions: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Términos y Condiciones")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)
                
                Text(termsAndConditionsText)
                    .font(.body)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .navigationBarTitle(Text("Términos y Condiciones"), displayMode: .inline)
    }
}

private let termsAndConditionsText = """
Términos y Condiciones / Aviso de Privacidad para WIPER

1.⁠ ⁠Introducción
Bienvenido a WIPER. Este documento establece los términos y condiciones, así como el aviso de privacidad de nuestra aplicación móvil destinada a mejorar la seguridad vial a través de la detección de anomalías durante el manejo mediante técnicas de visión por computadora e inteligencia artificial. Al usar la aplicación, usted acepta cumplir con estos términos y condiciones en su totalidad.

2.⁠ ⁠Responsabilidad del Usuario
WIPER está diseñada para brindar apoyo y alertas auditivas que ayuden al conductor a identificar riesgos potenciales en la carretera. Sin embargo, la aplicación no reemplaza la responsabilidad del usuario de conducir de manera segura y cumplir con todas las leyes de tránsito. WIPER no asume ninguna responsabilidad por accidentes, daños, pérdidas o lesiones de cualquier tipo que puedan ocurrir mientras se utiliza la aplicación.

3.⁠ ⁠Limitación de Responsabilidad
El usuario reconoce y acepta que WIPER es una herramienta de asistencia y que su funcionalidad puede estar sujeta a imprecisiones debido a factores externos como el estado del dispositivo móvil, condiciones climáticas, calidad de la señal de la cámara y otros aspectos que afectan la tecnología de visión por computadora. WIPER, sus desarrolladores, socios y afiliados no serán responsables por errores en la detección o interpretación de las alertas emitidas por la aplicación.

4.⁠ ⁠Uso Seguro de la Aplicación
Se recomienda que el conductor utilice WIPER de manera responsable y que no permita que la aplicación desvie su atención de la carretera. Las alertas auditivas proporcionadas están diseñadas para complementar, no sustituir, la atención del conductor.

5.⁠ ⁠Recopilación y Uso de Datos
Para mejorar la experiencia y efectividad de WIPER, es posible que la aplicación recopile información no personal del dispositivo, como datos de uso y de la cámara. Estos datos son utilizados únicamente para el correcto funcionamiento de las funcionalidades de la aplicación y no se comparten con terceros sin el consentimiento expreso del usuario.

6.⁠ ⁠Exoneración de Garantías
WIPER se proporciona "tal cual" sin garantías de ningún tipo, ya sea expresa o implícita. La aplicación no garantiza la exactitud, completitud o disponibilidad en todo momento y se exime de cualquier garantía implícita de comerciabilidad o idoneidad para un propósito particular.

7.⁠ ⁠Modificaciones de los Términos
WIPER se reserva el derecho de modificar estos términos y condiciones, así como el aviso de privacidad, en cualquier momento. Las modificaciones serán efectivas una vez publicadas en la aplicación, y el uso continuo de WIPER después de dichas publicaciones se considerará como la aceptación de los cambios.

8.⁠ ⁠Contacto
Si tiene preguntas o inquietudes sobre estos términos y condiciones o sobre la política de privacidad, puede comunicarse con nuestro equipo a través del correo de soporte de WIPER.

Aviso Final
El uso de WIPER implica la aceptación de que la aplicación es un asistente para la seguridad y no exime al conductor de su responsabilidad de conducir con precaución y siguiendo las normativas viales aplicables.
"""

struct TermsAndConditionsView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndConditions()
    }
}
