//
//  OrderDetailsViewModel.swift
//  Bookish
//
//  Created by Soroka, Olena on 13.08.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class OrderDetailsViewModel {
  let orderId: Int
  private let service: BooksApplicationService

  var order: Order?
  var loadingState: LoadingState = .idle

  init(orderId: Int, service: BooksApplicationService, order: Order? = nil) {
    self.orderId = orderId
    self.service = service
    self.order = order
  }

  func loadOrder() async {
    if order == nil {
      loadingState = .loading
    }

    do {
      let loaded = try await service.getOrder(by: orderId)
      guard !Task.isCancelled else { return }
      order = loaded
      loadingState = .loaded
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      if order == nil {
        loadingState = .failed(error.localizedDescription)
      }
    }
  }
}
