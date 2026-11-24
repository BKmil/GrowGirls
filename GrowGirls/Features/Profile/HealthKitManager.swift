import HealthKit

// This small helper contains all Apple Health code.
// SettingsView only needs to ask it for permission.
final class HealthKitManager {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async -> Bool {
        // Health data is not available on every Apple device.
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        // GrowGirls wants to save completed workouts to Apple Health.
        let workoutType = HKObjectType.workoutType()
        let dataToWrite: Set<HKSampleType> = [workoutType]

        // GrowGirls wants to read workouts and activity energy.
        let activeEnergyType = HKObjectType.quantityType(
            forIdentifier: .activeEnergyBurned
        )

        var dataToRead: Set<HKObjectType> = [workoutType]

        if let activeEnergyType {
            dataToRead.insert(activeEnergyType)
        }

        do {
            try await healthStore.requestAuthorization(
                toShare: dataToWrite,
                read: dataToRead
            )
            return true
        } catch {
            return false
        }
    }
}
