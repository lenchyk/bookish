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
  private let service: BooksApplicationService

  var order: Order?
  var isLoading = false
  var errorMessage: String?

  init(service: BooksApplicationService, order: Order? = nil) {
    self.service = service
    self.order = order
  }

  func loadOrder(id: Int) async {
    if order == nil {
      isLoading = true
    }

    defer { isLoading = false }

    do {
      let loaded = try await service.getOrder(by: id)
      guard !Task.isCancelled else { return }
      order = loaded
      errorMessage = nil
    } catch is CancellationError {
      return
    } catch {
      guard !Task.isCancelled else { return }
      if order == nil {
        errorMessage = error.localizedDescription
      }
    }
  }
}
