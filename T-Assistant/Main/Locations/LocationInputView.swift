import SwiftUI
import MapKit
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

struct LocationInputView: View {
    @Environment(\.dismiss) var dismiss
    var onSave: (String, String) -> Void
    @StateObject private var locationManager = LocationManager()

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6173),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var locationName: String = ""
    @State private var placemark: CLPlacemark?
    @State private var debounceWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            Color(red: 230/255, green: 235/255, blue: 241/255)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("Выберите Локацию")
                        .font(.largeTitle).bold()
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)

                Map(coordinateRegion: $region, interactionModes: .all)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    .overlay(alignment: .center) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(Color("action"))
                            .font(.system(size: 38, weight: .bold))
                            .shadow(radius: 3)
                            .offset(y: -15)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        Button {
                            locationManager.requestLocationAuthorization()
                            locationManager.startUpdatingLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.title2)
                                .padding(12)
                                .background(Color("action"))
                                .foregroundColor(.black)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(18)
                    }
                    .onChange(of: region.center) { newCenter in
                        selectedCoordinate = newCenter
                        debounceWorkItem?.cancel()
                        let workItem = DispatchWorkItem {
                            reverseGeocode(coordinate: newCenter)
                        }
                        debounceWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: workItem)
                    }
                    .onChange(of: locationManager.currentLocation) { newLocation in
                        if let location = newLocation {
                            region.center = location.coordinate
                            selectedCoordinate = location.coordinate
                            reverseGeocode(coordinate: location.coordinate)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                if let placemark = placemark {
                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "location")
                            .foregroundColor(Color("action"))
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(placemark.name ?? placemark.locality ?? "Адрес не найден")
                                .font(.headline)
                                .foregroundColor(.primary)
                            if let city = placemark.locality {
                                Text(city)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.95))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }

                HStack(spacing: 10) {
                    TextField("Название локации (например, 'Дом')", text: $locationName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 16)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { dismiss() }) {
                        Text("Отмена")
                            .fontWeight(.medium)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                    Button(action: {
                        if let coord = selectedCoordinate {
                            let coordsString = "\(coord.latitude),\(coord.longitude)"
                            onSave(locationName, coordsString)
                            dismiss()
                        }
                    }) {
                        Text("Сохранить")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(locationName.isEmpty || selectedCoordinate == nil ? Color.gray.opacity(0.3) : Color("action"))
                            .foregroundColor(locationName.isEmpty || selectedCoordinate == nil ? .gray : .black)
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
                    }
                    .disabled(locationName.isEmpty || selectedCoordinate == nil)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
    }

    private func reverseGeocode(coordinate: CLLocationCoordinate2D) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self.placemark = nil
                    return
                }
                self.placemark = placemarks?.first
            }
        }
    }
}
