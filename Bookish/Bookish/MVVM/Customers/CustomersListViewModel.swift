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
  var errorMessage: String?
  var isLoading = false
  private(set) var hasCompletedInitialLoad = false

  private let service: BooksApplicationService

  init(service: BooksApplicationService) {
    self.service = service
  }

  func loadInitialIfNeeded() async {
    guard !hasCompletedInitialLoad else { return }
    await loadCustomers()
  }

  func loadCustomers() async {
    isLoading = true
    defer {
      isLoading = false
      hasCompletedInitialLoad = true
    }

    do {
      customers = try await service.getCustomers()
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
