import Foundation
import UserNotifications
import CoreLocation
import os.log

class BeaconManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    @Published var beaconDistance: String = "No Beacons detected"
    @Published private var counter = 0
    @Published private var timer: Timer?
    let centralManager = CentralManager()

    override init() {
        self.locationManager = CLLocationManager()
        super.init()

        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.allowsBackgroundLocationUpdates = true
        os_log("Biruleibe")
        startScanning()
        startCounter()
    }

    func startCounter() {
        // Invalidate any existing timer

        // Start a new timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.counter += 1
            os_log("Counter: \(self.counter) [Beacon]") // Print the counter value
        }
    }

    func startScanning() {
        let beaconUUID = UUID(uuidString: "1750EFEB-8F47-4DE7-8EBD-388CC3F5C8F6")!
        let beaconIdentityConstraint = CLBeaconIdentityConstraint(uuid: beaconUUID)
        let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: beaconIdentityConstraint, identifier: "com.example.myBeacon")

        // Start monitoring for the region
        locationManager.startMonitoring(for: beaconRegion)

        // Check if the region is already monitored
        if locationManager.monitoredRegions.contains(beaconRegion) == false {
            locationManager.startMonitoring(for: beaconRegion)
        }

        // Start ranging beacons
        locationManager.startRangingBeacons(satisfying: beaconIdentityConstraint)
    }

    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        if let nearestBeacon = beacons.first {
            switch nearestBeacon.proximity {
            case .immediate:
                beaconDistance = "Immediate (Less than 1 meter)"
            case .near:
                beaconDistance = "Near (1 to 3 meters)"
            case .far:
                beaconDistance = "Far (more than 3 meters)"
            case .unknown:
                beaconDistance = "Unknown"
            @unknown default:
                beaconDistance = "Unknown error"
            }
        } else {
            beaconDistance = "No Beacons detected"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            print("When user did not yet determine")
        case .restricted:
            print("Restricted by parental control")
        case .denied:
            print("When user selects option Don't Allow")
        case .authorizedAlways:
            print("When user selects option Change to Always Allow")
        case .authorizedWhenInUse:
            print("When user selects option Allow While Using App or Allow Once")
            // Request always authorization if needed
            self.locationManager.requestAlwaysAuthorization()
        default:
            print("default")
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if let beaconRegion = region as? CLBeaconRegion {
            manager.startRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)

            // Local notification to inform the user
            let content = UNMutableNotificationContent()
            content.title = "Beacon Detected"
            content.body = "You've entered the beacon region."
            content.sound = .default

            os_log("Beacon detected [Beacon]")

            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Stop ranging when exiting the region
        if let beaconRegion = region as? CLBeaconRegion {
            os_log("Exit region [Beacon]")
            manager.stopRangingBeacons(satisfying: beaconRegion.beaconIdentityConstraint)
        }
    }
}
