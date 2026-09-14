//
//  BookishApp.swift
//  Bookish
//
//  Created by Soroka, Olena on 07.05.2026.
//

import SwiftUI
import SwiftData

@main
struct BookishApp: App {
  private let sharedModelContainer: ModelContainer
  private let booksViewModel: BooksListViewModel
  private let ordersViewModel: OrdersListViewModel
  private let customersViewModel: CustomersListViewModel

  init() {
    let container = Persistence.makeContainer()
    sharedModelContainer = container
    let service = BooksApplicationService(
      apiClient: APIClient(),
      cache: CacheStore(modelContainer: container)
    )
    booksViewModel = BooksListViewModel(service: service)
    ordersViewModel = OrdersListViewModel(service: service)
    customersViewModel = CustomersListViewModel(service: service)
  }

  var body: some Scene {
    WindowGroup {
      TabView {
        BooksListView(viewModel: booksViewModel)
          .tabItem {
            Label("Books", systemImage: "book")
          }

        OrdersListView(viewModel: ordersViewModel)
          .tabItem {
            Label("Orders", systemImage: "shippingbox")
          }

        CustomersListView(viewModel: customersViewModel)
          .tabItem {
            Label("Customers", systemImage: "person.2")
          }
      }
    }
    .modelContext(sharedModelContainer.mainContext)
  }
}
