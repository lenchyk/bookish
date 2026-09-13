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
  var loadingState: LoadingState = .idle

  init(service: BooksApplicationService) {
    self.service = service
  }

  func loadOrders() async {
    loadingState = .loading

    do {
      orders = try await service.getOrders()
      loadingState = .loaded
    } catch is CancellationError {
      return
    } catch {
      loadingState = .failed(error.localizedDescription)
    }
  }
}
