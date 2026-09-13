//
//  CustomersListViewModel.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class CustomersListViewModel {
  var customers: [Customer] = []
  var loadingState: LoadingState = .idle

  private let service: BooksApplicationService

  init(service: BooksApplicationService) {
    self.service = service
  }

  func loadCustomers() async {
    loadingState = .loading

    do {
      customers = try await service.getCustomers()
      loadingState = .loaded
    } catch is CancellationError {
      return
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }
}
