import Foundation

enum DTCDictionary {

    static func normalizedCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func description(for code: String) -> String {
        let key = normalizedCode(code)
        if let exact = titles[key] {
            return exact
        }

        switch key.first {
        case "P":
            return "Powertrain trouble code"
        case "C":
            return "Chassis trouble code"
        case "B":
            return "Body trouble code"
        case "U":
            return "Network trouble code"
        default:
            return "Diagnostic trouble code"
        }
    }

    static func title(for code: String) -> String {
        let key = normalizedCode(code)
        return "\(key) · \(description(for: key))"
    }

    private static let titles: [String: String] = [
        "P0001": "Fuel Volume Regulator Control Circuit / Open",
        "P0100": "Mass or Volume Air Flow Circuit Malfunction",
        "P0101": "Mass or Volume Air Flow Circuit Range / Performance",
        "P0102": "Mass or Volume Air Flow Circuit Low Input",
        "P0103": "Mass or Volume Air Flow Circuit High Input",
        "P0110": "Intake Air Temperature Circuit Malfunction",
        "P0113": "Intake Air Temperature Circuit High Input",
        "P0115": "Engine Coolant Temperature Circuit Malfunction",
        "P0118": "Engine Coolant Temperature Circuit High Input",
        "P0120": "Throttle / Pedal Position Sensor A Circuit",
        "P0128": "Coolant Thermostat (Coolant Temperature Below Thermostat Regulating Temperature)",
        "P0130": "O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)",
        "P0131": "O2 Sensor Circuit Low Voltage (Bank 1 Sensor 1)",
        "P0133": "O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)",
        "P0135": "O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 1)",
        "P0136": "O2 Sensor Circuit Malfunction (Bank 1 Sensor 2)",
        "P0141": "O2 Sensor Heater Circuit Malfunction (Bank 1 Sensor 2)",
        "P0171": "System Too Lean (Bank 1)",
        "P0172": "System Too Rich (Bank 1)",
        "P0174": "System Too Lean (Bank 2)",
        "P0175": "System Too Rich (Bank 2)",
        "P0200": "Injector Circuit Malfunction",
        "P0201": "Injector Circuit Malfunction — Cylinder 1",
        "P0202": "Injector Circuit Malfunction — Cylinder 2",
        "P0203": "Injector Circuit Malfunction — Cylinder 3",
        "P0204": "Injector Circuit Malfunction — Cylinder 4",
        "P0300": "Random / Multiple Cylinder Misfire Detected",
        "P0301": "Cylinder 1 Misfire Detected",
        "P0302": "Cylinder 2 Misfire Detected",
        "P0303": "Cylinder 3 Misfire Detected",
        "P0304": "Cylinder 4 Misfire Detected",
        "P0305": "Cylinder 5 Misfire Detected",
        "P0306": "Cylinder 6 Misfire Detected",
        "P0325": "Knock Sensor 1 Circuit Malfunction",
        "P0335": "Crankshaft Position Sensor A Circuit Malfunction",
        "P0340": "Camshaft Position Sensor Circuit Malfunction",
        "P0401": "Exhaust Gas Recirculation Flow Insufficient Detected",
        "P0420": "Catalyst System Efficiency Below Threshold (Bank 1)",
        "P0430": "Catalyst System Efficiency Below Threshold (Bank 2)",
        "P0440": "Evaporative Emission Control System Malfunction",
        "P0442": "Evaporative Emission Control System Leak Detected (Small Leak)",
        "P0446": "Evaporative Emission Control System Vent Control Circuit Malfunction",
        "P0455": "Evaporative Emission Control System Leak Detected (Gross Leak)",
        "P0456": "Evaporative Emission Control System Leak Detected (Very Small Leak)",
        "P0463": "Fuel Level Sensor Circuit High Input",
        "P0480": "Cooling Fan 1 Control Circuit Malfunction",
        "P0500": "Vehicle Speed Sensor Malfunction",
        "P0505": "Idle Control System Malfunction",
        "P0507": "Idle Control System RPM Higher Than Expected",
        "P0522": "Engine Oil Pressure Sensor / Switch Low Voltage",
        "P0700": "Transmission Control System Malfunction",
        "P0705": "Transmission Range Sensor Circuit Malfunction",
        "P0715": "Input / Turbine Speed Sensor Circuit Malfunction",
        "P0720": "Output Speed Sensor Circuit Malfunction",
        "P0730": "Incorrect Gear Ratio",
        "P0740": "Torque Converter Clutch Circuit Malfunction",
        "P1128": "Closed Loop Fueling Not Achieved",
        "P2187": "System Too Lean at Idle (Bank 1)",
        "P2195": "O2 Sensor Signal Stuck Lean (Bank 1 Sensor 1)",
        "P2270": "O2 Sensor Signal Stuck Lean (Bank 1 Sensor 2)",
        "P2610": "ECM / PCM Internal Engine Off Timer Performance",
        "C0035": "Left Front Wheel Speed Sensor Circuit",
        "C0040": "Right Front Wheel Speed Sensor Circuit",
        "B0001": "Driver Frontal Stage 1 Deployment Control",
        "U0100": "Lost Communication With ECM / PCM",
        "U0101": "Lost Communication With TCM",
        "U0121": "Lost Communication With ABS Control Module",
        "U0140": "Lost Communication With Body Control Module",
        "U0155": "Lost Communication With Instrument Panel Cluster",
    ]
}
