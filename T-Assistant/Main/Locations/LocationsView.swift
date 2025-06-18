import SwiftUI

struct LocationsView: View {
    @StateObject private var viewModel = LocationsViewModel()
    @State private var showingAddLocationSheet = false
    @Namespace private var animation

    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 230/255, green: 235/255, blue: 241/255)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 10) {
                        Text("Мои Локации")
                            .font(.largeTitle).bold()
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 24)
                    .padding(.bottom, 8)

                    ScrollView {
                        VStack(spacing: 16) {
                            if viewModel.locations.isEmpty && !viewModel.isLoading {
                                Text("У вас пока нет сохраненных локаций.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(viewModel.locations) { location in
                                    LocationCardView(location: location)
                                        .matchedGeometryEffect(id: location.id, in: animation)
                                        .transition(.move(edge: .bottom).combined(with: .opacity))
                                }
                            }

                            if viewModel.isLoading {
                                ProgressView("Загрузка локаций...")
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                        .padding(.horizontal)
                    }
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showingAddLocationSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.black)
                                .padding()
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color("action"), Color("action")]), startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .clipShape(Circle())
                                .shadow(color: Color("action").opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 28)
                        .padding(.bottom, 24)
                        .accessibilityLabel("Добавить локацию")
                    }
                }
            }
            .sheet(isPresented: $showingAddLocationSheet) {
                LocationInputView(onSave: { name, coords in
                    viewModel.saveLocation(name: name, coords: coords)
                })
            }
            .onAppear {
                viewModel.fetchLocations()
            }
            .alert(item: $viewModel.errorMessage) { errorMessage in
                Alert(title: Text("Ошибка"), message: Text(errorMessage.message), dismissButton: .default(Text("OK")))
            }
            .navigationBarHidden(true)
        }
    }
}

struct LocationCardView: View {
    let location: UserLocation

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color("action").opacity(0.7), Color("action").opacity(0.7)]), startPoint: .top, endPoint: .bottom)
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Image(systemName: "mappin")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(location.coords)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.95))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .padding(.horizontal, 2)
    }
}

class LocationsViewModel: ObservableObject {
    @Published var locations: [UserLocation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: ErrorMessage? = nil

    func fetchLocations() {
        isLoading = true
        LocationService.shared.fetchLocations { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let fetchedLocations):
                    self.locations = fetchedLocations
                case .failure(let error):
                    self.errorMessage = ErrorMessage(message: error.localizedDescription)
                    print("Error fetching locations: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveLocation(name: String, coords: String) {
        isLoading = true
        LocationService.shared.saveLocation(name: name, coords: coords) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success:
                    self.fetchLocations()
                case .failure(let error):
                    self.errorMessage = ErrorMessage(message: error.localizedDescription)
                    print("Error saving location: \(error.localizedDescription)")
                }
            }
        }
    }
}

#Preview {
    LocationsView()
} 
