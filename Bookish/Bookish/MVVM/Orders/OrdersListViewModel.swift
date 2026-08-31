//
//  OrdersListViewModel.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class OrdersListViewModel {
  let service: BooksApplicationService

  var orders: [Order] = []
  var errorMessage: String?
  var isLoading = false
  private(set) var hasCompletedInitialLoad = false

  init(service: BooksApplicationService) {
    self.service = service
  }

  func loadInitialIfNeeded() async {
    guard !hasCompletedInitialLoad else { return }
    await loadOrders()
  }

  func loadOrders() async {
    isLoading = true
    defer {
      isLoading = false
      hasCompletedInitialLoad = true
    }

    do {
      orders = try await service.getOrders()
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
