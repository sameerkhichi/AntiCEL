import Foundation

enum DTCDictionary {

    static func normalizedCode(_ code: String) -> String {
        code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    static func hasExactDescription(_ code: String) -> Bool {
        titles[normalizedCode(code)] != nil
    }

    static func description(for code: String) -> String {
        let key = normalizedCode(code)
        return titles[key] ?? inferredTitle(for: key)
    }

    static func title(for code: String) -> String {
        let key = normalizedCode(code)
        return "\(key) · \(description(for: key))"
    }

    static func explanation(for code: String) -> String {
        let key = normalizedCode(code)
        if let exact = explanations[key] {
            return exact
        }
        return inferredExplanation(for: key)
    }

    static func notes(for code: String, status: DiagnosticFaultStatus) -> String {
        let key = normalizedCode(code)
        let area = DTCHistoryMapper.vehicleArea(for: key).displayName
        var lines = [
            "\(key) — \(description(for: key))",
            "",
            explanation(for: key),
            "",
            "System: \(area)",
            "Status: \(status.displayName) — \(statusMeaning(status))"
        ]
        if !hasExactDescription(key), isManufacturerSpecific(key) {
            lines.append("Definition source: manufacturer-specific. AntiCEL cannot look up the OEM wording.")
        } else if hasExactDescription(key) {
            lines.append("Definition source: standard OBD / SAE J2012.")
        } else {
            lines.append("Definition source: SAE code family. No line-item wording is published for this exact code.")
        }
        lines.append("Saved by AntiCEL from a Connect scan.")
        return lines.joined(separator: "\n")
    }

    private static func statusMeaning(_ status: DiagnosticFaultStatus) -> String {
        switch status {
        case .stored:
            return "saved in the vehicle’s memory. This is the code that usually turns on a warning lamp."
        case .pending:
            return "seen during a drive but not confirmed yet. It may set as stored if the fault happens again."
        case .permanent:
            return "kept until the vehicle completes a clean drive cycle. A code clear cannot remove this one."
        }
    }

    private static func isManufacturerSpecific(_ key: String) -> Bool {
        guard key.count >= 2 else { return false }
        let origin = key[key.index(key.startIndex, offsetBy: 1)]
        return origin == "1" || origin == "3"
    }

    private static func inferredTitle(for key: String) -> String {
        guard key.count >= 3 else { return genericLetterTitle(key) }
        let letter = key[key.startIndex]
        let origin = key[key.index(key.startIndex, offsetBy: 1)]
        let group = key[key.index(key.startIndex, offsetBy: 2)]
        let manufacturer = origin == "1" || origin == "3"

        switch letter {
        case "P":
            if manufacturer { return "Manufacturer powertrain code" }
            switch group {
            case "0": return "Fuel and air metering / auxiliary emission control"
            case "1": return "Fuel and air metering"
            case "2": return "Fuel and air metering — injector circuit"
            case "3": return "Ignition system or misfire"
            case "4": return "Auxiliary emission controls"
            case "5": return "Vehicle speed, idle control, or auxiliary inputs"
            case "6": return "Computer and auxiliary outputs"
            case "7", "8", "9": return "Transmission"
            case "A": return "Hybrid propulsion"
            case "B": return "Hybrid battery"
            case "C": return "Hybrid / electric drive motor"
            default: return "Powertrain trouble code"
            }
        case "C":
            if manufacturer { return "Manufacturer chassis code" }
            switch group {
            case "0": return "ABS / traction — wheel speed or brake control"
            case "1": return "ABS / traction — pressure or pump"
            case "2": return "ABS / traction — solenoid or valve"
            default: return "Chassis system (ABS, steering, or suspension)"
            }
        case "B":
            return manufacturer ? "Manufacturer body code" : "Body control / occupant safety"
        case "U":
            return manufacturer ? "Manufacturer network code" : "Network / lost communication"
        default:
            return "Diagnostic trouble code"
        }
    }

    private static func genericLetterTitle(_ key: String) -> String {
        switch key.first {
        case "P": return "Powertrain trouble code"
        case "C": return "Chassis trouble code"
        case "B": return "Body trouble code"
        case "U": return "Network trouble code"
        default: return "Diagnostic trouble code"
        }
    }

    private static func inferredExplanation(for key: String) -> String {
        let title = inferredTitle(for: key)
        if isManufacturerSpecific(key) {
            return "\(key) is a manufacturer-specific \(genericLetterTitle(key).lowercased()). Standard OBD does not publish one public sentence for this code. The vehicle still reported it as a real fault, usually in the \(title.lowercased()) area. A dealer-level description may name the exact sensor or module."
        }
        return "The vehicle reported \(key). AntiCEL does not have a line-item definition for this exact code. In the SAE J2012 layout it belongs to “\(title).” That is the system the ECU is pointing at."
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
        "C0045": "Left Rear Wheel Speed Sensor Circuit",
        "C0050": "Right Rear Wheel Speed Sensor Circuit",
        "C0060": "ABS Lateral Accelerometer Circuit",
        "C0110": "Pump Motor Circuit",
        "B0001": "Driver Frontal Stage 1 Deployment Control",
        "U0100": "Lost Communication With ECM / PCM",
        "U0101": "Lost Communication With TCM",
        "U0121": "Lost Communication With ABS Control Module",
        "U0140": "Lost Communication With Body Control Module",
        "U0155": "Lost Communication With Instrument Panel Cluster",
    ]

    private static let explanations: [String: String] = [
        "P0001": "The fuel volume regulator control circuit is open. The ECM is not seeing a valid command path to the fuel quantity control valve, which can cause hard starts, stalling, or a rich/lean condition.",
        "P0100": "The mass air flow sensor circuit is not reading a plausible airflow signal. The engine may idle poorly, hesitate, or run rich or lean because fueling is based on a bad air measurement.",
        "P0101": "Mass air flow is outside the expected range for current RPM and load. The sensor may be dirty, leaking intake air, or electrically out of spec.",
        "P0102": "Mass air flow voltage is too low. Typical causes are an unplugged MAF, a damaged wire, or a severely restricted intake.",
        "P0103": "Mass air flow voltage is too high. Typical causes are a shorted MAF circuit or a sensor that is reporting far more air than the engine is actually taking in.",
        "P0110": "The intake air temperature sensor circuit is implausible. The ECM uses this for fueling and idle; a bad reading can affect cold start and mixture.",
        "P0113": "Intake air temperature voltage is too high, which the ECM treats as an extremely cold (or open) sensor. Wiring and the IAT sensor are the usual checks.",
        "P0115": "The engine coolant temperature sensor circuit is implausible. Fans, mixture, and temperature gauges can all behave incorrectly.",
        "P0118": "Coolant temperature voltage is too high (open circuit / extremely cold reading). A failed ECT sensor or wiring is typical.",
        "P0120": "Throttle or pedal position sensor A is out of range. Drive-by-wire cars may go into limp mode.",
        "P0128": "Coolant is not reaching the thermostat’s regulating temperature in time. A stuck-open thermostat is the common cause; the engine runs too cool.",
        "P0130": "Bank 1 sensor 1 (upstream O2 / A/F) is not producing a valid signal. Fuel trim and catalyst monitoring on that bank are affected.",
        "P0131": "Bank 1 sensor 1 voltage is stuck low (lean). Exhaust leaks, wiring, or a failed sensor can cause this.",
        "P0133": "Bank 1 sensor 1 is switching too slowly. The sensor is often aged or contaminated.",
        "P0135": "The heater for bank 1 sensor 1 is not working. The sensor stays cold and mixture control is slow after start.",
        "P0136": "Bank 1 sensor 2 (downstream O2) is not producing a valid signal. Catalyst monitoring on that bank is affected.",
        "P0141": "The heater for bank 1 sensor 2 is not working.",
        "P0171": "Bank 1 is running too lean. Unmetered air, low fuel pressure, a dirty MAF, or an exhaust leak before the upstream sensor are common.",
        "P0172": "Bank 1 is running too rich. Leaking injectors, high fuel pressure, or a biased MAF/O2 reading are common.",
        "P0174": "Bank 2 is running too lean. Same family of causes as P0171, on the other bank.",
        "P0175": "Bank 2 is running too rich. Same family of causes as P0172, on the other bank.",
        "P0200": "An injector control circuit is out of range. One or more injectors may not be firing correctly.",
        "P0201": "Cylinder 1 injector circuit is open or shorted. That cylinder may misfire or go dead.",
        "P0202": "Cylinder 2 injector circuit is open or shorted.",
        "P0203": "Cylinder 3 injector circuit is open or shorted.",
        "P0204": "Cylinder 4 injector circuit is open or shorted.",
        "P0300": "The ECM detected misfires on more than one cylinder. Ignition, fueling, compression, or vacuum leaks can all cause this.",
        "P0301": "Cylinder 1 is misfiring. Check spark, injector, and compression on that cylinder.",
        "P0302": "Cylinder 2 is misfiring.",
        "P0303": "Cylinder 3 is misfiring.",
        "P0304": "Cylinder 4 is misfiring.",
        "P0305": "Cylinder 5 is misfiring.",
        "P0306": "Cylinder 6 is misfiring.",
        "P0325": "Knock sensor 1 is not reporting a valid signal. The ECM may pull timing and the engine can feel dull.",
        "P0335": "The crankshaft position sensor signal is missing or implausible. No-starts and stalling are common.",
        "P0340": "The camshaft position sensor signal is missing or implausible. Timing correlation and starting can fail.",
        "P0401": "Not enough EGR flow. A clogged EGR valve or passage is typical; the engine may knock or fail emissions.",
        "P0420": "The catalytic converter on bank 1 is not cleaning exhaust as expected. A worn catalyst, exhaust leak, or biased O2 sensors can all set this.",
        "P0430": "The catalytic converter on bank 2 is not cleaning exhaust as expected.",
        "P0440": "The evaporative emissions system is not holding or purging as expected. A loose fuel cap is the first check.",
        "P0442": "A small EVAP leak was detected. Cap, hoses, and the charcoal canister purge path are typical.",
        "P0446": "The EVAP vent control circuit is implausible. The vent valve or its wiring is the usual focus.",
        "P0455": "A large EVAP leak was detected. Loose cap, disconnected hose, or a failed seal are common.",
        "P0456": "A very small EVAP leak was detected. These can be hard to find and often come and go with temperature.",
        "P0463": "The fuel level sender voltage is too high. The gauge may read full or empty incorrectly.",
        "P0480": "Cooling fan 1 control is out of range. Overheating risk if the fan is not actually running.",
        "P0500": "Vehicle speed is missing or implausible. Speedometer, cruise, and ABS-related inputs can be affected.",
        "P0505": "Idle speed control is not holding the target idle.",
        "P0507": "Idle is higher than the ECM expects. A vacuum leak or stuck idle valve is common.",
        "P0522": "Oil pressure sensor voltage is too low. Confirm actual oil pressure before replacing parts.",
        "P0700": "The transmission control module stored a fault and asked the ECM to turn on the lamp. Scan the transmission for the specific code.",
        "P0705": "The transmission range sensor (PRNDL) is implausible. Shifting and starting in gear can be affected.",
        "P0715": "The input / turbine speed sensor signal is missing or implausible.",
        "P0720": "The output speed sensor signal is missing or implausible. Speedometer and shift quality can suffer.",
        "P0730": "The transmission is not in the gear the TCM commanded. Slip, wrong ratio, or a failed clutch/solenoid is typical.",
        "P0740": "The torque converter clutch circuit is out of range. You may feel shudder or higher RPM on the highway.",
        "P1128": "Closed-loop fueling was not reached in time. O2 sensors, coolant temp, or a large fueling error can delay it.",
        "P2187": "Bank 1 is too lean at idle. Vacuum leaks show up here first.",
        "P2195": "Bank 1 sensor 1 is stuck reporting lean. The sensor or an exhaust leak before it is typical.",
        "P2270": "Bank 1 sensor 2 is stuck reporting lean.",
        "P2610": "The ECM’s engine-off timer does not look valid. Evap and other after-run monitors can be affected.",
        "C0035": "The ABS module is not getting a valid left front wheel speed signal. ABS, traction, and stability control can disable. Sensor, tone ring, and the harness at that corner are the usual checks.",
        "C0040": "The ABS module is not getting a valid right front wheel speed signal. ABS, traction, and stability control can disable.",
        "C0045": "The ABS module is not getting a valid left rear wheel speed signal.",
        "C0050": "The ABS module is not getting a valid right rear wheel speed signal.",
        "C0060": "The ABS lateral accelerometer signal is implausible. Stability control may be limited.",
        "C0110": "The ABS pump motor circuit is out of range. Pedal feel and ABS assist can change.",
        "B0001": "The driver frontal airbag stage 1 deployment circuit is implausible. The airbag lamp is usually on; this is a restraint-system fault.",
        "U0100": "A module lost communication with the engine computer. Wiring, power, ground, or a busy/failed ECM can cause this.",
        "U0101": "A module lost communication with the transmission control module.",
        "U0121": "A module lost communication with the ABS control module. ABS and traction warnings are common.",
        "U0140": "A module lost communication with the body control module. Multiple body functions can drop at once.",
        "U0155": "A module lost communication with the instrument cluster. Gauges or warning lamps may be blank or stuck.",
    ]
}
